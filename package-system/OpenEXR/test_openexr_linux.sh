#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

rm -rf temp/build_test
mkdir temp/build_test

cmake -S test -B temp/build_test -G Ninja \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_BUILD_TYPE=Release || exit 1
cmake --build temp/build_test --parallel || exit 1
temp/build_test/test_openexr || exit 1

cmake -S test -B temp/build_test -G Ninja \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" \
    -DCMAKE_BUILD_TYPE=Debug || exit 1
cmake --build temp/build_test --parallel || exit 1
temp/build_test/test_openexr || exit 1

# extra - ensute multi-config compiles too
rm -rf temp/build_test
cmake -S test -B temp/build_test -G "Ninja Multi-Config" \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS;$PACKAGE_ROOT" || exit 1
cmake --build temp/build_test --parallel --config Debug || exit 1
cmake --build temp/build_test --parallel --config Release || exit 1
cmake --build temp/build_test --parallel --config RelWithDebInfo || exit 1


exit 0
