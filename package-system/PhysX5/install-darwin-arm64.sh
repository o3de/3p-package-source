#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

set -euo pipefail

echo $TARGET_INSTALL_ROOT
echo $TEMP_FOLDER

SRC_PATH=$TEMP_FOLDER/src/physx

# Copy include files
SRC_INCLUDE_PATH=$SRC_PATH/install/mac-arm64/PhysX/include
DEST_INCLUDE_PATH=$TARGET_INSTALL_ROOT/physx/include
mkdir -p $DEST_INCLUDE_PATH
echo Copying $SRC_INCLUDE_PATH to $DEST_INCLUDE_PATH
cp -vrf $SRC_INCLUDE_PATH/* $DEST_INCLUDE_PATH/

# Copy static library files for each configuration
# Note that the built libraries are in mac.x86_64 even though we built for mac-arm64
SRC_PHYSX_BIN_PATH_BASE=$SRC_PATH/bin/mac.x86_64
DEST_PHYSX_BIN_PATH_BASE=$TARGET_INSTALL_ROOT/physx/bin/static
configs=("release" "profile" "checked" "debug")
for config in "${configs[@]}"; do
    SRC_PHYSX_BIN_PATH=$SRC_PHYSX_BIN_PATH_BASE/$config
    libfiles=("PhysXVehicle2" "PhysXExtensions" "PhysXFoundation" "PhysXCooking" "PhysXCharacterKinematic" "PhysX" "PhysXPvdSDK" "PhysXVehicle" "PhysXCommon")
    for libfile in "${libfiles[@]}"; do
        SRC_FILE_PATH=$SRC_PHYSX_BIN_PATH/lib${libfile}_static_64.a
        DEST_FILE_PATH=$DEST_PHYSX_BIN_PATH_BASE/$config/lib${libfile}_static_64.a
        echo Copying $SRC_FILE_PATH to $DEST_FILE_PATH
        mkdir -p $(dirname $DEST_FILE_PATH)
        cp -f $SRC_FILE_PATH $DEST_FILE_PATH
    done
done    

# Copy fastxml include files
echo "Copying fastxml"
SRC_FASTXML_INCLUDE_PATH=$SRC_PATH/install/mac-arm64/PhysX/source/fastxml
DEST_FASTXML_INCLUDE_PATH=$TARGET_INSTALL_ROOT/physx/source/fastxml
mkdir -p $DEST_FASTXML_INCLUDE_PATH
cp -rf $SRC_FASTXML_INCLUDE_PATH/* $DEST_FASTXML_INCLUDE_PATH/

# Copy README and version files
echo "Copying README.txt and version.txt"
cp -f $TEMP_FOLDER/src/README.md $TARGET_INSTALL_ROOT/
cp -f $SRC_PATH/README.md $TARGET_INSTALL_ROOT/physx/
cp -f $SRC_PATH/version.txt $TARGET_INSTALL_ROOT/physx/

echo "PhysX5 installation complete"

exit 0
