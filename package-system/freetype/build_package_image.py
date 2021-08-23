#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
    ], [], 'debug', 'release'),
    'ios'       : ([
        '-G', 'Xcode',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/iOS/Toolchain_ios.cmake',
        '-DPACKAGE_PLATFORM=ios'
    ], [
        '--',
        '-destination generic/platform=iOS'
    ], 'debug', 'release'),
    'linux'     : ([
        '-G', 'Ninja Multi-Config',
        '-DCMAKE_C_COMPILER=clang-6.0', 
        '-DCMAKE_CXX_COMPILER=clang++-6.0'
    ], [], 'Debug', 'Release'),
    'windows'   : ([
        '-G', 'Visual Studio 16 2019',
        '-Ax64', '-Thost=x64'
    ], [], 'debug', 'release'),
    'android'   : ([
        '-G', 'Ninja Multi-Config',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/Android/Toolchain_android.cmake',
        '-DANDROID_ABI=arm64-v8a',
        '-DANDROID_ARM_MODE=arm',
        '-DANDROID_ARM_NEON=FALSE',
        '-DANDROID_NATIVE_API_LEVEL=21',
        f'-DLY_NDK_DIR={ly_3rdparty_path}/android-ndk/r21d',
        '-DPACKAGE_PLATFORM=android'
    ], [], 'debug', 'release') # Android needs to have ninja in the path
}

# intentionally generate a keyerror if its not a good platform:
cmake_generation, cmake_build, debug_build_name, release_build_name = folder_names[args.platform]

script_dir = os.path.dirname(os.path.realpath(__file__))
package_name = os.path.basename(script_dir) 
build_dir = os.path.join(script_dir, 'temp/build', args.platform)
os.makedirs(build_dir, exist_ok=True)

# generate
generate_call = ['cmake', '-Stemp/src', f'-B{build_dir}', f'-DCMAKE_INSTALL_PREFIX=../{package_name}-{args.platform}/{package_name}/', '-DBUILD_SHARED_LIBS=false']
if cmake_generation:
    generate_call += cmake_generation
result_value = subprocess.run(generate_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build debug
build_call =['cmake', '--build', build_dir, '--config', debug_build_name, '--target', 'install']
if cmake_build:
    build_call += cmake_build
print(build_call)
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build release
build_call =['cmake', '--build', build_dir, '--config', release_build_name, '--target', 'install']
if cmake_build:
    build_call += cmake_build
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)
sys.exit(result_value.returncode)
