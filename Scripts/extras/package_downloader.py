
import os
import urllib
import urllib.request
import ssl
import certifi
import hashlib
import pathlib
import tarfile
import sys

class PackageDownloader(): 
    @staticmethod
    def DownloadAndUnpackPackage(package_name, package_hash, folder_target):
        ''' given a public server URL list (semicolon-seperated), 
            finds the package, if possible, and downloads and unpacks it to a given folder.
            Note that this essentially mimics the server urls protocol used by cmake on the client
            side and thus will also check buckets if s3:// urls are given
            and will stop at the first one it finds.

            Assumes that LY_PACKAGE_SERVER_URLS is set in the environment
            Assumes that, if necessary, LY_AWS_PROFILE is set in the environment (if using s3 buckets)

            returns True if it succeeded, False otherwise.
         '''

        def ComputeHashOfFile(file_path):
            file_path = os.path.normpath(file_path)
            hasher = hashlib.sha256()
            hash_result = None
            
            # we don't follow symlinks here, this is strictly to check actual packages.
            with open(file_path, 'rb') as afile:
                buf = afile.read()
                hasher.update(buf)
                hash_result = hasher.hexdigest()
        
            return hash_result

        # make sure a package with that name is not already present:
        server_urls = os.environ.get("LY_PACKAGE_SERVER_URLS", default = "")

        if not server_urls:
            print(f"Server url list is empty - please set LY_PACKAGE_SERVER_URLS env var to semicolon-seperated list of urls to check")
            print(f"Using default URL for convenience: https://d2c171ws20a1rv.cloudfront.net")
            server_urls = "https://d2c171ws20a1rv.cloudfront.net"

        download_location = pathlib.Path(folder_target)
        package_file_name = package_name + ".tar.xz"
        package_download_name = download_location / package_file_name
        package_unpack_folder = download_location / package_name
        
        server_list = server_urls.split(';')

        if os.path.exists(str(package_download_name)):
            os.path.os.remove(str(package_download_name))
      
        if not os.path.exists(str(download_location)):
            os.makedirs(str(download_location))

        print(f"Downloading package {package_name}...")

        for package_server in server_list:
            if not package_server:
                continue
            full_package_url = package_server + "/" + package_file_name
            print(f"    - attempting '{full_package_url}' ...")

            try:
                if package_server.startswith("s3://"):
                    # we don't want to use temp buckets for package dependencies
                    # you should depend on production (CDN) resources that have been verified!
                    print(f"        - Note:  Ignoring {package_server} - S3 buckets should not be used for package dependencies.")
                    continue
                tls_context = ssl.create_default_context(cafile=certifi.where())
                with urllib.request.urlopen(url=full_package_url, context = tls_context) as server_response:
                    print("    - Downloading package...")
                    file_data = server_response.read()
                    with open(package_download_name, "wb") as save_package:
                        save_package.write(file_data)
            except urllib.error.URLError as e:
                print(f"        - Server returned error: {e}")
                continue # try the next URL, if any...

            # validate that the package matches its hash
            print("    - Checking hash ... ")
            hash_result = ComputeHashOfFile(str(package_download_name))
            if hash_result != package_hash:
                print("    - Warning: Hash of package does not match - will not use it")
                os.remove(package_download_name)
                continue

            # hash matched.  Unpack and return!
            if not os.path.exists(str(package_unpack_folder)):
                os.makedirs(str(package_unpack_folder))
            with tarfile.open(package_download_name) as archive_file:
                print("    - unpacking package...")
                archive_file.extractall(package_unpack_folder)
                print(f"Downloaded successfuly to {os.path.realpath(package_unpack_folder)}")
            os.remove(package_download_name)
            return True
              
        return False

# you can also use this module from a bash script to get a package
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description="Download, verify hash, and unpack a 3p package")

    parser.add_argument('--package-name',
                        help='The package name to download',
                        required=True)

    parser.add_argument('--package-hash',
                        help='The package hash to verify',
                        required=True)
    
    parser.add_argument('--output-folder',
                        help='The folder to unpack to.  It will get unpacked into (package-name) subfolder!',
                        required=True)

    parsed_args = parser.parse_args()
    if PackageDownloader.DownloadAndUnpackPackage(parsed_args.package_name, parsed_args.package_hash, parsed_args.output_folder):
        sys.exit(0)

    sys.exit(1)

