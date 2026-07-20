#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# The expected OPENSSL_VERSION_TEXT and its sha1sum (Refer to build_package_image.py for the current version being built)
EXPECTED_OPENSSL_VERSION="OpenSSL 3.6.3 9 Jun 2026"
EXPECTED_OPENSSL_VERSION_SHA256="5559d73213aff02be756d7cb30491444c9c21473"

rm -rf temp/build_test
mkdir temp/build_test

cmake -S test -B temp/build_test -G Xcode \
 -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/Mac/Toolchain_mac.cmake \
 -DCMAKE_MODULE_PATH="$PACKAGE_ROOT" || exit 1

cmake --build temp/build_test --parallel --config Release || exit 1

temp/build_test/Release/test_OpenSSL "${EXPECTED_OPENSSL_VERSION}" "${EXPECTED_OPENSSL_VERSION_SHA256}" || exit 1

exit 0
