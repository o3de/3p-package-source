#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import sys
import subprocess
import argparse
import traceback

from common import CommonUtils
from pack_package import PackageUpFolder

"""This module creates the package specified on the command line, based on the package config files.
If the package has a build script, it will execute the build script, and then pack the package afterwards,
otherwise, it will invoke just the packing process.

Does not attempt to upload the package, and does not attempt to verify that its already uploaded.  Used
as a development tool.  
"""
def BuildPackage(package_name, output_folder, search_path):
    data = CommonUtils.LoadPackageLists(search_path)

    source_packages = data['build_from_source']
    folder_packages = data['build_from_folder']

    if package_name not in folder_packages:
            print(f"Error, package {package_name} is not in the build-from-folder list.")
            print(f"Even when building from source, add the folder created by the build script to the build-from-folder list")
            return 1

    if package_name in source_packages:
        # build from source!
        build_script_cmd = source_packages[package_name]
        build_script_path = build_script_cmd.split(' ')[0]

        # search for the build script in the search path (preferably) but if its not found
        # try the root path too:
        if not os.path.exists(build_script_path):
                print(f"Error: build script at {build_script_path} for package {package_name} not found!")
                return 1

        build_script_folder = os.path.dirname(build_script_path)
        # fetch and then execute the build script

        if package_name not in folder_packages:
            print(f"Error: {package_name} specified in the source packages, but not the folder packages!")
            return 1

        # Put the package_name in an environment variable so that the build script
        # can reference it if desired
        subprocess_env = os.environ.copy()
        subprocess_env["O3DE_PACKAGE_NAME"] = package_name

        print(f"Calling build script: \"{build_script_cmd}\"...")
        cmd = [sys.executable, '-s', build_script_path] + build_script_cmd.split(' ')[1:]
        output = subprocess.run(cmd, cwd=build_script_folder, env=subprocess_env)
        if output.returncode != 0:
            print(f"Package {package_name} failed to build from source.")
            return 1

    # now pack it up...
    package_abspath = folder_packages[package_name]
    package_info_file_path = os.path.join(package_abspath, CommonUtils.package_descriptor_name)
    # over here we'd sync the folder, if necessary, using p4 or git or whatever.
    # for now we assume its all fetched.
    if not os.path.exists(package_info_file_path):
        print(f"Package info file not found: {package_info_file_path} ... skipping")
        return 1
    try:
        data = CommonUtils.ReadPackageInfo(package_info_file_path)
        if data['PackageName'] != package_name:
            raise KeyError(f"Package {package_name} has a PackageInfo.json that calls itself {data['PackageName']} instead.")

        # build it:
        PackageUpFolder(package_abspath, output_folder)
    except Exception as e:
        print(f"Error:  {package_name} {e}")
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Creates a package from a folder which contains a PackageInfo.json file')
    parser.add_argument('package_name', help='The name of the package to build as it appears in the json config files.')
    
    CommonUtils.AddCommonArgs(parser)
    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    sys.exit(BuildPackage(args.package_name, args.output_folder, args.search_path))

