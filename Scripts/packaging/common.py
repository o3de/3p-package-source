#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import stat
import pathlib
import json
import platform
import tempfile
import tarfile
import hashlib
import ssl
import certifi
import urllib.request 

class InvalidHashFormatException(Exception):
    '''Raised when a hash file (SHA256SUMS file) being parsed has a bad format'''
    pass

class CommonUtils():
    ''' Common utilities used when building packages
    '''

    # global consts
    package_extension                = '.tar.xz'
    package_hash_extension           = '.tar.xz.SHA256SUMS'
    package_content_hash_extension   = '.tar.xz.content.SHA256SUMS'
    package_root_hash_file_name      = 'SHA256SUMS'
    package_descriptor_name          = "PackageInfo.json"
    package_info_required_fields     = ['URL', 'PackageName', 'License', 'LicenseFile']
    spdx_license_list                = None

    # default folders
    script_dir = os.path.dirname(os.path.realpath(__file__))
    root_path = pathlib.Path(script_dir).parent.absolute()
    # note that the default output folder is the subfolder of the root to put the packages
    # if you override it with a relative path, it will also assume relative to the root
    # otherwise if you override with an absolute path, it will use the path as-is.
    default_output_folder  = 'packages'

    # update default parameters with environment vars:
    output_folder = os.environ.get("PACKAGE_output_folder", default = default_output_folder)

    @staticmethod
    def GetSPDXLicenseList():
        if not CommonUtils.spdx_license_list:
            # get the list from the official site
            try:
                context = ssl.create_default_context(cafile=certifi.where())
                with urllib.request.urlopen("https://spdx.org/licenses/licenses.json", context=context) as url:
                    data = json.loads(url.read().decode())
                    # validate that its actually the right content
                    if 'licenses' in data:
                        CommonUtils.spdx_license_list = data
                    else:
                        print("Invalid license format from spdx.org, see whats at https://spdx.org/licenses/licenses.json")
            except Exception as e:
                print("ERROR: Could not fetch the license list from  https://spdx.org/licenses/licenses.json, license validation unavailable")
                print(str(e))

        return CommonUtils.spdx_license_list or None

    @staticmethod
    def GetPALPlatformName():
        ''' Returns 'darwin', 'linux', or 'windows'
        '''
        platsys = platform.system().lower()
        # If the current platform is linux, add the architecture to the platform name as well
        if platsys == 'linux':
            if platform.machine() == 'aarch64':
                return f'{platsys}-{platform.machine()}'
            # For x86_64 and others, default to the legacy 'linux' as the PAL platform name
            return platsys
        elif platsys == 'darwin':
            if platform.machine() == 'arm64':
                return f'{platsys}-{platform.machine()}'

        return platsys

    @staticmethod
    def AddCommonArgs(argparser):
        argparser.add_argument('-o', '--output_folder', action='store', default=CommonUtils.output_folder, help='The folder to store the package in')
        argparser.add_argument('--search_path', type=str, required=True, action='store', help='Folder to search for package host list files')
        argparser.epilog = 'Note: You can set environment variables in the form\nPACKAGE_<paramname>\n to pass from env instead of command line'

    @staticmethod
    def PostArgParse(args):
        ''' Fixes up any args post 'argparse' pass to make sure defaults are as they are expected to be. '''
        if not args.search_path:
            print(f"Using default search path of '{CommonUtils.root_path}' - Override with --search_path")
            args.search_path = CommonUtils.root_path
        
        args.output_folder = os.path.join(args.search_path, args.output_folder)
        print(f"Output folder for packages is '{args.output_folder}' - Override with --output_folder")

    @staticmethod
    def ReadPackageInfo(package_descriptor_file_path):
        ''' Given a json file that should contain a package descriptor file
        Will read it and throw an exception if something is wrong
        '''
        with open(package_descriptor_file_path, encoding='utf8') as json_file:
            data = json.load(json_file)
            for required_field in CommonUtils.package_info_required_fields:
                if required_field not in data:
                    raise KeyError("Required field {} is missing from {}".format(required_field, data))
                if not data[required_field]:
                    raise KeyError("Required field {} is empty or invalid in {}".format(required_field, data))
                if len(data[required_field]) < 1:
                    raise KeyError("Required field {} is empty or invalid in {}".format(required_field, data))
    
            return data

    @staticmethod
    def GetPackageParts(package_name):
        ''' Yields all of the filenames expected for a given package name.'''
        known_addons = [
                CommonUtils.package_extension,
                CommonUtils.package_hash_extension,
                CommonUtils.package_content_hash_extension,
                "." + CommonUtils.package_descriptor_name,  # this must come last, as it is the final part.
        ]
        
        for element in known_addons:
            yield package_name + element

    @staticmethod
    def ParseSHA256SumsFile(path_to_file):
        ''' Parse a SHA256 Sums file.  Returns a dictionary:
        { name of file : expected hash}
        '''
        return_dict = {}
        lines = []
        with open(path_to_file, encoding='utf8') as shasums_file:
            lines = shasums_file.readlines()

        for line in lines:
            line = line.strip()
            space_pos = line.find(' ')
            if space_pos == -1:
                raise InvalidHashFormatException(f"Invalid line in hash file {path_to_file} line: {line}")
            hash_code = line[:space_pos]
            hash_filename = line[space_pos + 2:] # skip over the space found and next char
            # detect duplicates
            if hash_filename in return_dict:
                raise InvalidHashFormatException(f"Invalid line in hash file {path_to_file} same file appears twice: {hash_filename}")
            
            # detect invalid hashes:
            if not hash_code or not hash_filename or len(hash_code) != 64: # a sha256 is 64 characters long
                raise InvalidHashFormatException(f"Invalid line in hash file {path_to_file} invalid hash code: {line}")

            return_dict[hash_filename] = hash_code
        return return_dict
    
    @staticmethod 
    def ComputeHashOfFile(file_path):
        file_path = os.path.normpath(file_path)
        original_folder = os.path.dirname(file_path)
        hasher = hashlib.sha256()
        hash_result = None
        
        # if its a symlink we'll follow the link.  Note that this is what allows
        # the system to work in terms of a windows machine uploading packages made on
        # linux or MacOS.
        paths_considered = []
        while (os.path.islink(file_path)):
            resolved_path = os.readlink(file_path)
            if not os.path.isabs(resolved_path):
                resolved_path = os.path.join(original_folder, resolved_path)
                resolved_path = os.path.realpath(resolved_path)
                resolved_path = os.path.normpath(resolved_path)
            if resolved_path in paths_considered:
                print(f"Cyclic symlink detected in  {paths_considered} -> {resolved_path}")
                return None
            paths_considered.append(resolved_path)
            file_path = resolved_path

        with open(file_path, 'rb') as afile:
            buf = afile.read()
            hasher.update(buf)
            hash_result = hasher.hexdigest()
        
        return hash_result
    
    @staticmethod
    def VerifyPackageImage(package_image_folder):
        '''Returns True if the folder contains an unpacked, valid package.
            - must contain the package descriptor file
            - must have the content hash file
            - must hash match every file
            - no extra files allowed.
        '''
        expected_package_hash_file = os.path.join(package_image_folder, CommonUtils.package_root_hash_file_name)
        expected_package_json_file = os.path.join(package_image_folder, CommonUtils.package_descriptor_name)
        for expected_file in [expected_package_hash_file, expected_package_json_file]:
            if not os.path.isfile(expected_file): 
                print(f"Package is missing a file: {expected_file}")
                return False
        
        found_readonly_files = False
        try:
            package_sums = CommonUtils.ParseSHA256SumsFile(expected_package_hash_file)
            # make sure that the files on disk are the expected files:
            expected_files = sorted(package_sums.keys())
            actual_files = []
            for root, _, filenames in os.walk(package_image_folder):
                for name in filenames:
                    file_abspath = os.path.join(root, name)
                    relpath_from_folder = str(pathlib.Path(file_abspath).relative_to(package_image_folder).as_posix())

                    # files may not be read only inside the archive.
                    if not os.access(file_abspath, os.W_OK):
                        print(f"ERROR, Files are read-only in the archive: {relpath_from_folder}")
                        st = os.stat(file_abspath)
                        os.chmod(file_abspath, st.st_mode | stat.S_IWUSR)

                        # we dont bail immediately because we need to actually set all of these
                        # to be writable by user or else removing the temp dir will fail
                        found_readonly_files = True
                    
                    if relpath_from_folder != CommonUtils.package_root_hash_file_name: #ignore the SHA256SUMS file itself
                        actual_files.append(relpath_from_folder)

            actual_files = set(actual_files)
            expected_files = set(expected_files)
            
            missing_files = expected_files - actual_files
            unexpected_files = actual_files - expected_files

            if len(missing_files) > 0:
                print(f"Files are missing from the package: {missing_files}")
                return False
           
            if len(unexpected_files) > 0:
                print(f"Unexpected files found in package but not in hash set: {unexpected_files}")
                return False

            # all files accounted for.  Hash them now
            for file_to_hash in actual_files:
                actual_hash = CommonUtils.ComputeHashOfFile(os.path.join(package_image_folder, file_to_hash))
                if actual_hash != package_sums[file_to_hash]:
                    print(f"Hash of file is not correct: {file_to_hash}")
                    return False
            
            if found_readonly_files:
                print(f"Found read-only files in the archive, this is not ok.")
                return False

        except InvalidHashFormatException as e:
            print(f"Hash file parse failed: {e}")
            return False

        return CommonUtils.ValidatePackageLicense(package_image_folder)

    @staticmethod
    def ValidatePackageLicense(unpackaged_package_path):
        '''  Makes sure that the license file is present where the package descriptor says it is.
        '''
        try:
            expected_package_info_path = os.path.join(unpackaged_package_path, CommonUtils.package_descriptor_name)
            package_info = CommonUtils.ReadPackageInfo(expected_package_info_path)
        except FileNotFoundError as e:
            print(f"Package information file was not found: {e}")
            return False
        except KeyError as e:
            print(f"Package information was invalid: {e}")
            return False
        
        # make sure the stated license file is present:
        relpath_to_license = os.path.join(unpackaged_package_path, package_info['LicenseFile'])
        if not os.path.exists(relpath_to_license):
            print(f"License is not found where PackageInfo.json stated: {relpath_to_license}")
            return False
        
        # make sure its an actual valid SPDX license tag.
        licenses = CommonUtils.GetSPDXLicenseList()
        license_is_spdx_compliant = True
        license_is_ok = True

        if licenses:
            spdx_license_tag = package_info['License']
            official_license_names = [license['licenseId'] for license in licenses['licenses']]
            if spdx_license_tag not in official_license_names:
                license_is_spdx_compliant = False
                if spdx_license_tag.lower() != 'custom':
                    print(f'    - ERROR: "License" : "{spdx_license_tag}" in PackageInfo.json is not a valid SPDX LicenseId.')
                    print(f'          Find the right license or use "License" : "custom" in your PackageInfo.json')
                    license_is_ok = False
                else:
                    print(f'    - WARNING: "License" : "{spdx_license_tag}" in PackageInfo.json indicates a custom license.')
                    print(f"          Most packages use one of the licences from SPDX.  Use 'custom' only as a last resort.")
        
        if not license_is_spdx_compliant:
            print(f"          Check https://spdx.org/licenses for the official list of license Identifiers.")
            print(f"          Consider searching online for terms inside the license file to see if its one of the ones from SPDX.")
        
        return license_is_ok


    @staticmethod
    def FullyValidatePackage(package_folder, package_name):
        '''Given a folder containing a package SHA256SUMS file, JSON file, and all other parts
        Will actually untar (to temp), test all the contents, and ensure the entire package
        matches requirements/expectations.
        '''
        print(f"    - Validating package: {package_name} in folder {package_folder}....")
        for expected_file in CommonUtils.GetPackageParts(package_name):
            expected_abspath = os.path.join(package_folder, expected_file)
            if not os.path.exists(expected_abspath):
                print(f"        - FAILED!  Expected package part is missing: {expected_abspath}")
                return False

        # validate the hash of archive itself
        archive_path        = os.path.join(package_folder, package_name + CommonUtils.package_extension)
        archive_hash_path   = os.path.join(package_folder, package_name + CommonUtils.package_hash_extension)

        hash_result = CommonUtils.ComputeHashOfFile(archive_path)
        
        try:
        # parse the SHA256UMS file:
            package_full_name = package_name + CommonUtils.package_extension
            package_sums = CommonUtils.ParseSHA256SumsFile(archive_hash_path)
            if len(package_sums) != 1:
                print(f"Package sums file {archive_hash_path} is invalid - should only have one entry.")
                return False
            if package_full_name not in package_sums:
                print(f"Package sums file {archive_hash_path} is invalid - does not reference the actual package")
                print(f"Hash had: {package_sums} - filename is {package_full_name}")
                return False
            if hash_result != package_sums[package_full_name]:
                print(f"Package hash mismatch.  {archive_hash_path} has a different hash than the actual package.")
                return False

        except InvalidHashFormatException as e:
            print(f"Hash file parse failed for package: {e}")
            return False

        all_ok = False

        # unzip it to a temp space, and then verify the actual contents
        with tempfile.TemporaryDirectory() as tmpdirname:
            with tarfile.open(archive_path) as archive_file:
                archive_file.extractall(tmpdirname)
                all_ok = CommonUtils.VerifyPackageImage(tmpdirname)

        return all_ok

    @staticmethod
    def IngestPackageList(source_file_path, source_root_path, target_dictionary):
        ''' Reads a package list from source_file_path (which is expected)
        to be an absolute path to a json file, and merges it into the target dictionary.
        Note that file paths and folder paths appearing in dictionary values will
        assume relative paths from source root path and will be updated during ingestion

        Results in a target dictionary being populated with two keys, 
        target_dictionary['build_from_source'] = map[packagename] -> folder path containing build script
        target_dictionary['build_from_folder'] = map[packagename] -> folder path containing built package image
        '''
        if not 'build_from_source' in target_dictionary:
            target_dictionary['build_from_source'] = {}
        if not 'build_from_folder' in target_dictionary:
            target_dictionary['build_from_folder'] = {}

        if not os.path.exists(source_file_path):
            return

        data = {}
        
        print(f"Loading and merging {source_file_path} ...")

        with open(source_file_path, encoding='utf-8-sig') as json_file:
            data = json.load(json_file)
        
        if 'build_from_source' in data:
            for package_name in data['build_from_source'].keys():
                package_folder_and_args = data['build_from_source'][package_name].split(' ')
                package_folder = package_folder_and_args[0]
                package_folder_args = ' '.join(package_folder_and_args[1:]) if len(package_folder_and_args) > 1 else ''

                # note that we leave the build from source first arg relative so that it can find it..
                if not os.path.isabs(package_folder):
                    package_folder = os.path.join(source_root_path, package_folder)
                    package_folder = os.path.normpath(package_folder)
                target_dictionary['build_from_source'][package_name] = f"{package_folder} {package_folder_args}".strip()
        
        if 'build_from_folder' in data:
            for package_name in data['build_from_folder'].keys():
                package_folder = data['build_from_folder'][package_name]
                if not os.path.isabs(package_folder):
                    package_folder = os.path.join(source_root_path, package_folder)
                    package_folder = os.path.normpath(package_folder)
                target_dictionary['build_from_folder'][package_name] = package_folder

    @staticmethod
    def LoadPackageLists(folder, platform_override = None):
        '''Reads a series of package list files from the given set of folders.
        Note that it will load package_build_list.json
        and then override it with package_build_list_host_(PLATFORMNAME).json
        where PLATFORMNAME is 'darwin', 'linux' or 'windows', host platforms.'''

        host_platform = platform_override or CommonUtils.GetPALPlatformName()
        print(f"Loading {host_platform} package lists from {folder}...")
        data = {}
        
        basic_json_file_name = 'package_build_list.json'
        host_json_file_name = f'package_build_list_host_{host_platform}.json'
        
        # load host and platform files:
        actual_rootpath = pathlib.Path(folder).absolute()
        host_json_file_path = pathlib.Path(os.path.join(actual_rootpath, host_json_file_name)).absolute()
        CommonUtils.IngestPackageList(host_json_file_path, actual_rootpath, data)
    
        return data

    @staticmethod 
    def PrintPackageList(data):
        """ Given a package list data loaded by LoadPackageLists, prints it out in a friendly format"""
        print("   Packages to build from source:")
        for package_name in data['build_from_source'].keys():
            package_folder = data['build_from_source'][package_name]
            print(f"        '{package_name}' in '{package_folder}'")

        print("   Packages to build from folders (after building from source):")
        for package_name in data['build_from_folder'].keys():
            package_folder = data['build_from_folder'][package_name]
            print(f"        '{package_name}' in '{package_folder}'")