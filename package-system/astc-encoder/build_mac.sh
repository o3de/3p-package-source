#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

cmake -S temp/src -B temp/build -G Xcode -DCMAKE_BUILD_TYPE=Release -DSKIP_INSTALL_FILES=YES -DISA_NEON=ON

if [ $? -ne 0 ]; then
    echo "Error generating build"
    exit 1
fi

cmake --build temp/build --config Release -j 8
if [ $? -ne 0 ]; then
    echo "Error building"
    exit 1
fi

