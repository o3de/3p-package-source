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
import shutil

parser = argparse.ArgumentParser(description='Builds this package')
parser.add_argument('--platform', default=platform.system().lower(), required=False, help=f'Platform to build (defaults to \"{platform.system().lower()}\")')
args = parser.parse_args()

this_dir = os.path.dirname(os.path.realpath(__file__))
cmake_scripts_path = os.path.abspath(os.path.join(this_dir, '../../Scripts/cmake'))

android_ndk_dir = os.getenv('ANDROID_NDK_HOME')

folder_names = { 
    #system-name  cmake generation, cmake build
    'mac'       : ([
        '-G', 'Xcode'
    ], 
    [], 
    ['osx/darwin-clang']),
    'ios'       : ([
        '-G', 'Xcode',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/iOS/Toolchain_ios.cmake',
        '-DPACKAGE_PLATFORM=ios'
    ], [
        '--',
        '-destination generic/platform=iOS'
    ], ['osx/ios-clang']),
    'linux'     : ([
        '-G', 'Ninja Multi-Config',
        '-DCMAKE_C_COMPILER=clang', 
        '-DCMAKE_CXX_COMPILER=clang++'
    ], 
    [], 
    ['clang']),
    'windows'   : ([
        '-G', 'Visual Studio 16 2019',
        '-Ax64', '-Thost=x64'
    ], 
    [],
    ['win64/vc140']),
    'android'   : ([
        '-G', 'Ninja Multi-Config',
        f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/Android/Toolchain_android.cmake',
        '-DANDROID_ABI=arm64-v8a',
        '-DANDROID_ARM_MODE=arm',
        '-DANDROID_ARM_NEON=FALSE',
        '-DANDROID_NATIVE_API_LEVEL=21',
        f'-DLY_NDK_DIR={android_ndk_dir}',
        '-DPACKAGE_PLATFORM=android'
    ], 
    [],
    ['android-ndk-r21']) # Android needs to have ninja in the path
}

# intentionally generate a keyerror if its not a good platform:
cmake_generation, cmake_build, build_dst = folder_names[args.platform]

script_dir = os.path.dirname(os.path.realpath(__file__))
package_name = os.path.basename(script_dir) 
build_dir = os.path.join(script_dir, 'build', args.platform)
os.makedirs(build_dir, exist_ok=True)

# cmake file for building
cmake_file = open(os.path.join(script_dir, 'CMakeLists.txt'), 'w')
cmake_file.write('''
    cmake_minimum_required(VERSION 3.17)
    project(libcityhash)
    SET(INC_LIBCITYHASH
        city.h
        citycrc.h)
    SET(SRC_LIBCITYHASH
        city.cc)
    include_directories("${CMAKE_SOURCE_DIR}")
    LIST(APPEND SRC_LIBCITYHASH ${INC_LIBCITYHASH})
    ADD_LIBRARY ( cityhashlib STATIC ${SRC_LIBCITYHASH} )
    TARGET_LINK_LIBRARIES (cityhashlib)
    set_target_properties(cityhashlib
        PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib/debug/"
            ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib/release/"
            LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib/debug/"
            LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib/release/"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin/debug/"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin/release/"
    )
    install(TARGETS cityhashlib
            PUBLIC_HEADER
                DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            LIBRARY
                DESTINATION ${CMAKE_BINARY_DIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
            RUNTIME
                DESTINATION ${CMAKE_BINARY_DIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
            ARCHIVE
                DESTINATION ${CMAKE_BINARY_DIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
    )
''')
cmake_file.close()


# generate
generate_call = ['cmake', '-S.', f'-B{build_dir}', f'-DCMAKE_INSTALL_PREFIX=../../package-system/{package_name}-{args.platform}/']
if cmake_generation:
    generate_call += cmake_generation
result_value = subprocess.run(generate_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build debug
build_call =['cmake', '--build', build_dir, '--config', 'Debug', '--target', 'install']
if cmake_build:
    build_call += cmake_build
print(build_call)
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)
if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# build release
build_call =['cmake', '--build', build_dir, '--config', 'Release', '--target', 'install']
if cmake_build:
    build_call += cmake_build
result_value = subprocess.run(build_call, shell=False, cwd=script_dir)

os.remove(os.path.join(script_dir, 'CMakeLists.txt'))

# installation directory
dest_dir = os.path.join(script_dir, '..', f'cityhash-{args.platform}')
os.makedirs(dest_dir, exist_ok=True)
os.makedirs(os.path.join(dest_dir, 'cityhash', 'src'), exist_ok=True)

# copy binary, cmake, and license files
shutil.copytree(src=os.path.join(build_dir, 'lib'), dst=os.path.join(dest_dir, 'cityhash', 'build', build_dst[0]), dirs_exist_ok=True)
shutil.copyfile(src=os.path.join(script_dir, 'README'), dst=os.path.join(dest_dir, 'cityhash', 'README'))
shutil.copyfile(src=os.path.join(script_dir, 'COPYING'), dst=os.path.join(dest_dir, 'cityhash', 'COPYING'))
shutil.copyfile(src=os.path.join(script_dir, 'Findcityhash.cmake'), dst=os.path.join(dest_dir, 'Findcityhash.cmake'))
shutil.copyfile(src=os.path.join(script_dir, 'citycrc.h'), dst=os.path.join(dest_dir, 'cityhash', 'src', 'citycrc.h'), )
shutil.copyfile(src=os.path.join(script_dir, 'city.h'), dst=os.path.join(dest_dir, 'cityhash', 'src', 'city.h'))
shutil.copyfile(src=os.path.join(script_dir, 'city.cc'), dst=os.path.join(dest_dir, 'cityhash', 'src', 'city.cc'))
shutil.copyfile(src=os.path.join(script_dir, 'city-test.cc'), dst=os.path.join(dest_dir, 'cityhash', 'src', 'city-test.h'))

# package info json
package_json_file = open(os.path.join(dest_dir, 'PackageInfo.json'), 'w')
package_json_file.write('''{
    "PackageName" : "cityhash-1.1-multiplatform",
    "URL"         : "http://code.google.com/p/cityhash/",
    "License"     : "MIT",
    "LicenseFile" : "cityhash/COPYING"
}''')
package_json_file.close()

# cleanup 
shutil.rmtree(os.path.join(script_dir, 'build'))

sys.exit(result_value.returncode)
