#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

set -euo pipefail

SRC_PATH=$TEMP_FOLDER/src
BLD_PATH=$TEMP_FOLDER/build

pushd $SRC_PATH

INSTALL_DIR=$BLD_PATH

if [ "$(uname -m)"="aarch64" ]
then
    echo "Configuring cityhash for ARM64"
    ./configure --build=arm --prefix=$INSTALL_DIR
else 
    echo "Configuring cityhash for x86_64"
    ./configure --prefix=$INSTALL_DIR
fi

if [ $? -ne 0 ]
then
    echo "Failed configuring cityhash"
    exit 1
fi

make all
if [ $? -ne 0 ]
then
    echo "Failed building cityhash"
    exit 1
fi

make check
if [ $? -ne 0 ]
then
    echo "Failed testing cityhash"
    exit 1
fi

make install
if [ $? -ne 0 ]
then
    echo "Failed installing cityhash"
    exit 1
fi

echo "cityhash built successfully"
exit 0
