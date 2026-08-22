#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

echo "TARGET_INSTALL_ROOT=$TARGET_INSTALL_ROOT"
echo "PACKAGE_ROOT=$PACKAGE_ROOT"
echo "TEMP_FOLDER=$TEMP_FOLDER"

OPENSSL_SRC=$TEMP_FOLDER/src
BUILD_FOLDER=$TEMP_FOLDER/build

echo "Preparing build from ${OPENSSL_SRC}"

cd $OPENSSL_SRC
echo "Configuring OpenSSL"
CMD="./config no-shared no-asm --prefix=${TARGET_INSTALL_ROOT} --openssldir=${BUILD_FOLDER}/openssl"
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

echo "Installing OpenSSL to ${TARGET_INSTALL_ROOT}"
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
