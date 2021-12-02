#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Note: on x86/x64 platforms, O3DE requires a minimum of SSE 4.1, so we do request this.
cmake -S temp/src -B temp/build -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DISA_SSE41=ON \
    || exit $?

cmake --build temp/build -j 8 || exit $?
