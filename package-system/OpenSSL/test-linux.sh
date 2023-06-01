#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# The expected OPENSSL_VERSION_TEXT (Refer to build_config.json for the current version being built)
EXPECTED_OPENSSL_VERSION="OpenSSL 1.1.1t  7 Feb 2023"

# The sha256 hash of the above OPENSSL_VERSION_TEXT (Refer to build_config.json for the current version being built)
EXPECTED_OPENSSL_VERSION_SHA256="92b72d8487f5580f88413f85e7053daf63da2653"


# Reset any existing test folder
rm -rf temp/build_test
mkdir temp/build_test

# Make sure we are running on the target architecture
TARGET_ARCH=${1:-$(uname -m)}

CURRENT_HOST_ARCH=$(uname -m)
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
    echo "Warning: Tests for packages on target ${TARGET_ARCH} can only be run on ${TARGET_ARCH}. Skipping tests."
    exit 0
fi

# Build the test program
cmake -S test -B temp/build_test -DCMAKE_MODULE_PATH="$PACKAGE_ROOT" -DCMAKE_BUILD_TYPE=Release
if [ $? -ne 0 ]
then
    echo "Error generating the test project"
    exit 1
fi

cmake --build temp/build_test
if [ $? -ne 0 ]
then
    echo "Error building the test project"
    exit 1
fi

echo Executing test_OpenSSL \"${EXPECTED_OPENSSL_VERSION}\" ${EXPECTED_OPENSSL_VERSION_SHA256}
./temp/build_test/test_OpenSSL "${EXPECTED_OPENSSL_VERSION}" ${EXPECTED_OPENSSL_VERSION_SHA256}
if [ $? -ne 0 ]
then
    echo "Package test failed"
    exit 1
fi

echo "Package test passed"

exit 0
