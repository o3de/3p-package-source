#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

CPU_ARCHITECTURE=$(lscpu | grep Architecture | awk '{print $2}')
if [ "$CPU_ARCHITECTURE" = "x86_64" ]
then
    # On x86/x64 platforms, O3DE requires requirest SSE 4.1
    cmake -S src -B build -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DISA_SSE41=ON 

elif [ "$CPU_ARCHITECTURE" = "aarch64" ]
then
    # On aarch64 architectures, O3DE requires NEON simd support
    cmake -S src -B build -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DISA_NEON=ON 
fi

if [ $? -ne 0 ]
then
    echo "Failed to generate build for astc encoder for Linux"
    exit 1
fi

cmake --build build
if [ $? -ne 0 ]
then
    echo "Failed to build astc encoder for Linux"
    exit 1
fi

