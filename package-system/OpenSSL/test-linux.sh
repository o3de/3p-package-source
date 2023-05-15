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

if [ $# -ne 3 ]
then
    echo "Invalid/incomplete arguments"
    echo "Usage: ${0} [architecture] [OpenSSL version string] [SHA256 hash of the the OpenSSL version string]"
    exit 1
fi

# Make sure we are running on the target architecture
TARGET_ARCH=$1
CURRENT_HOST_ARCH=$(uname -m)
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
    echo "Warning: Tests for packages on target ${TARGET_ARCH} can only be run on ${TARGET_ARCH}. Skipping tests."
    exit 0
fi

# Required Argument 2: The expected OPENSSL_VERSION_TEXT
EXPECTED_OPENSSL_VERSION=$2

# Required Argument 3: The sha256 hash of the above OPENSSL_VERSION_TEXT 
EXPECTED_OPENSSL_VERSION_SHA256=$3

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
