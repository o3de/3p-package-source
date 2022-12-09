#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

BIN_PATH=$TARGET_INSTALL_ROOT/bin
INCLUDE_PATH=$TARGET_INSTALL_ROOT/include/ISPC

mkdir -p $INCLUDE_PATH
mkdir -p $BIN_PATH

cp -f temp/src/license.txt $TARGET_INSTALL_ROOT/ || exit $?
cp -f temp/src/ispc_texcomp/ispc_texcomp.h $INCLUDE_PATH/ || exit $?
cp -f temp/docker_output/libispc_texcomp.so $BIN_PATH/ || exit $?

