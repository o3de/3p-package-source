#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake -S temp/src -B temp/build -G Xcode \
    -DBUILD_SHARED_LIBS=OFF ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS" ^
    -DASSIMP_BUILD_ZLIB=OFF ^
    temp/src/CMakeLists.txt || exit 1
cmake --build temp/src --config release || exit 1
cmake --build temp/src --config debug || exit 1

cmake -S temp/src -B temp/build -G Xcode \
    -DBUILD_SHARED_LIBS=OFF ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS" ^
    -DASSIMP_BUILD_ZLIB=OFF ^
    temp/src/CMakeLists.txt || exit 1
cmake --build temp/src --config release || exit 1
cmake --build temp/src --config debug || exit 1

