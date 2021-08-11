#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT



BIN_PATH=$TARGET_INSTALL_ROOT/bin

SRC_PATH=temp/src

mkdir -p $BIN_PATH

cp -f $SRC_PATH/README.md $TARGET_INSTALL_ROOT/
cp -f $SRC_PATH/LICENSE_APACHE2.TXT $TARGET_INSTALL_ROOT/
cp -f $SRC_PATH/LICENSE_MIT.TXT $TARGET_INSTALL_ROOT/


mkdir -p $BIN_PATH/Release

cp -f $SRC_PATH/build/release/azslc $BIN_PATH/Release/

exit 0
