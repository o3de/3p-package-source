#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import logging
import os
import pathlib
import platform
import requests
import shutil
import string
import subprocess
import tarfile
import time


SCRIPT_PATH = pathlib.Path(__file__).parent
PATCH_FILE = SCRIPT_PATH / "mcpp-2.7.2-az.2.patch"
PYTHON_PATCHER = SCRIPT_PATH / ".." / ".." / "Scripts" / "extras" / "patch.py"
SOURCE_NAME = "mcpp-2.7.2"
SOURCE_TAR_FILE = f"{SOURCE_NAME}.tar.gz"
SOURCEFORGE_URL = "https://sourceforge.net/projects/mcpp/files/mcpp/V.2.7.2"
SOURCEFORGE_DOWNLOAD_URL = f"{SOURCEFORGE_URL}/{SOURCE_TAR_FILE}/download"

PLATFORM_LINUX = 'linux'
PLATFORM_MAC = 'mac'
PLATFORM_WINDOWS = 'windows'

if platform.system() == 'Linux':
    platform_name = PLATFORM_LINUX
    shared_lib_name = 'libmcpp.so'
    static_lib_name = 'libmcpp.a'
elif platform.system() == 'Darwin':
    platform_name = PLATFORM_MAC
    shared_lib_name = 'libmcpp.dylib'
    static_lib_name = 'libmcpp.a'
elif platform.system() == 'Windows':
    platform_name = PLATFORM_WINDOWS
    static_lib_name = 'mcpp0.lib'
    shared_lib_name = 'mcpp0.dll'

    # Note: If we are running from windows, this script must be run from a visual studio command prompt
    # We will check the system environment to make sure that 'INCLUDE', 'LIB', 'LIBPATH' are set
    for vs_env_key in ('INCLUDE', 'LIB', 'LIBPATH'):
        if os.environ.get(vs_env_key) is None:
            print("This script must be run from a visual studio command prompt, or the visual studio command line"
                  " environments must be set")
            exit(1)
    # Check it's running under x64 build environment.
    vs_target_arch = os.environ.get('VSCMD_ARG_TGT_ARCH')
    if vs_target_arch is None:
        print("Couldn't read the environment variable 'VSCMD_ARG_TGT_ARCH'. This script must be run from a x64 visual studio command prompt, or the visual studio command line"
              " environments must be set")
        exit(1)
    if vs_target_arch != 'x64':
        print("This script must be run from a x64 visual studio command prompt, or the visual studio command line"
              " environments must be set")
        exit(1)
else:
    assert False, "Invalid platform"

assert platform_name in (PLATFORM_LINUX, PLATFORM_MAC, PLATFORM_WINDOWS), f"Invalid platform_name {platform_name}"

TARGET_3PP_PACKAGE_FOLDER = SCRIPT_PATH.parent / f'mcpp-{platform_name}'

MCPP_DETAIL = f"""
The MCPP package will be patched and built from the following sources

Sourceforge URL                    : {SOURCEFORGE_URL}
Source name                        : {SOURCE_NAME}
Patch File                         : {PATCH_FILE}
Target Pre-package Platform target : {TARGET_3PP_PACKAGE_FOLDER}
Example command:

python get_and_build_linux.sh mcpp-2.7.2_az.1-rev1-{platform_name}
"""


def execute_cmd(cmd, cwd=None, shell=False, suppress_std_err=False, env=None):
    logging.debug(f"[DEBUG] Calling {subprocess.list2cmdline(cmd)}")
    if shell:
        cmd = subprocess.list2cmdline(cmd)
    return subprocess.call(cmd,
                           shell=shell,
                           cwd=cwd,
                           env=env,
                           stderr=subprocess.DEVNULL if suppress_std_err else subprocess.STDOUT)


def prepare_temp_folder(temp_folder):
    if temp_folder.exists():
        shutil.rmtree(str(temp_folder.resolve()), ignore_errors=True)
    os.makedirs(temp_folder, exist_ok=True)
    return True


def download_from_source_forge(source_forge_download_url, temp_folder):

    try:
        request = requests.get(source_forge_download_url, allow_redirects=True)
        target_file = temp_folder / SOURCE_TAR_FILE
        if target_file.is_file():
            target_file.unlink()

        with open(str(target_file.resolve()), 'wb') as request_stream:
            bytes_written = request_stream.write(request.content)

        logging.debug(f'[DEBUG] {SOURCE_TAR_FILE} downloaded ({bytes_written} bytes)')
        return True
    except Exception as e:
        logging.fatal(f'[FATAL] Error downloading from {source_forge_download_url} : {e}')
        return False


def extract_tarfile(temp_folder):
    try:
        target_file = temp_folder / SOURCE_TAR_FILE
        if not target_file.is_file():
            logging.error(f'[ERROR] Missing expected tar file {target_file}')
        tar = tarfile.open(str(target_file), 'r:gz')
        tar.extractall(path=str(temp_folder.resolve()))
        logging.debug(f'[DEBUG] {SOURCE_TAR_FILE} extracted to ({str(temp_folder.resolve())})')
        return True
    except Exception as e:
        logging.fatal(f'[FATAL] extracting tar file {target_file} : {e}')
        return False


def apply_patch(temp_folder, patch_file):

    pristine_source_path = str((temp_folder / SOURCE_NAME).resolve())

    # Git apply for some reason fails on windows, but works on other platforms. We will first try 'git', and if that
    # fails, we will try 'patch'
    apply_patch_cmds = [
        ('python', [str(PYTHON_PATCHER.resolve()), str(patch_file.resolve())]),
        ('patch', ['--strip=1', f'--input={str(patch_file.resolve())}'])
    ]

    try:
        patched = False
        for apply_patch_cmd in apply_patch_cmds:
            patch_cmd = apply_patch_cmd[0]
            logging.info(f"Attempt to patch with {patch_cmd}")

            result = execute_cmd([patch_cmd, '--version'], shell=True, suppress_std_err=True)
            if result != 0:
                logging.debug(f"[DEBUG] Unable to locate cmd {patch_cmd} for patching.")
                continue

            patch_full_cmd = [patch_cmd]
            patch_full_cmd.extend(apply_patch_cmd[1])
            result = execute_cmd(patch_full_cmd, shell=True, cwd=pristine_source_path)
            if result != 0:
                logging.debug(f"[DEBUG] cmd {patch_cmd} failed for patching.")
                continue
            patched = True
            break

        if not patched:
            logging.error(f"[ERROR] Unable to patch. Make sure to 'patch' or 'git' is installed.")

        return patched
    except Exception as e:
        logging.fatal(f'[FATAL] Error applying patch file {patch_file} : {e}')
        return False


def configure_build(temp_folder):
    try:
        pristine_source_path = str((temp_folder / SOURCE_NAME).resolve())

        if platform_name == PLATFORM_WINDOWS:
            # Windows does not have a configure, instead it will use a modified visualc.mak directly
            # Copy the modified visualc.mak file to the patched source directory for the subsequent build step
            src_visualc_mak = SCRIPT_PATH / 'visualc.mak'
            dst_visualc_mak = temp_folder / SOURCE_NAME / 'src' / 'visualc.mak'
            shutil.copyfile(str(src_visualc_mak.resolve()), str(dst_visualc_mak.resolve()))
        else:
            if platform_name == PLATFORM_MAC:
                # For mac, we need to disable the 'implicit-function-declaration' or else the build will fail
                env_copy = os.environ.copy()
                env_copy['CFLAGS'] = '-Wno-implicit-function-declaration'
            else:
                env_copy = None

            # Mac and Linux use the built in ./configure command
            if execute_cmd(['./configure',
                            '--with-pic',
                            '--enable-mcpplib'],
                           cwd=pristine_source_path,
                           suppress_std_err=True,
                           env=env_copy) != 0:
                logging.fatal(f'[ERROR] Error configuring build.')
                return False

        return True
    except Exception as e:
        logging.fatal(f'[FATAL] Error configuring build : {e}')
        return False


def build_from_source(temp_folder):
    try:

        if platform_name == PLATFORM_WINDOWS:
            # Windows will use a precreated visualc.mak file instead of configure/make.
            source_working_path = str((temp_folder / SOURCE_NAME / 'src').resolve())

            build_cmds = [
                ['nmake', '/f', 'visualc.mak', 'COMPILER=MSC'],
                ['nmake', '/f', 'visualc.mak', 'COMPILER=MSC', 'MCPP_LIB=1', 'mcpplib']
            ]

            for build_cmd in build_cmds:
                if execute_cmd(build_cmd, cwd=source_working_path) != 0:
                    logging.fatal(f'[ERROR] Error building from source.')
                    return False

        else:
            # Mac/Linux will use 'make' to build
            pristine_source_path = str((temp_folder / SOURCE_NAME).resolve())
            result = execute_cmd(['make'],
                                 cwd=pristine_source_path,
                                 suppress_std_err=True)
            if result != 0:
                logging.fatal(f'[ERROR] Error building from source.')
                return False

        return True
    except Exception as e:
        logging.fatal(f'[FATAL] Error building from source : {e}')
        return False


def copy_build_artifacts(temp_folder):
    # Copying LICENSE, headers and libs
    source_path = temp_folder / SOURCE_NAME
    target_mcpp_root = TARGET_3PP_PACKAGE_FOLDER / 'mcpp'

    file_copy_tuples = [
        (source_path / 'LICENSE', target_mcpp_root),
        (source_path / 'src' / 'mcpp_lib.h', target_mcpp_root / 'include'),
        (source_path / 'src' / 'mcpp_out.h', target_mcpp_root / 'include')
        ]
    if platform_name == 'linux':
        file_copy_tuples.extend([
            (source_path / 'src' / '.libs' / 'libmcpp.a', target_mcpp_root / 'lib'),
            (source_path / 'src' / '.libs' / 'libmcpp.so.0.3.0', target_mcpp_root / 'lib'),
            (source_path / 'src' / '.libs' / 'mcpp', target_mcpp_root / 'lib')
        ])
    elif platform_name == 'mac':
        file_copy_tuples.extend([
            (source_path / 'src' / '.libs' / 'libmcpp.a', target_mcpp_root / 'lib'),
            (source_path / 'src' / '.libs' / 'libmcpp.0.3.0.dylib', target_mcpp_root / 'lib'),
            (source_path / 'src' / '.libs' / 'mcpp', target_mcpp_root / 'lib')
        ])
    elif platform_name == 'windows':
        file_copy_tuples.extend([
            (source_path / 'src' / 'mcpp0.dll', target_mcpp_root / 'lib'),
            (source_path / 'src' / 'mcpp0.lib', target_mcpp_root / 'lib'),
            (source_path / 'src' / 'mcpp.exe', target_mcpp_root / 'lib')
        ])

    for file_copy_tuple in file_copy_tuples:
        src = file_copy_tuple[0]
        dst = file_copy_tuple[1]
        if not src.is_file():
            logging.error(f'[ERROR] Missing source file {str(src)}')
            return False
        if not dst.is_dir():
            os.makedirs(str(dst.resolve()))
        shutil.copy2(str(src), str(dst))

    dst_lib_folder = target_mcpp_root / 'lib'
    if platform_name == 'linux':
        base_shared_lib_name = 'libmcpp.so.0.3.0'
        symlinks = ['libmcpp.so.0', 'libmcpp.so']
    elif platform_name == 'mac':
        base_shared_lib_name = 'libmcpp.0.3.0.dylib'
        symlinks = ['libmcpp.0.dylib', 'libmcpp.dylib']
    else:
        base_shared_lib_name = None
        symlinks = None

    if base_shared_lib_name and symlinks:
        for symlink in symlinks:
            execute_cmd(['ln', '-s', base_shared_lib_name, symlink], cwd=str(dst_lib_folder))

    return True


def create_3PP_package(temp_folder, package_label):

    if TARGET_3PP_PACKAGE_FOLDER.is_dir():
        shutil.rmtree(str(TARGET_3PP_PACKAGE_FOLDER.resolve()), ignore_errors=True)
    os.makedirs(str(TARGET_3PP_PACKAGE_FOLDER.resolve()), exist_ok=True)

    # Generate the find cmake file from the template file
    find_cmake_template_file = SCRIPT_PATH / f'Findmcpp.cmake.template'
    assert find_cmake_template_file.is_file(), f"Missing template file {find_cmake_template_file}"
    find_cmake_template_file_content = find_cmake_template_file.read_text("UTF-8", "ignore")

    template_env = {
        "MCPP_SHARED_LIB": shared_lib_name,
        "MCPP_STATIC_LIB": static_lib_name
    }

    find_cmake_content = string.Template(find_cmake_template_file_content).substitute(template_env)
    dst_find_cmake = TARGET_3PP_PACKAGE_FOLDER / 'Findmcpp.cmake'
    dst_find_cmake.write_text(find_cmake_content)

    # Generate the PackageInfo
    package_info_content = f'''
{{
    "PackageName" : "{package_label}-{platform_name}",
    "URL"         : "{SOURCEFORGE_URL}",
    "License"     : "custom",
    "LicenseFile" : "mcpp/LICENSE"
}}
'''
    package_info_target = TARGET_3PP_PACKAGE_FOLDER / 'PackageInfo.json'
    logging.debug(f'[DEBUG] Generating  {package_info_target}')
    package_info_target.write_text(package_info_content)

    return copy_build_artifacts(temp_folder)


def main():

    parser = argparse.ArgumentParser(description="Script to build the O3DE complaint 3rd Party Package version of the mcpp open source project.",
                                     formatter_class=argparse.RawDescriptionHelpFormatter,
                                     epilog=MCPP_DETAIL)
    parser.add_argument(
        'package_label',
        help="The package name and revision"
    )
    parser.add_argument(
        '--debug',
        help="Enable debug messages",
        action="store_true"
    )
    args = parser.parse_args()
    logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG if args.debug else logging.INFO)

    logging.info("Preparing temp working folder")
    temp_folder = SCRIPT_PATH / 'temp'
    if not prepare_temp_folder(temp_folder):
        return False

    logging.info("Downloading from sourceforge")
    if not download_from_source_forge(SOURCEFORGE_DOWNLOAD_URL, temp_folder):
        return False

    logging.info("Extracting source tarball")
    if not extract_tarfile(temp_folder):
        return False

    logging.info("Apply Patch File")
    if not apply_patch(temp_folder, PATCH_FILE):
        return False

    logging.info("Configuring Build")
    if not configure_build(temp_folder):
        return False

    logging.info("Building from source")
    if not build_from_source(temp_folder):
        return False

    logging.info("Creating 3PP Target")
    if not create_3PP_package(temp_folder, args.package_label):
        return False

    # If successful, delete the temp folder
    if temp_folder.exists():
        shutil.rmtree(str(temp_folder.resolve()), ignore_errors=True)

    logging.info("MCPP Package complete")


    return True


if __name__ == '__main__':

    start = time.time()

    result = main()

    elapsed = time.time() - start
    hour = int(elapsed // 3600)
    minute = int((elapsed - 3600*hour) // 60)
    seconds = int((elapsed - 3600*hour - 60*minute))

    logging.info(f'Total time {hour}:{minute:02d}:{seconds:02d}')

    if result:
        exit(0)
    else:
        exit(1)

