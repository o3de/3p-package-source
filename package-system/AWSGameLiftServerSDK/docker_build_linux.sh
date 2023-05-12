#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


WORKSPACE_DIR=/data/workspace
SDK_SRC_SUBPATH=${1:-.}
SRC_PATH=${WORKSPACE_DIR}/src/${SDK_SRC_SUBPATH}

if [ ! -d ${SRC_PATH} ]
then
    echo "Unable to locate source path at ${SRC_PATH}"
    exit 1
fi

# Perform a cmake project generation and build
# 
# Arguments:
#   $1 : BUILD path
#   $2 : Build SHARED libs
#   $3 : Build Type
build_package() {

    echo "Generating $1"

    cmake -G Ninja -S ${SRC_PATH} -B $1 -DBUILD_SHARED_LIBS=$2 -DCMAKE_BUILD_TYPE=Release
    if [ $? -ne 0 ]
    then
        echo "Error generating AWS Gamelift Server SDK for $1" 
        exit 1
    fi
    cmake --build $1
    if [ $? -ne 0 ]
    then
        echo "Error building AWS Gamelift Server SDK for $1" 
        exit 1
    fi

    if [ ! -d $1/prefix ]
    then
        echo "Error installing AWS Gamelift Server SDK for $1" 
        exit 1
    fi
}

BUILD_PATH_ROOT=${WORKSPACE_DIR}/build

#### Build Static ####
echo "Building Static/Release ..."
build_package ${BUILD_PATH_ROOT}/build_static OFF

#### Build Shared ####
echo "Building Shared/Release..."
build_package ${BUILD_PATH_ROOT}/build_shared ON

echo "Build Succeeded."

exit 0
