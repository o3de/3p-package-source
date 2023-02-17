#! /bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


cd /data/workspace

echo "Using custom zlib library at /data/workspace/${ZLIB_LIB_PATH}"

cmake -S /data/workspace/src -B /data/workspace/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH="/data/workspace/${ZLIB_LIB_PATH}" -DASSIMP_BUILD_ZLIB=OFF -DBUILD_SHARED_LIBS=ON -DASSIMP_BUILD_ASSIMP_TOOLS=ON || (echo "Failed generating cmake project for assimp/shared." ; exit 1)

cmake --build /data/workspace/build || (echo "Failed building cmake project for assimp/shared." ; exit 1)

cmake -S /data/workspace/src -B /data/workspace/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH="/data/workspace/${ZLIB_LIB_PATH}" -DASSIMP_BUILD_ZLIB=OFF -DBUILD_SHARED_LIBS=OFF -DASSIMP_BUILD_ASSIMP_TOOLS=ON || (echo "Failed generating cmake project for assimp/static." ; exit 1)

cmake --build /data/workspace/build || (echo "Failed building cmake project for assimp/shared." ; exit 1)

mkdir -p /data/workspace/build/port/

cp -R src/port/PyAssimp /data/workspace/build/port/

echo "Build Succeeded"

exit 0