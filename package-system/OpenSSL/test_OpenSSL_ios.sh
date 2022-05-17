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

cmake -S test -B temp/build_test -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/iOS/Toolchain_ios.cmake \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=false \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=false \
    -DCMAKE_MODULE_PATH="$PACKAGE_ROOT" || exit 1

cmake --build temp/build_test --parallel --config Release || exit 1

# we can't actually run it on ios, that'd require an emulator or device as well as
# cert / signing - but we can at least make sure it compiles and links!

exit 0
