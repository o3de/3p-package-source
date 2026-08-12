#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# in this case, we really just want to make sure the package is found successfully

rm -rf temp/build_test
mkdir temp/build_test

cmake -S test/find-using-config -B temp/build_test/find-using-config \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_PREFIX_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_BUILD_TYPE=Release || exit 1

cmake -S test/find-using-module -B temp/build_test/find-using-module \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_PREFIX_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_BUILD_TYPE=Release || exit 1

cmake --build temp/build_test/find-using-config --config Release || exit 1
cmake --build temp/build_test/find-using-module --config Release || exit 1

./temp/build_test/find-using-module/yaml-cpp-test || exit 1
./temp/build_test/find-using-config/yaml-cpp-test || exit 1

exit 0
