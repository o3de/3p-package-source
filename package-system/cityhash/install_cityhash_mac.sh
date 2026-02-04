#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

set -euo pipefail

echo $TARGET_INSTALL_ROOT
echo $TEMP_FOLDER

BUILD_PATH=$TEMP_FOLDER/build

cp -rvf $BUILD_PATH/* $TARGET_INSTALL_ROOT

exit 0