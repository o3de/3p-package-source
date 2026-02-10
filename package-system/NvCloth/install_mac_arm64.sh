#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

set -euo pipefail

echo $TARGET_INSTALL_ROOT
echo $TEMP_FOLDER

SRC_PATH=$TEMP_FOLDER/src

SRC_LIB_PATH=$SRC_PATH/NvCloth/build/mac/NvCloth/lib/osx64-cmake
echo "Copying built libraries from $SRC_LIB_PATH/NvCloth/lib/ to target install root"
mkdir -p $TARGET_INSTALL_ROOT/NvCloth/lib
cp -rv $SRC_LIB_PATH/* $TARGET_INSTALL_ROOT/NvCloth/lib/

echo "Copying include files"
mkdir -p $TARGET_INSTALL_ROOT/NvCloth/include
cp -rv $SRC_PATH/NvCloth/include/* $TARGET_INSTALL_ROOT/NvCloth/include/
mkdir -p $TARGET_INSTALL_ROOT/NvCloth/extensions/include
cp -rv $SRC_PATH/NvCloth/extensions/include/* $TARGET_INSTALL_ROOT/NvCloth/extensions/include/
mkdir -p $TARGET_INSTALL_ROOT/PxShared/include
cp -rv $SRC_PATH/PxShared/include/* $TARGET_INSTALL_ROOT/PxShared/include/

echo "Copying license and readme files"
cp -rv $SRC_PATH/README.md $TARGET_INSTALL_ROOT/README.md
cp -rv $SRC_PATH/NvCloth/license.txt $TARGET_INSTALL_ROOT/NvCloth/license.txt
cp -rv $SRC_PATH/PxShared/license.txt $TARGET_INSTALL_ROOT/PxShared/license.txt

echo "NvCloth installation complete"

exit 0
