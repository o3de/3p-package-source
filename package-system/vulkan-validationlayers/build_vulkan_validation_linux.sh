#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT


SRC_DIR=$TEMP_FOLDER/src
BUILD_DIR=$TEMP_FOLDER/build
TMP_RELEASE_DIR=$BUILD_DIR/install/lib/release

$PYTHON_BINARY $SRC_DIR/scripts/update_deps.py --dir $SRC_DIR/external --arch x64 --config release
cmake -G "Ninja Multi-Config" -C $SRC_DIR/external/helper.cmake -S $SRC_DIR -B $BUILD_DIR
cmake --build $BUILD_DIR --config Release --target clean
cmake --build $BUILD_DIR --config Release

mkdir -p $TMP_RELEASE_DIR
mv $BUILD_DIR/layers/Release/* $TMP_RELEASE_DIR

exit 0