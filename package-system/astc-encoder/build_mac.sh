#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

export CXX=clang++

# using -DISA_AVX2=ON enables build for x86_64
# using -DISA_NEON=ON enables build for arm64 
# to build arm64 requires xcode 12.3 and macos 11
# Note: on x86/x64 platforms, O3DE requires a minimum of SSE 4.1, so we do request this.

cmake -S temp/src -B temp/build -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DISA_SSE41=ON \
    -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/Mac/Toolchain_mac.cmake \
    || exit $?

cmake --build temp/build --parallel || exit $?

