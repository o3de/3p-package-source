#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT


WORKSPACE=/data/workspace

SRC_DIR=$WORKSPACE/src

BUILD_DIR=$SRC_DIR/build

cd $SRC_DIR
if [ $? -ne 0 ]
then
    echo "Invalid path ${SRC_DIR}"
    exit 1
fi

make -f Makefile.linux
if [ $? -ne 0 ]
then
    echo "Build failed"
    exit 1
fi

exit 0
