#! /bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# -Wno-error, turning off warnings as errors because Assimp uses TinyUSDZ for USD support which has compiler warnings.
cmake_base_command="cmake -S temp/src -B temp/src temp/src/CMakeLists.txt -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH=\"$DOWNLOADED_PACKAGE_FOLDERS\" -DASSIMP_BUILD_ZLIB=OFF -DASSIMP_BUILD_ASSIMP_TOOLS=OFF -DASSIMP_HUNTER_ENABLED=OFF -DASSIMP_BUILD_USD_IMPORTER=ON -DASSIMP_WARNINGS_AS_ERRORS=OFF -DASSIMP_BUILD_TESTS=ON -DCMAKE_CXX_FLAGS=\"-Wno-unused-const-variable -Wno-error\""

# On Mac, load the toolchain file to make sure
# the build matches compatibility with other Mac libraries
if [ "$(uname)" = "Darwin" ];
then
    echo "Loading Darwin toolchain file"
    cmake_base_command+=" -DCMAKE_TOOLCHAIN_FILE=$PWD/../../Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"
fi

cmake_no_shared_libs="$cmake_base_command -DBUILD_SHARED_LIBS=OFF"
cmake_shared_libs="$cmake_base_command -DBUILD_SHARED_LIBS=ON"

echo "Running first cmake command:"
echo "$cmake_no_shared_libs"

eval "$cmake_no_shared_libs" || exit 1
cmake --build temp/src --config release || exit 1

echo "Running second cmake command:"
echo "$cmake_shared_libs"

eval "$cmake_shared_libs" || exit 1
cmake --build temp/src --config release || exit 1
