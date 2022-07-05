#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import hashlib
import os
import pathlib
import platform
import urllib.request
import subprocess
import sys
import zipfile

SUPPORTED_HASH_ALGORITHMS = {
    'md5': lambda: hashlib.md5(),
    'sha1': lambda: hashlib.sha1(),
    'sha224': lambda: hashlib.sha224(),
    'sha256': lambda: hashlib.sha256()
}

ARCHIVE_EXTS_ZIP = { '.zip' }
ARCHIVE_EXTS_TAR = { '.tgz', 'gz', '.xz', '.tar.xz' }
ARCHIVE_EXTS_7ZIP = { '.7z' }

INDENT=' '*4

def hash_file(file_path:str, hash_algorithm:str='md5')->str:
    """
    Calculate a hash based on the input file path and selected hash algorithm and return a hex-string representation of it

    (Refer to SUPPORTED_HASH_ALGORITHMS for the supported hash algorithms)

    :param file_path:       The path to the file to calculate the hash
    :param hash_algorithm:  The desired hash algorith. See 'SUPPORTED_HASH_ALGORITHMS' for the list of algorithms
    """

    if not os.path.isfile(file_path):
        raise FileNotFoundError(f"File to hash {file_path} does not exist.")
    hasher_create = SUPPORTED_HASH_ALGORITHMS.get(hash_algorithm)
    if not hasher_create:
        raise KeyError("Invalid hash algorithm selected for hash calculation: '{hash_algorithm}'")

    hasher = hasher_create()
    
    # we don't follow symlinks here, this is strictly to check actual packages.
    with open(file_path, 'rb') as afile:
        buf = afile.read()
        hasher.update(buf)
    hash_result = hasher.hexdigest()

    return hash_result


def download_and_verify(src_url: str, src_zip_hash:str, src_zip_hash_algorithm:str,target_folder:str)->str:
    """
    Calculate a hash based on the input file path and selected hash algorithm and return a hex-string representation of it

    Supported hash algorithms are: md5, sha1, sha224, sha256

    :param src_url:                 The full url of the archive file to download
    :param src_zip_hash:            The expected hash to use to verify the integrity of the downloaded file. If 'None', then
                                    verification is replaced by the calculation and reporting of the result hash of the downloaded package.
    :param src_zip_hash_algorithm:  The desired hash algorith. See 'SUPPORTED_HASH_ALGORITHMS' for the list of algorithms
    :param target_folder:           The target folder to download the archive file to
    """

    target_folder_path = pathlib.Path(target_folder)

    src_filename = os.path.basename(src_url)
    tgt_filename = target_folder_path / src_filename

    # If the file has been downloaded, check its hash
    current_hash = None
    if tgt_filename.is_file():
        current_hash = hash_file(file_path=str(tgt_filename),
                                 hash_algorithm=src_zip_hash_algorithm)
        print(f"Current hash of {tgt_filename}:{current_hash}")

    if current_hash and current_hash == src_zip_hash:
        print(f"{INDENT}File '{src_filename}' already downloaded to {tgt_filename}, skipping.")
        return str(tgt_filename)

    print(f"{INDENT}Downloading {src_url}")
    tgt_filename.unlink(missing_ok=True)

    urllib.request.urlretrieve(src_url, tgt_filename)

    # Calculate the downloaded file hash 
    downloaded_hash = hash_file(file_path=str(tgt_filename),
                                hash_algorithm=src_zip_hash_algorithm)
    if src_zip_hash and src_zip_hash != downloaded_hash:
        raise RuntimeError(f"Hash {src_zip_hash_algorithm} verification failed for {tgt_filename}")

    print(f"{INDENT}Package hash : ({src_zip_hash_algorithm}) {downloaded_hash}")

    return str(tgt_filename)

def extract_package(src_package_file: str, target_folder:str):

    src_package_file_path = pathlib.Path(src_package_file)
    target_folder_path = pathlib.Path(target_folder)

    if not src_package_file_path.is_file():
        raise FileNotFoundError(f"Package to extract '{src_package_file_path}' does not exist.")
    
    package_name, package_ext = os.path.splitext(str(src_package_file_path.name))

    destination_path = target_folder_path / package_name

    print(f"{INDENT}Extracting {src_package_file_path} to {destination_path}")

    if package_ext in ARCHIVE_EXTS_ZIP:
        import zipfile
        with zipfile.ZipFile(str(src_package_file_path.resolve()), 'r') as dep_zip:
            dep_zip.extractall(destination_path)
    elif package_ext in ARCHIVE_EXTS_TAR:
        import tarfile
        with tarfile.open(str(src_package_file_path.resolve())) as tar_file:
            tarfile.extractall(destination_path)
    elif package_ext in ARCHIVE_EXTS_7ZIP:
        try:
            os.makedirs(destination_path, exist_ok=True)
            subprocess.call(['7z', 'x', '-y', str(src_package_file_path.resolve())], cwd=destination_path)
        except Exception:
            raise RuntimeError(f"Archive file {src_package_file_path} requires 7Zip to be installed and on the command path. ")
        else:
            print(f"Extracted to {destination_path}")
            
    else:
        raise RuntimeError(f"Unsupported package extension: {package_ext}")

    return destination_path



if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Download, verify hash, and unpack remote zip file")
    parser.add_argument('src-url', 
                        help='The download url of the zip package to download',
                        nargs=1)
    parser.add_argument('--hash-algorithm',
                        help=f'The hash algorithm to use to calculate the fingerprint ({" ".join(SUPPORTED_HASH_ALGORITHMS.keys())})',
                        default='sha256',
                        required=False)
    parser.add_argument('--hash',
                        help='The hash fingerprint to validate against',
                        default='',
                        required=False)

    parser.add_argument('--target-folder',
                        help='The target location for the download',
                        required=True)
    
    parsed_args = parser.parse_args()

    downloaded_package_file = download_and_verify(src_url=parsed_args.src_url[0],
                                                  src_zip_hash=parsed_args.hash,
                                                  src_zip_hash_algorithm=parsed_args.hash_algorithm,
                                                  target_folder=parsed_args.target_folder)

    extracted_package_path = extract_package(src_package_file=downloaded_package_file, 
                                             target_folder=parsed_args.target_folder)

    sys.exit(1)
