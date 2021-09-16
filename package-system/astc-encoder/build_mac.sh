#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

export CXX=clang++

# using -DISA_AVX2=ON enables build for x86_64
# using -DISA_NEON=ON enables build for arm64 
# to build arm64 requires xcode 12.3 and macos 11 which is not supported on my Mac
# we have to disable cpu specific options for an universal build

cmake -S temp/src -B temp/build -G "Unix Makefiles" 

if [ $? -ne 0 ]; then
    echo "Error generating build"
    exit 1
fi

cmake --build temp/build --config Release -j 8
if [ $? -ne 0 ]; then
    echo "Error building"
    exit 1
fi

