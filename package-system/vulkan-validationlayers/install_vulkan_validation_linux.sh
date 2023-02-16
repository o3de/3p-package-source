#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

BUILD_DIR=$TEMP_FOLDER/build
TMP_RELEASE_DIR=$BUILD_DIR/install/lib/release

OUT_RELEASE=$TARGET_INSTALL_ROOT/lib/release

mkdir -p $OUT_RELEASE

cp $TMP_RELEASE_DIR/* $OUT_RELEASE
if [ $? -ne 0 ]; then
    echo Unable to copy $TMP_RELEASE_DIR to $OUT_RELEASE
    exit 1
fi

exit 0