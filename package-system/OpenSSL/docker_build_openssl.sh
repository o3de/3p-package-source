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
cp -r $WORKSPACE/temp/src $WORKSPACE/ 
if [ $? -ne 0 ]
then
    echo "Error copying src from $WORKSPACE/tempo"
    exit 1
fi

cd $WORKSPACE/src
echo "Configuring OpenSSL"
CMD="./config no-shared no-asm --prefix=${BUILD_FOLDER} --openssldir=/etc/ssl LDFLAGS='-Wl,-rpath=\$$ORIGIN'"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring OpenSSL"
    exit 1
fi

echo "Building OpenSSL"
CMD="make"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building OpenSSL"
    exit 1
fi

echo "Running OpenSSL tests"
CMD="make test"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "OpenSSL failed tests"
    exit 1
fi

echo "Installing OpenSSL to ${BUILD_FOLDER}"
CMD="make install"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "OpenSSL failed to install"
    exit 1
fi

echo "Build complete. Build artifacts installed to ${BUILD_FOLDER}"

exit 0
