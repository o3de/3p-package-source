#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# The expected SDF Version
EXPECTED_SDF_VERSION="13.5.0"

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

CMD="./temp/build_test/test_sdformat ${EXPECTED_SDF_VERSION}"
echo "Executing $CMD"
$CMD
if [ $? -ne 0 ]
then
    echo "Package test failed"
    exit 1
fi

echo "Package test passed"

exit 0
