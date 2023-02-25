#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

TEMP_FOLDER=/data/workspace
SRC_DIR=$TEMP_FOLDER/src
BUILD_DIR=$TEMP_FOLDER/build
TMP_RELEASE_DIR=$BUILD_DIR/install/lib/release

python3 $SRC_DIR/scripts/update_deps.py --dir $TEMP_FOLDER/external --arch x64 --config release
if [ $? -ne 0 ]
then
    echo "Error configuring build environment"
    exit 1
fi

cmake -G "Ninja Multi-Config" -C $TEMP_FOLDER/external/helper.cmake -S $SRC_DIR -B $BUILD_DIR
if [ $? -ne 0 ]
then
    echo "Error generating cmake project"
    exit 1
fi

cmake --build $BUILD_DIR --config Release --target clean
if [ $? -ne 0 ]
then
    echo "Error cleaning project"
    exit 1
fi

cmake --build $BUILD_DIR --config Release
if [ $? -ne 0 ]
then
    echo "Error building project"
    exit 1
fi

mkdir -p $TMP_RELEASE_DIR
mv $BUILD_DIR/layers/Release/* $TMP_RELEASE_DIR

exit 0
