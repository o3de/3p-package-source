#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import glob
import json
import os
import pathlib
import subprocess
import shutil
import urllib.request
import zipfile
from typing import List

PACKAGE_NAME: str = "AWSGameLiftServerSDK"
PACKAGE_VERSION: str = "3.4.2-rev1"
PACKAGE_PLATFORM: str = ""
PACKAGE_URL: str = "https://aws.amazon.com/documentation/gamelift/"
PACKAGE_LICENSE: str = "Apache-2.0"
PACKAGE_LICENSE_FILE: str = "LICENSE_AMAZON_GAMELIFT_SDK.TXT"

GAMELIFT_SERVER_SDK_RELEASE_VERSION: str = "4.0.2"
GAMELIFT_SERVER_SDK_DOWNLOAD_URL: str = "https://gamelift-release.s3-us-west-2.amazonaws.com/GameLift_06_03_2021.zip"

PACKAGE_BASE_PATH: pathlib.Path = pathlib.Path(os.path.dirname(__file__))
PACKAGE_ROOT_PATH: pathlib.Path = PACKAGE_BASE_PATH.parent
PACKAGE_BUILD_TYPES: List[str] = ["Debug", "Release"]
PACKAGE_LIB_TYPES: List[str] = ["Shared", "Static"]
PACKAGE_PLATFORM_OPTIONS: List[str] = ["windows", "linux", "linux-aarch64"]

# Lookup table for the Find{PACKAGE_NAME}.cmake.{platform} source file to copy in case there are shared files across different platforms
FIND_CMAKE_PLATFORM_SUFFIX_BY_PLATFORM = {
    'Windows': 'Windows',
    'Linux': 'Linux',
    'Linux-Aarch64': 'Linux'
}

# utils
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

def subp_args(args) -> str:
    arg_string = " ".join([arg for arg in args])
    print(f"Command: {arg_string}")
    return arg_string

def delete_folder(folder: pathlib.Path) -> None:
    shutil.rmtree(folder.resolve())

def copy_file_to_destination(file: str, destination: str) -> None:
    print(f"Copying {file} to {destination}")
    shutil.copy2(file, destination)

# collect package build required information, like platform
def collect_package_info() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        required=True,
        choices=PACKAGE_PLATFORM_OPTIONS
    )
    
    args = parser.parse_args()
    global PACKAGE_PLATFORM
    PACKAGE_PLATFORM = args.platform_name

# prepare working directories for package build
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

# download gamelift server server sdk source code for package build
def download_gamelift_server_sdk(working_directory: WorkingDirectoryInfo) -> None:
    # download sdk from url
    gamelift_sdk_zip_file: str = str(working_directory.root_path.joinpath("gamelift_server_sdk.zip").resolve())
    with urllib.request.urlopen(GAMELIFT_SERVER_SDK_DOWNLOAD_URL) as response, open(gamelift_sdk_zip_file, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)
    
    # unzip sdk contents
    with zipfile.ZipFile(gamelift_sdk_zip_file, "r") as f:
        f.extractall(working_directory.root_path.resolve())

# apply required patch file to support package build
def apply_patch_on_sdk_source(working_directory: WorkingDirectoryInfo) -> None:
    patch_file: str = str(PACKAGE_BASE_PATH.joinpath(f"{PACKAGE_NAME}-{PACKAGE_VERSION.split('-')[0]}-{PACKAGE_PLATFORM}.patch").resolve())
    source_folder: str = str(working_directory.source_path.resolve())
    git_result = subprocess.run(subp_args(["git","init"]), 
                                shell=True,
                                capture_output=True,
                                cwd=source_folder)
    if git_result.returncode != 0:
        raise Exception(f"Error git init sdk source: {git_result.stderr.decode()}")
    git_result = subprocess.run(subp_args(["git","add","."]), 
                                shell=True,
                                capture_output=True,
                                cwd=source_folder)
    if git_result.returncode != 0:
        raise Exception(f"Error git add sdk source: {git_result.stderr.decode()}")
    git_result = subprocess.run(subp_args(["git","commit","-m","temp"]),
                                shell=True,
                                capture_output=True,
                                cwd=source_folder)
    if git_result.returncode != 0:
        raise Exception(f"Error git commit sdk source: {git_result.stderr.decode()}")
    git_result = subprocess.run(subp_args(["git","apply", "--ignore-space-change", "--ignore-whitespace", f"{patch_file}"]),
                                shell=True,
                                capture_output=True,
                                cwd=source_folder)
    if git_result.returncode != 0:
        raise Exception(f"Error git apply patch sdk source: {git_result.stderr.decode()}")

# get required custom environment for package build
def get_custom_build_env():
    if PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        custom_env = os.environ.copy()
        custom_env["CC"] = "clang"
        custom_env["CXX"] = "clang++"
        custom_env["CFLAGS"] = "-fPIC"
        custom_env["CXXFLAGS"] = "-fPIC"
        return custom_env
    return None

# configure gamelift server sdk project
def configure_sdk_project(source_folder: str,
                          build_folder: str,
                          build_type: str,
                          lib_type: str) -> None:
    build_shared: str = "ON" if lib_type == "Shared" else "OFF"
    if PACKAGE_PLATFORM == PACKAGE_PLATFORM_OPTIONS[0]:
        generator: str = "-G \"Visual Studio 15 2017\" -A x64"
    elif PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        generator: str = "-G \"Unix Makefiles\""
    else:
        raise Exception(f"Error unsupported platform: {PACKAGE_PLATFORM}")
        
    configure_cmd: List[str] = [f"cmake {generator} -S .",
                                f"-B {build_folder}",
                                f"-DBUILD_SHARED_LIBS={build_shared}",
                                f"-DCMAKE_BUILD_TYPE={build_type}"]
    configure_result = subprocess.run(subp_args(configure_cmd),
                                      shell=True,
                                      capture_output=True,
                                      cwd=source_folder,
                                      env=get_custom_build_env())
    if configure_result.returncode != 0:
        raise Exception(f"Error generating project: {configure_result.stderr.decode()}")

# build gamelift server sdk project
def build_sdk_project(source_folder: str,
                      build_folder: str,
                      build_type: str) -> None:
    if PACKAGE_PLATFORM == PACKAGE_PLATFORM_OPTIONS[0]:
        target: str = "--target ALL_BUILD"
    elif PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        target: str = ""
    else:
        raise Exception(f"Error unsupported platform: {PACKAGE_PLATFORM}")
    
    build_cmd: List[str] = ["cmake",
                            f"--build {build_folder}",
                            f"--config {build_type}",
                            f"{target} -j"]
    build_result = subprocess.run(subp_args(build_cmd),
                                  shell=True,
                                  capture_output=True,
                                  cwd=source_folder,
                                  env=get_custom_build_env())
    if build_result.returncode != 0:
        raise Exception(f"Error building project: {build_result.stderr.decode()}")

# copy all built gamelift server sdk libs into expected output folder
def copy_sdk_libs(libs_output_path: pathlib.Path,
                  build_path: pathlib.Path,
                  build_type: str,
                  lib_type: str) -> None:
    if lib_type == PACKAGE_LIB_TYPES[0]:
        destination: pathlib.Path = libs_output_path.joinpath(f"bin/{build_type}")
    else:
        destination: pathlib.Path = libs_output_path.joinpath(f"lib/{build_type}")
    destination.mkdir(parents=True)
    
    install_folder: pathlib.Path = build_path.joinpath("prefix")
    if PACKAGE_PLATFORM == PACKAGE_PLATFORM_OPTIONS[0]:
        shared_libs_pattern: str = str(install_folder.joinpath("bin/*.dll"))
        static_libs_pattern: str = str(install_folder.joinpath("lib/*.lib"))
        
        # for windows, it always requires .lib file, .dll file is only required for shared libs
        if lib_type == PACKAGE_LIB_TYPES[0]:
            for file in glob.glob(shared_libs_pattern):
                copy_file_to_destination(file, str(destination.resolve()))

        for file in glob.glob(static_libs_pattern):
            copy_file_to_destination(file, str(destination.resolve()))
    elif PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        shared_libs_pattern: str = str(install_folder.joinpath("lib/*.so*"))
        static_libs_pattern: str = str(install_folder.joinpath("lib/*.a"))
        
        # for linux, it requires .a file for static libs and .so file for shared libs
        if lib_type == PACKAGE_LIB_TYPES[0]:
            for file in glob.glob(shared_libs_pattern):
                copy_file_to_destination(file, str(destination.resolve()))
        else:
            for file in glob.glob(static_libs_pattern):
                copy_file_to_destination(file, str(destination.resolve()))
    else:
        raise Exception(f"Error unsupported platform: {PACKAGE_PLATFORM}")

def build_gamelift_server_sdk(working_directory: WorkingDirectoryInfo,
                              build_type: str,
                              lib_type: str) -> None:
    build_folder: pathlib.Path = working_directory.build_path.joinpath(f"{build_type}_{lib_type}").resolve()
    
    print(f"Generating GameLift Server SDK project with {build_type} {lib_type} configuration...")
    configure_sdk_project(working_directory.source_path.resolve(), build_folder.resolve(), build_type, lib_type)
    
    print(f"Building GameLift Server SDK project with {build_type} {lib_type} configuration...")
    build_sdk_project(working_directory.source_path.resolve(), build_folder.resolve(), build_type)
    
    print(f"Copying {build_type} {lib_type} built sdk libs into output folder...")
    copy_sdk_libs(working_directory.libs_output_path, build_folder, build_type, lib_type)

# generate required information for package, like name, url, and license
def generate_packageInfo(working_directory: WorkingDirectoryInfo) -> None:
    settings={
        'PackageName': f'{PACKAGE_NAME}-{PACKAGE_VERSION}-{PACKAGE_PLATFORM}',
        "URL"         : f'{PACKAGE_URL}',
        "License"     : f'{PACKAGE_LICENSE}',
        'LicenseFile': f'{PACKAGE_NAME}/{PACKAGE_LICENSE_FILE}'
    }
    package_file: str = str(working_directory.output_path.joinpath("PackageInfo.json").resolve())
    with open(package_file, 'w') as fh:
        json.dump(settings, fh, indent=4)

# generate required cmake file which is used to find package libs
def generate_cmake_file(working_directory: WorkingDirectoryInfo) -> None:
    cmake_file_source_suffix = FIND_CMAKE_PLATFORM_SUFFIX_BY_PLATFORM[PACKAGE_PLATFORM.title()]
    cmake_file_source: pathlib.Path = PACKAGE_BASE_PATH.joinpath(f"Find{PACKAGE_NAME}.cmake.{cmake_file_source_suffix}")
    if cmake_file_source.is_file():
        find_cmake_content = cmake_file_source.read_text("UTF-8", "ignore")

        target_cmake_file: pathlib.Path = working_directory.output_path.joinpath(f"Find{PACKAGE_NAME}.cmake")
        target_cmake_file.write_text(find_cmake_content)
    else:
        raise Exception(f"Error finding cmake source file: {str(cmake_file_source.resolve())}")


if __name__ == '__main__':
    try:
        print("Collecting package build info for GameLift Server SDK...")
        collect_package_info()
        
        print("Prepare working directory...")
        working_directory: WorkingDirectoryInfo = prepare_working_directory()
        
        print(f"Downloading GameLift Server SDK from {GAMELIFT_SERVER_SDK_DOWNLOAD_URL}...")
        download_gamelift_server_sdk(working_directory)
        
        print("Initializing and applying patch to GameLift Server SDK source....")
        apply_patch_on_sdk_source(working_directory)
        
        # build sdk with different configurations
        for build_type in PACKAGE_BUILD_TYPES:
                for lib_type in PACKAGE_LIB_TYPES:
                    build_gamelift_server_sdk(working_directory, build_type, lib_type)
        
        print("Copying include and license files into output directory...")
        shutil.copytree(working_directory.source_path.joinpath("gamelift-server-sdk/include").resolve(),
                        working_directory.libs_output_path.joinpath("include").resolve())
        copy_file_to_destination(str(working_directory.source_path.joinpath(PACKAGE_LICENSE_FILE).resolve()),
                                 str(working_directory.libs_output_path.resolve()))
        copy_file_to_destination(str(working_directory.source_path.joinpath("NOTICE_C++_AMAZON_GAMELIFT_SDK.TXT").resolve()),
                                 str(working_directory.libs_output_path.resolve()))
        
        print("Generating package info into output directory...")
        generate_packageInfo(working_directory)
        
        print("Generating cmake file into output directory...")
        generate_cmake_file(working_directory)
        exit(0)
    except Exception as e:
        print(e)
        exit(1)
