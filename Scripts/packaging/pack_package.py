#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import tarfile
import pathlib
import argparse
import lzma
import stat
import shutil
from glob import glob

from common import CommonUtils

# this module will pack up a folder given a folder name, essentially a zip file creator
# and validator.
# if you want to actually use the package system (ie, the build scripts, etc) use build_package.py instead.

_archive_buffer_size = 1024 * 1024 * 10 # 10mb buffer

def _NoReadOnlyTarFileFilter(tarinfo):
    # remove any readonly flags from any given tar element
    tarinfo.mode = tarinfo.mode | stat.S_IWUSR | stat.S_IWGRP | stat.S_IWOTH
    return tarinfo

def PackageUpFolder(package_folder_path, output_folder):
    ''' Packages up a folder into an package-file and stamps it with SHASUMS and so forth
    '''
    package_descriptor_path = os.path.join(package_folder_path, CommonUtils.package_descriptor_name)
    if not os.path.exists(package_descriptor_path):
        raise FileNotFoundError('package descriptor file was not found {}'.format(package_descriptor_path))

    package_info = CommonUtils.ReadPackageInfo(package_descriptor_path)

    if not CommonUtils.ValidatePackageLicense(package_folder_path):
        # we failed to validate the license file, bail!
        return False

    package_name = package_info['PackageName']

    # build script does not exist, assume just an existing package folder

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    print("Creating/Updating package: {}".format(package_name))
    # we would normally use mkstemp but we actually want a temp folder on the same volume
    # so that fast renames work.
    temp_output_path = os.path.join(output_folder, "temp")

    if not os.path.exists(temp_output_path):
        os.makedirs(temp_output_path)

    # create a manifest which has the hash and name of every file in the folder.
    # this includes the package info file.
    path_to_scan = pathlib.Path(package_folder_path)
    file_hashes = {} # map of 'relative path' -> sha256sum
    files_to_add = {} # map of 'absolute path' -> relative path from the package root

    # Note:  While it would be great to use pathlib.glob, it doesn't 'see' symlinks!
    # We have to use glob.glob instead, then wrap it in a pathlib.Path:
    path_list = list(path_to_scan.glob("**/*"))
    for path_str in path_list:
        individual_path = pathlib.Path(path_str)
        if not individual_path.is_dir():
            individual_relpath = individual_path.relative_to(package_folder_path)
            individual_relpath = individual_relpath.as_posix()
            individual_abspath = individual_path.absolute()

            hash_result = CommonUtils.ComputeHashOfFile(individual_abspath)
            file_hashes[individual_relpath] = hash_result
            files_to_add[individual_abspath] = individual_relpath

    individual_file_hashes_string = ''
    for hash_key in file_hashes.keys():
        individual_file_hashes_string += "{} *{}\n".format(file_hashes[hash_key], hash_key)

    package_file_name = package_name + CommonUtils.package_extension
    full_package_file_name       = os.path.join(output_folder, package_name + CommonUtils.package_extension)
    full_hash_file_name          = os.path.join(output_folder, package_name + CommonUtils.package_hash_extension)
    full_contents_hash_file_name = os.path.join(output_folder, package_name + CommonUtils.package_content_hash_extension)
    full_package_info_file_name  = os.path.join(output_folder, package_name + "." + CommonUtils.package_descriptor_name)
    temp_package_file  = os.path.join(temp_output_path, 'temp_package_' + package_name)  # temp file for the package itself
    temp_package_hash_file = os.path.join(temp_output_path, 'temp_package_hash_' + package_name) # temp file for the hash of the package itself
    temp_package_contents_hash_file_path = os.path.join(temp_output_path, 'temp_package_contents_hash_' + package_name) # temp file for the hash of the package itself

    # using LZMA yields overall best compression for packages tested:
    compression_level = lzma.PRESET_EXTREME|9
    with tarfile.open(temp_package_file, mode="w:xz", bufsize=_archive_buffer_size, preset=compression_level) as tar:
        print('    Adding files to: "{}"'.format(temp_package_file))
        for individual_file in files_to_add.keys():
            tar.add(str(individual_file), arcname=str(files_to_add[individual_file]), filter=_NoReadOnlyTarFileFilter)

        # save the contents hash to root
        with open(temp_package_contents_hash_file_path, "wb") as temp_package_contents_hash_file:
            temp_package_contents_hash_file.write(individual_file_hashes_string.encode('utf8'))

        tar.add(temp_package_contents_hash_file_path, arcname=CommonUtils.package_root_hash_file_name, filter=_NoReadOnlyTarFileFilter)

    new_hash_contents = ''

    file_hash = CommonUtils.ComputeHashOfFile(temp_package_file)
        
    with open(temp_package_hash_file, "wb") as package_hash_file:
        new_hash_contents = "{} *{}\n".format(file_hash, package_file_name)
        package_hash_file.write(new_hash_contents.encode("utf8"))

    # replace them all
    if os.path.exists(full_package_file_name):
        os.remove(full_package_file_name)

    if os.path.exists(full_hash_file_name):
        os.remove(full_hash_file_name)

    if os.path.exists(full_contents_hash_file_name):
        os.remove(full_contents_hash_file_name)
    
    os.rename(temp_package_file, full_package_file_name)
    os.rename(temp_package_hash_file, full_hash_file_name)
    os.rename(temp_package_contents_hash_file_path, full_contents_hash_file_name)
    shutil.copyfile(package_descriptor_path, full_package_info_file_name)

    print("    Created: {}".format(full_package_file_name))
    print("    Created: {}".format(full_hash_file_name))   
    print("    Created: {}".format(full_contents_hash_file_name))
    print("    Created: {}".format(full_package_info_file_name))
    
    returnCode = CommonUtils.FullyValidatePackage(output_folder, package_name)

    print(f"    Package Hash: {new_hash_contents}")
    return returnCode

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Creates a package from a folder which contains a PackageInfo.json file')
    parser.add_argument('source_folder', help='The folder to turn into a package.')
    CommonUtils.AddCommonArgs(parser)    
    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    PackageUpFolder(args.source_folder, args.output_folder)

