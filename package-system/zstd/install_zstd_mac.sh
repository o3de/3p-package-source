#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

SRC_DIR=$TEMP_FOLDER/src
INSTALL_DIR=$TEMP_FOLDER/install

cp -rvf $INSTALL_DIR/* $TARGET_INSTALL_ROOT/
cp -v $SRC_DIR/LICENSE $TARGET_INSTALL_ROOT/
cp -v $SRC_DIR/COPYING $TARGET_INSTALL_ROOT/

exit 0
