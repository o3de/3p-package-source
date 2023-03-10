#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Build both debug and release variants
build_configs=(Debug Release)
for build_config in "${build_configs[@]}"
do
    echo 
    cmake -S src -B build/${build_config} -G Ninja -DCMAKE_BUILD_TYPE=${build_config} -DCMAKE_CXX_STANDARD=17 -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DHAVE_STD_REGEX=TRUE -DBENCHMARK_ENABLE_TESTING=OFF -DCMAKE_INSTALL_PREFIX=/data/workspace/install/${build_config}

    if [ $? -ne 0 ]
    then
        echo "Error configuring cmake for google benchmark (${build_config})"
        exit 1
    fi

    cmake --build build/${build_config}
    if [ $? -ne 0 ]
    then
        echo "Failed to build google benchmark for Linux (${build_config})"
        exit 1
    fi

    cmake --install build/${build_config}
    if [ $? -ne 0 ]
    then
        echo "Failed to package google benchmark for Linux (${build_config})"
        exit 1
    fi

done

# Create a combined package with debug and release libs
mkdir -p package
cp -r install/Release/include package/
cp -r install/Release/share package/

mkdir -p package/lib/Debug
cp -r install/Debug/lib/* package/lib/Debug/

mkdir -p package/lib/Release
cp -r install/Release/lib/* package/lib/Release/


exit 0


