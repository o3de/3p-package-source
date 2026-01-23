#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import os
import platform
import subprocess
import sys

parser = argparse.ArgumentParser(description='Builds this package')
parser.add_argument('--platform', default=platform.system().lower(), required=False, help=f'Platform to build (defaults to \"{platform.system().lower()}\")')
args = parser.parse_args()

this_dir = os.path.dirname(os.path.realpath(__file__))
cmake_scripts_path = os.path.abspath(os.path.join(this_dir, '../../Scripts/cmake'))

ly_3rdparty_path = os.getenv('LY_3RDPARTY_PATH')

folder_names = { 
    #system-name  cmake generation, cmake build
    'mac'       : ([
        '-G', 'Xcode'
    ], []),
   'mac-arm64' : ([
        '-G', 'Xcode',
        '-DPACKAGE_PLATFORM=mac-arm64'
    ], []),
    'ios'       : ([
        '-G', 'Xcode',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/iOS/Toolchain_ios.cmake',
        '-DPACKAGE_PLATFORM=ios'
    ], [
        '--',
        '-destination generic/platform=iOS'
    ]),
    'linux'     : ([
        '-G', 'Ninja Multi-Config',
        '-DCMAKE_C_COMPILER=clang-6.0', 
        '-DCMAKE_CXX_COMPILER=clang++-6.0'
    ], []),
    'linux-aarch64'     : ([
        '-G', 'Ninja Multi-Config',
        '-DCMAKE_C_COMPILER=clang-12',
        '-DCMAKE_CXX_COMPILER=clang++-12',
        '-DPACKAGE_PLATFORM=linux-aarch64'
    ], []),
    'windows'   : ([
        '-G', 'Visual Studio 15 2017',
        '-Ax64', '-Thost=x64'
    ], []),
    'android'   : ([
        '-G', 'Ninja Multi-Config',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/Android/Toolchain_android.cmake',
        '-DANDROID_ABI=arm64-v8a',
        '-DANDROID_ARM_MODE=arm',
        '-DANDROID_ARM_NEON=FALSE',
        '-DANDROID_NATIVE_API_LEVEL=21',
        f'-DLY_NDK_DIR={ly_3rdparty_path}/android-ndk/r21d',
        '-DPACKAGE_PLATFORM=android'
    ], []) # Android needs to have ninja in the path
}

# intentionally generate a keyerror if its not a good platform:
cmake_generation, cmake_build = folder_names[args.platform]

script_dir = os.path.dirname(os.path.realpath(__file__))
package_name = os.path.basename(script_dir) 
build_dir = os.path.join(script_dir, 'build', args.platform)
os.makedirs(build_dir, exist_ok=True)

# generate
generate_call = ['cmake', '-S.', f'-B{build_dir}', f'-DCMAKE_INSTALL_PREFIX=../../package-system/{package_name}-{args.platform}/']
if cmake_generation:
    generate_call += cmake_generation
result_value = subprocess.run(generate_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build debug
build_call =['cmake', '--build', build_dir, '--config', 'debug', '--target', 'install']
if cmake_build:
    build_call += cmake_build
print(build_call)
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build release
build_call =['cmake', '--build', build_dir, '--config', 'release', '--target', 'install']
if cmake_build:
    build_call += cmake_build
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)
sys.exit(result_value.returncode)
