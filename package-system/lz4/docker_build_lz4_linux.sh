#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Build only release variants
lib_name="lz4"
build_configs=(Release)

cmake_src_dir="src/build/cmake"
# Configure using the Ninja Multi-Config generator
cmake -S ${cmake_src_dir} -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS="-fPIC -O2" -DCMAKE_CXX_STANDARD=17 -DCMAKE_INSTALL_PREFIX=/data/workspace/package -DBUILD_SHARED_LIBS=OFF -DLZ4_BUILD_CLI=OFF -DLZ4_BUILD_LEGACY_LZ4C=OFF
if [ $? -ne 0 ]; then
    echo "Error configuring cmake for ${lib_name}"
    exit 1
fi

for config in "${build_configs[@]}"
do
    cmake --build build --target install
    if [ $? -ne 0 ]; then
        echo "Failed to build and package ${lib_name} for Linux (${config})"
        exit 1
    fi
done

exit 0
