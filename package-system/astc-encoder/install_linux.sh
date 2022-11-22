#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

BIN_PATH=$TARGET_INSTALL_ROOT/bin
INCLUDE_PATH=$TARGET_INSTALL_ROOT/include

mkdir -p $INCLUDE_PATH
mkdir -p $BIN_PATH

# copy LICENSE.txt and header file
cp -f temp/src/LICENSE.txt $TARGET_INSTALL_ROOT/ || exit $?
cp -f temp/src/Source/astcenc.h $INCLUDE_PATH/ || exit $?

BUILD_PATH=temp/build/Source

# copy static lib and executable
CPU_ARCHITECTURE=$(lscpu | grep Architecture | awk '{print $2}')
if [ "$CPU_ARCHITECTURE" = "x86_64" ]
then
    cp -f $BUILD_PATH/astcenc-sse4.1 $BIN_PATH/ || exit $?
    cp -f $BUILD_PATH/libastcenc-sse4.1-static.a $BIN_PATH/ || exit $?
elif [ "$CPU_ARCHITECTURE" = "aarch64" ]
then
    cp -f $BUILD_PATH/astcenc-native $BIN_PATH/ || exit $?
    cp -f $BUILD_PATH/libastcenc-native-static.a $BIN_PATH/ || exit $?

fi

exit 0
