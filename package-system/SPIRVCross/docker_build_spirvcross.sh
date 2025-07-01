#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# Validate the bld path input
BUILD_FOLDER=${DOCKER_BUILD_PATH}
if [ "${BUILD_FOLDER}" == "" ]
then
    echo "Missing required build target folder environment"
    exit 1
elif [ "${BUILD_FOLDER}" == "temp" ]
then
    echo "Build target folder environment cannot be 'temp'"
    exit 1
fi


# Copy the source folder from the read-only $WORKSPACE/temp/src to $WORKSPACE/src
# since the build process will write/modify the source path
echo "Preparing source folder '$WORKSPACE/src'"
cp -r $WORKSPACE/temp/src $WORKSPACE/ || (echo "Error copying src from $WORKSPACE/temp" && exit 1)

SRC_PATH=$WORKSPACE/src

if [ ! -d ${SRC_PATH} ]
then
    echo "Missing expected source path at ${SRC_PATH}"
    exit 1
fi

CMAKE_BUILD_PATH=$WORKSPACE/gen

BUILD_PATH=$WORKSPACE/build
if [ -d ${BUILD_PATH} ]
then
    rm -rf ${BUILD_PATH}
fi



# Run configure 


cmake -S $SRC_PATH -B ${CMAKE_BUILD_PATH}/Debug -G Ninja -DSPIRV_CROSS_CLI=ON \
      -DSPIRV_CROSS_SHARED=OFF \
      -DCMAKE_INSTALL_LIBDIR=${BUILD_FOLDER}/lib/Debug \
      -DCMAKE_INSTALL_BINDIR=${BUILD_FOLDER}/bin/Debug \
      -DCMAKE_BUILD_TYPE=Debug
if [ $? -ne 0 ]
then
    echo "Unable to generate SPIRVCROSS for debug"
    exit 1
fi

cmake --build ${CMAKE_BUILD_PATH}/Debug --target install
if [ $? -ne 0 ]
then
    echo "Failed to build SPIRVCROSS for debug"
    exit 1
fi


cmake -S $SRC_PATH -B ${CMAKE_BUILD_PATH} -G Ninja -DSPIRV_CROSS_CLI=ON \
      -DSPIRV_CROSS_SHARED=OFF \
      -DCMAKE_INSTALL_LIBDIR=${BUILD_FOLDER}/lib/Release \
      -DCMAKE_INSTALL_BINDIR=${BUILD_FOLDER}/bin/Release \
      -DCMAKE_BUILD_TYPE=Release
if [ $? -ne 0 ]
then
    echo "Unable to generate SPIRVCROSS for release"
    exit 1
fi

cmake --build ${CMAKE_BUILD_PATH}/Release --target install
if [ $? -ne 0 ]
then
    echo "Failed to build SPIRVCROSS for release"
    exit 1
fi

exit 1
