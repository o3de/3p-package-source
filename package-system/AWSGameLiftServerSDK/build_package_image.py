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
import sys
import urllib.request
import zipfile
from typing import List

# O3DE_PACKAGE_NAME is given in the format <PACKAGE_NAME>-<VERSION>-<PLATFORM>
O3DE_PACKAGE_NAME = os.environ['O3DE_PACKAGE_NAME']
O3DE_PACKAGE_NAME_PARTS = O3DE_PACKAGE_NAME.split('-')
PACKAGE_NAME: str = "AWSGameLiftServerSDK"
PACKAGE_PLATFORM: str = ""
PACKAGE_URL: str = "https://aws.amazon.com/documentation/gamelift/"
PACKAGE_LICENSE: str = "Apache-2.0"
PACKAGE_LICENSE_FILE: str = "LICENSE_AMAZON_GAMELIFT_SDK.TXT"

GAMELIFT_SERVER_SDK_RELEASE_VERSION: str = O3DE_PACKAGE_NAME_PARTS[1]
GAMELIFT_SERVER_SDK_DOWNLOAD_URL: str = "https://gamelift-release.s3-us-west-2.amazonaws.com/GameLift-SDK-Release-5.0.0.zip"

PACKAGE_BASE_PATH: pathlib.Path = pathlib.Path(os.path.dirname(__file__))
PACKAGE_ROOT_PATH: pathlib.Path = PACKAGE_BASE_PATH.parent
REPO_ROOT_PATH: pathlib.Path = PACKAGE_ROOT_PATH.parent
GENERAL_SCRIPTS_PATH = REPO_ROOT_PATH / 'Scripts' / 'extras'
PACKAGE_BUILD_TYPES: List[str] = ["Debug", "Release"]
PACKAGE_LIB_TYPES: List[str] = ["Shared", "Static"]
PACKAGE_PLATFORM_OPTIONS: List[str] = ["windows", "linux", "linux-aarch64"]

# Insert the 3p scripts path so we can use the package downloader to
# download the openssl dependency
sys.path.insert(1, str(GENERAL_SCRIPTS_PATH.resolve()))
from package_downloader import PackageDownloader

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
        self.dependencies_folder_path = (self.root_path / 'dependencies').resolve()

# OpenSSL dependency: (packagename,  hash)
OPENSSL_PACKAGE = ('OpenSSL-1.1.1o-rev1-windows', '52b9d2bc5f3e0c6e405a0f290d1904bf545acc0c73d6a52351247d917c4a06d2')
def get_dependencies(working_directory: WorkingDirectoryInfo) -> None:
    # Only windows has an additional dependency on openssl that we need to download from our own packages
    # The linux builds also rely on openssl, but they use the version on the system
    if PACKAGE_PLATFORM != 'windows':
        return

    print("Downloading dependencies...")

    package_name = OPENSSL_PACKAGE[0]
    package_hash = OPENSSL_PACKAGE[1]
    if not (working_directory.dependencies_folder_path / package_name).exists():
        if not PackageDownloader.DownloadAndUnpackPackage(package_name, package_hash, str(working_directory.dependencies_folder_path)):
            raise Exception("Failed to download OpenSSL dependency!")
    else:
        print(f'OpenSSL already in dependencies folder, skipping. Use --clean to refresh')

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
        root_directory.joinpath(f"GameLift-SDK-Release-{GAMELIFT_SERVER_SDK_RELEASE_VERSION}/GameLift-Cpp-ServerSDK-{GAMELIFT_SERVER_SDK_RELEASE_VERSION}")
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
        unzip_path = working_directory.root_path.resolve()
        for file in f.namelist():
            # Ignore the __MACOSX metadata file structure because unzipping
            # it as well can exceed the max path on windows
            if not file.startswith('__MACOSX'):
                f.extract(file, unzip_path)

# get required custom environment for package build
def get_custom_build_env():
    if PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        custom_env = os.environ.copy()
        custom_env["CC"] = "gcc"
        custom_env["CXX"] = "g++"
        custom_env["CFLAGS"] = "-fPIC"
        custom_env["CXXFLAGS"] = "-fPIC"
        return custom_env
    return None

# configure gamelift server sdk project
def configure_sdk_project(working_directory: WorkingDirectoryInfo,
                          build_folder: str,
                          build_type: str,
                          lib_type: str) -> None:
    source_folder: str = working_directory.source_path.resolve()
    build_shared: str = "ON" if lib_type == "Shared" else "OFF"
    if PACKAGE_PLATFORM == PACKAGE_PLATFORM_OPTIONS[0]:
        generator: str = "-G \"Visual Studio 17\""
    elif PACKAGE_PLATFORM in (PACKAGE_PLATFORM_OPTIONS[1], PACKAGE_PLATFORM_OPTIONS[2]):
        generator: str = "-G \"Unix Makefiles\""
    else:
        raise Exception(f"Error unsupported platform: {PACKAGE_PLATFORM}")

    configure_cmd: List[str] = [f"cmake {generator} -S .",
                                f"-B {build_folder}",
                                f"-DBUILD_SHARED_LIBS={build_shared}",
                                f"-DCMAKE_BUILD_TYPE={build_type}"]

    # On windows add our OpenSSL dependency to the DCMAKE_MODULE_PATH so the
    # GameLift build can find it
    if PACKAGE_PLATFORM == 'windows':
        package_name = OPENSSL_PACKAGE[0]
        openssl_dependency_path = (working_directory.dependencies_folder_path / package_name).resolve().as_posix()
        configure_cmd.append(f"-DCMAKE_MODULE_PATH=\"{openssl_dependency_path}\"")

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
    configure_sdk_project(working_directory, build_folder.resolve(), build_type, lib_type)

    print(f"Building GameLift Server SDK project with {build_type} {lib_type} configuration...")
    build_sdk_project(working_directory.source_path.resolve(), build_folder.resolve(), build_type)

    print(f"Copying {build_type} {lib_type} built sdk libs into output folder...")
    copy_sdk_libs(working_directory.libs_output_path, build_folder, build_type, lib_type)

# generate required information for package, like name, url, and license
def generate_packageInfo(working_directory: WorkingDirectoryInfo) -> None:
    settings={
        'PackageName': f'{O3DE_PACKAGE_NAME}',
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

        # Retrieve any dependencies (if needed)
        get_dependencies(working_directory)

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
