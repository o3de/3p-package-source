#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT



cp -r temp/build/include $TARGET_INSTALL_ROOT
cp -r temp/build/bin $TARGET_INSTALL_ROOT

if [ -f temp/build/LICENSE.sse2neon ]
then
    cp temp/build/LICENSE.sse2neon $TARGET_INSTALL_ROOT/
fi

exit 0 
