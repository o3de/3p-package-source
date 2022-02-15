#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import json
import os
import pathlib
import subprocess
import shutil
import urllib.request
import zipfile

PACKAGE_NAME: str = "AWSGameLiftServerSDK"
PACKAGE_VERSION: str = "3.4.2-rev1"
PACKAGE_PLATFORM: str = ""
PACKAGE_URL: str = "https://aws.amazon.com/documentation/gamelift/"
PACKAGE_LICENSE: str = "Apache-2.0"
PACKAGE_LICENSE_FILE: str = "LICENSE_AMAZON_GAMELIFT_SDK.txt"

GAMELIFT_SERVER_SDK_RELEASE_VERSION: str = "4.0.2"
GAMELIFT_SERVER_SDK_DOWNLOAD_URL: str = "https://gamelift-release.s3-us-west-2.amazonaws.com/GameLift_06_03_2021.zip"
PACKAGE_BASE_PATH: pathlib.Path = pathlib.Path(os.path.dirname(__file__))
PACKAGE_ROOT_PATH: pathlib.Path = PACKAGE_BASE_PATH.parent

# utils
class BuildError(Exception):
    pass

class WorkingDirectoryInfo(object):
    def __init__(self, root_path: pathlib.Path,
                 source_path: pathlib.Path,
                 build_path: pathlib.Path,
                 output_path: pathlib.Path,
                 libs_output_path: pathlib.Path) -> None:
        self.root_path = root_path
        self.source_path = source_path
        self.build_path = build_path
        self.output_path = output_path
        self.libs_output_path = libs_output_path

def subp_args(args):
    arg_string = " ".join([arg for arg in args])
    print(f"Command: {arg_string}")
    return arg_string

def delete_folder(folder: pathlib.Path) -> None:
    shutil.rmtree(folder.resolve())

# steps
def collect_package_info() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        required=True,
        choices=['windows']
    )
    
    args = parser.parse_args()
    global PACKAGE_PLATFORM
    PACKAGE_PLATFORM = args.platform_name

def prepare_working_directory() -> WorkingDirectoryInfo:
    # root directory
    root_directory: pathlib.Path = PACKAGE_BASE_PATH.joinpath("temp")
    if root_directory.is_dir():
        delete_folder(root_directory)
    
    # source and build directory
    source_directory: pathlib.Path = \
        root_directory.joinpath(f"GameLift-SDK-Release-{GAMELIFT_SERVER_SDK_RELEASE_VERSION}/GameLift-Cpp-ServerSDK-{PACKAGE_VERSION.split('-')[0]}")
    build_directory: pathlib.Path = root_directory.joinpath("build")
    build_directory.mkdir(parents=True)
    
    # build output and libs output directory
    build_output_directory: pathlib.Path = PACKAGE_ROOT_PATH.joinpath(f"{PACKAGE_NAME}-{PACKAGE_PLATFORM}")
    if build_output_directory.is_dir():
        delete_folder(build_output_directory)
    
    build_libs_output_directory: pathlib.Path = build_output_directory.joinpath(f"{PACKAGE_NAME}")
    build_libs_output_directory.mkdir(parents=True)
    
    return WorkingDirectoryInfo(root_directory, source_directory, build_directory, build_output_directory, build_libs_output_directory)

def download_gamelift_server_sdk(working_directory: WorkingDirectoryInfo) -> None:
    # download sdk from url
    gamelift_sdk_zip_file: str = working_directory.root_path.joinpath("gamelift_server_sdk.zip").resolve()
    with urllib.request.urlopen(GAMELIFT_SERVER_SDK_DOWNLOAD_URL) as response, open(gamelift_sdk_zip_file, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)
    
    # unzip sdk contents
    with zipfile.ZipFile(gamelift_sdk_zip_file, "r") as f:
        f.extractall(working_directory.root_path.resolve())

def build_gamelift_server_sdk(working_directory: WorkingDirectoryInfo,
                              build_type: str,
                              lib_type: str) -> None:
    build_folder: pathlib.Path = working_directory.build_path.joinpath(f"{build_type}_{lib_type}").resolve()
    build_shared: str = "ON" if lib_type == "Shared" else "OFF"
    
    print(f"Generating GameLift Server SDK project with {build_type} {lib_type} configuration...")
    configure_cmd: List[str] = ["cmake -G \"Visual Studio 16 2019\" -A x64 -S .",
                                f"-B {build_folder.resolve()}",
                                f"-DBUILD_SHARED_LIBS={build_shared}",
                                f"-DCMAKE_BUILD_TYPE={build_type}"]
    configure_result = subprocess.run(subp_args(configure_cmd),
                                      shell=True,
                                      capture_output=True,
                                      cwd=str(working_directory.source_path.resolve()))
    if configure_result.returncode != 0:
        raise BuildError(f"Error generating project: {str(configure_result.stderr)}")
    
    print(f"Building GameLift Server SDK project with {build_type} {lib_type} configuration...")
    build_cmd: List[str] = ["cmake",
                            f"--build {build_folder.resolve()}",
                            f"--config {build_type}",
                            "--target ALL_BUILD -j"]
    build_result = subprocess.run(subp_args(build_cmd),
                                  shell=True,
                                  capture_output=True,
                                  cwd=str(working_directory.source_path.resolve()))
    if build_result.returncode != 0:
        raise BuildError(f"Error building project: {str(build_result.stderr)}")
    
    print(f"Copying {build_type} {lib_type} built libs into output folder...")
    install_folder: pathlib.Path = build_folder.joinpath("prefix")
    
    if lib_type == "Shared":
        destination: pathlib.Path = working_directory.libs_output_path.joinpath(f"bin/{build_type}")
    else:
        destination: pathlib.Path = working_directory.libs_output_path.joinpath(f"lib/{build_type}")
    destination.mkdir(parents=True)
    
    if lib_type == "Shared":
        for file in install_folder.joinpath("bin").glob("*.dll"):
            shutil.copy2(file.resolve(), destination.resolve())
    
    for file in install_folder.joinpath("lib").glob("*.lib"):
        shutil.copy2(file.resolve(), destination.resolve())

def generate_packageInfo(working_directory: WorkingDirectoryInfo) -> None:
    settings={
        'PackageName': f'{PACKAGE_NAME}-{PACKAGE_VERSION}-{PACKAGE_PLATFORM}',
        "URL"         : f'{PACKAGE_URL}',
        "License"     : f'{PACKAGE_LICENSE}',
        'LicenseFile': f'{PACKAGE_NAME}/{PACKAGE_LICENSE_FILE}'
    }
    package_file: str = working_directory.output_path.joinpath("PackageInfo.json").resolve()
    with package_file.open('w') as fh:
        json.dump(settings, fh, indent=4)

def generate_cmake_file(working_directory: WorkingDirectoryInfo) -> None:
    cmake_file_source: pathlib.Path = PACKAGE_BASE_PATH.joinpath(f"Find{PACKAGE_NAME}.cmake.{PACKAGE_PLATFORM.title()}")
    if cmake_file_source.is_file():
        find_cmake_content = cmake_file_source.read_text("UTF-8", "ignore")

        target_cmake_file: pathlib.Path = working_directory.output_path.joinpath(f"Find{PACKAGE_NAME}.cmake")
        target_cmake_file.write_text(find_cmake_content)
    else:
        raise BuildError(f"Error finding cmake source file: {cmake_file_source.resolve()}")


if __name__ == '__main__':
    try:
        print("Collecting package build info for GameLift Server SDK...")
        collect_package_info()
        
        print("Prepare working directory...")
        working_directory: WorkingDirectoryInfo = prepare_working_directory()
        
        print(f"Downloading GameLift Server SDK from {GAMELIFT_SERVER_SDK_DOWNLOAD_URL}...")
        download_gamelift_server_sdk(working_directory)
        
        # build sdk with different configurations
        build_gamelift_server_sdk(working_directory, "Debug", "Shared")
        build_gamelift_server_sdk(working_directory, "Debug", "Static")
        build_gamelift_server_sdk(working_directory, "Release", "Shared")
        build_gamelift_server_sdk(working_directory, "Release", "Static")
        
        print("Copying include and license files into output directory...")
        shutil.copytree(working_directory.source_path.joinpath("gamelift-server-sdk/include").resolve(),
                        working_directory.libs_output_path.joinpath("include").resolve())
        shutil.copy2(working_directory.source_path.joinpath(PACKAGE_LICENSE_FILE).resolve(),
                     working_directory.libs_output_path.resolve())
        shutil.copy2(working_directory.source_path.joinpath("NOTICE_C++_AMAZON_GAMELIFT_SDK.txt").resolve(),
                     working_directory.libs_output_path.resolve())
        
        print("Generating package info into output directory...")
        generate_packageInfo(working_directory)
        
        print("Gnerating cmake file into output directory...")
        generate_cmake_file(working_directory)
        exit(0)
    except BuildError as err:
        print(err)
        exit(1)
