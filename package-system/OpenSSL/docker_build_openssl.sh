#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# Validate the bld path input
BUILD_FOLDER=${DOCKER_BUILD_PATH}
if [ "${BUILD_FOLDER}" == "" ]
then
    echo "Missing required build target folder environment"
    exit 1
elif [ "${BUILD_FOLDER}" == "temp" ]
then
    echo "Build target folder environment cannot be 'temp'"
    exit 1
fi

# Copy the source folder from the read-only $WORKSPACE/temp/src to $WORKSPACE/src
# since the build process will write/modify the source path

echo "Preparing source folder '$WORKSPACE/src'"
cp -r $WORKSPACE/temp/src $WORKSPACE/ || (echo "Error copying src from $WORKSPACE/tempo" && exit 1)

cd $WORKSPACE/src
echo "Configuring OpenSSL"
echo ./config no-shared no-asm --prefix=${BUILD_FOLDER} --openssldir=/etc/ssl LDFLAGS='-Wl,-rpath=\$$ORIGIN' 
./config no-shared no-asm --prefix=${BUILD_FOLDER} --openssldir=/etc/ssl LDFLAGS='-Wl,-rpath=\$$ORIGIN' 


echo "Building OpenSSL"
echo make
make || (echo "Error building OpenSSL" && exit 1)

echo "Running OpenSSL tests"
echo make test
make test || (echo "OpenSSL failed tests" && exit 1)

echo "Installing OpenSSL to ${BUILD_FOLDER}"
echo make install
make install || (echo "Error install OpenSSL" && exit 1)


echo "Build complete. Build artifacts installed to ${BUILD_FOLDER}"

exit 0
