#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Build both debug and release variants
build_configs=(Debug Release)


cmake -S src -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS="-fPIC -O2" -DCMAKE_CXX_STANDARD=17 -DCMAKE_INSTALL_PREFIX=/data/workspace/package
if [ $? -ne 0 ]
then
    echo "Error configuring cmake for squish-ccr (${build_config})"
    exit 1
fi

cmake --build build/${build_config}
if [ $? -ne 0 ]
then
    echo "Failed to build squish-ccr for Linux (${build_config})"
    exit 1
fi

cmake --install build/${build_config}
if [ $? -ne 0 ]
then
    echo "Failed to package squish-ccr for Linux (${build_config})"
    exit 1
fi

exit 0
