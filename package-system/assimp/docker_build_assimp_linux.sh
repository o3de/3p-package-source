#! /bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


cd /data/workspace/src

# Since we are mapping in a git repo from outside of the docker, git will report that the folder has a 'dubious' owner
# which will cause code in the CMakeLists.txt that extracts the commit hash to fail, and thus fail the revision
# unit test. To prevent this, mark the forlder 'src' as a safe directory for git
git config --global --add safe.directory /data/workspace/src

GIT_HASH=$(git rev-parse --short=8 HEAD)
echo "Working with Assimp commit hash ${GIT_HASH}"

echo "Using custom zlib (shared) library at /data/workspace/${ZLIB_LIB_PATH}"


cmake -S . -B /data/workspace/build -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH="/data/workspace/${ZLIB_LIB_PATH}" -DASSIMP_BUILD_ZLIB=OFF -DBUILD_SHARED_LIBS=ON -DASSIMP_BUILD_ASSIMP_TOOLS=ON 
if [ $? -ne 0 ]
then
    echo "Failed generating cmake project for assimp/shared."
    exit 1
fi


cmake --build /data/workspace/build 
if [ $? -ne 0 ]
then
    echo "Failed building cmake project for assimp/shared."
    exit 1
fi


echo "Using custom zlib (static) library at /data/workspace/${ZLIB_LIB_PATH}"

cmake -S . -B /data/workspace/build -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_MODULE_PATH="/data/workspace/${ZLIB_LIB_PATH}" -DASSIMP_BUILD_ZLIB=OFF -DBUILD_SHARED_LIBS=OFF -DASSIMP_BUILD_ASSIMP_TOOLS=ON 
if [ $? -ne 0 ]
then
    echo "Failed generating cmake project for assimp/static."
    exit 1
fi


cmake --build /data/workspace/build
if [ $? -ne 0 ]
then
    echo "Failed building cmake project for assimp/shared." 
    exit 1
fi


mkdir -p /data/workspace/build/port/
cp -R /data/workspace/src/port/PyAssimp /data/workspace/build/port/

echo "Running unit test"

cd ..
mkdir -p test_out
cd test_out

../build/bin/unit 
if [ $? -eq 0 ]; then
    echo "Unit Tests Passed"
    exit 0
else
    echo "Unit Tests Failed"
    exit 1
fi

exit 0

