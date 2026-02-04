#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

echo "Configuring zstd"
cd src

SRC_DIR=$TEMP_FOLDER/src
BLD_DIR=$TEMP_FOLDER/build
INSTALL_DIR=$TEMP_FOLDER/install

cmake -S $SRC_DIR/build/cmake -B $BLD_DIR -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DZSTD_BUILD_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR
if [ $? -ne 0 ]
then
    echo "Failed configuring zstd"
    exit 1
fi

cmake --build ${BLD_DIR} --config Release --target install 
if [ $? -ne 0 ]
then
    echo "Failed building zstd"
    exit 1
fi

echo "Finished building zstd"

 exit 0
