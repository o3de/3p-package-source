#! /bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_base_command="cmake -S temp/src -B temp/src  -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH=\"$DOWNLOADED_PACKAGE_FOLDERS\" -DASSIMP_BUILD_ZLIB=OFF"

# On Mac, load the toolchain file to make sure
# the build matches compatibility with other Mac libraries
if [ "$(uname)" == "Darwin" ];
then
    echo "Loading Darwin toolchain file"
    cmake_base_command+=" -DCMAKE_TOOLCHAIN_FILE=$PWD/../../Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"
fi

cmake_no_shared_libs="$cmake_base_command -DBUILD_SHARED_LIBS=OFF -DASSIMP_BUILD_ASSIMP_TOOLS=ON"
cmake_shared_libs="$cmake_base_command -DBUILD_SHARED_LIBS=ON -DASSIMP_BUILD_ASSIMP_TOOLS=ON"

echo "Running first cmake command:"
echo "$cmake_no_shared_libs"

eval "$cmake_no_shared_libs temp/src/CMakeLists.txt" || exit 1
cmake --build temp/src --config release || exit 1

echo "Running second cmake command:"
echo "$cmake_shared_libs"

eval "$cmake_shared_libs temp/src/CMakeLists.txt" || exit 1
cmake --build temp/src --config release || exit 1

if [ "$(uname)" == "Darwin" ];
then
    # Printing the minimum OS version here can save some time debugging.
    echo "Min OS version:"
    otool -l temp/src/bin/assimp | grep -i minos
fi
