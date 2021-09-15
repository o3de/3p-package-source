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
cp -f temp/src/LICENSE.txt $TARGET_INSTALL_ROOT/
cp -f temp/src/Source/astcenc.h $INCLUDE_PATH/

BUILD_PATH=temp/build/Source

# copy static lib and executable
cp -f $BUILD_PATH/astcenc-native $BIN_PATH/
cp -f $BUILD_PATH/libastcenc-native-static.a $BIN_PATH/

exit 0
