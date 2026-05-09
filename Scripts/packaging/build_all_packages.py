#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
 
import os
import subprocess
import argparse
import sys
import traceback

from common import CommonUtils
from find_package_on_server import FindPackageUtils
from pack_package import PackageUpFolder

def BuildPackages(output_folder, search_paths, server_urls, aws_profile_name):
    ''' BuildPackages is essentially the main function.
    Given an output_folder, paths to search for trees of json files, 
    and urls of servers to contact, it will build all missing packages
    to the output folder, including invoking build scripts as necessary.
    '''
    
    data = CommonUtils.LoadPackageLists(search_paths)
    CommonUtils.PrintPackageList(data)

    failed_source_packages = []
    failed_folder_packages = []
    exitCode = 0

    source_packages = data['build_from_source']
    folder_packages = data['build_from_folder']

    packages_already_found_on_server = []

    print("Building packages from source...")
    # first, find out which packages, if any, need to be built from source
    for package_name in source_packages.keys():
        print(f"    Package: '{package_name}'...")
        found = FindPackageUtils.FindPackageOnServer(package_name, server_urls, aws_profile_name)
        if found:
            # we dont attempt to build packages already present on the package servers.
            print(f"    - {package_name} already found at {found}")
            packages_already_found_on_server.append(package_name)
            continue
        build_script_cmd = source_packages[package_name]
        build_script_path = build_script_cmd.split(' ')[0]
        build_script_folder = os.path.dirname(build_script_path)
        # fetch and then execute the build script
        if not os.path.exists(build_script_path):
            print(f"Error: build script at {build_script_path} for package {package_name} not found!")
            failed_source_packages.append(package_name)
            exitCode = 1
            continue

        if package_name not in folder_packages:
            print(f"Error: {package_name} specified in the source packages, but not the folder packages!")
            failed_source_packages.append(package_name)
            exitCode = 1
            continue

        print(f"Calling build script: \"{build_script_cmd}\"...")
        cmd = [sys.executable, '-s'] + build_script_cmd.split(' ')
        output = subprocess.run(cmd, cwd=build_script_folder)
        if output.returncode != 0:
            print(f"Build script for package {package_name} failed, will not attempt to create package for it")
            failed_source_packages.append(package_name)
            exitCode = 1
            
    print("Building packages from folders...")
    for package_name in folder_packages.keys():
        if package_name in failed_source_packages:
            print(f"    Package: '{package_name}' skipped since it failed to build.")
            continue

        if package_name in packages_already_found_on_server:
            print(f"    Package: '{package_name}' skipped since its already uploaded.")
            continue

        print(f"    Package: '{package_name}'...")
        found = FindPackageUtils.FindPackageOnServer(package_name, server_urls, aws_profile_name)
        if found:
            print(f"    - {package_name} already at {found}.")
            packages_already_found_on_server.append(package_name)
        
        if not package_name in packages_already_found_on_server:
            package_abspath = folder_packages[package_name]
            package_info_file_path = os.path.join(package_abspath, CommonUtils.package_descriptor_name)
            # over here we'd sync the folder, if necessary, using p4 or git or whatever.
            # for now we assume its all fetched.
            if not os.path.exists(package_info_file_path):
                print(f"Error: Package info file not found: {package_info_file_path} ... skipping")
                failed_folder_packages.append(package_name)
                exitCode = 1
                continue
            try:
                data = CommonUtils.ReadPackageInfo(package_info_file_path)
                if data['PackageName'] != package_name:
                    raise KeyError(f"Package {package_name} has a PackageInfo.json that claims its {data['PackageName']} instead.")
            
                # build it:
                if not PackageUpFolder(package_abspath, output_folder):
                    print(f"Error:  {package_name} failed to package up correctly.")
                    exitCode = 1
                    failed_folder_packages.append(package_name)

            except Exception as e:
                print(f"Error:  {package_name} {e}") 
                exitCode = 1
                failed_folder_packages.append(package_name)
                traceback.print_exc()
                continue

    if packages_already_found_on_server:
        print("The following packages were skipped as they were already on the server(s)")
        for package_name in packages_already_found_on_server:
            print(f"   [SKIPPED] - {package_name}")
    
    if failed_source_packages:
        print("WARNING: These packages failed to build from source:")
        for package_name in failed_source_packages:
            print(f"   [FAILED] - {package_name}")

    if failed_folder_packages:
        print("WARNING: These packages failed to build from folder:")
        for package_name in failed_folder_packages:
            print(f"   [FAILED] - {package_name}")
    
    return exitCode

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Builds any missing packages into the packages folder, based on package list json files.')
    CommonUtils.AddCommonArgs(parser)
    FindPackageUtils.AddServerArgs(parser)
    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    if args.profile_name:
        print(f"Using AWS profile: {args.profile_name}")

    if not args.server_urls:
        print("You must specify server urls to check in order to use this script")
        print("Either set LY_PACKAGE_SERVER_URLS (semi colon list) or specify it in the command line in --server_urls (semi colon list)")
        sys.exit(1)

    exitCode = BuildPackages(args.output_folder, args.search_path, args.server_urls, args.profile_name)
    sys.exit(exitCode)
