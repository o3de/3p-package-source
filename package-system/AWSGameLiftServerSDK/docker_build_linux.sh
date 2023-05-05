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

# Fix for unit test failure on ARM64 from the package caused by a different default initialization behavior on an enum 
FILE_TO_PATCH=${SRC_PATH}/gamelift-server-sdk/include/aws/gamelift/internal/model/request/UpdatePlayerSessionCreationPolicyRequest.h
if [ -f ${FILE_TO_PATCH} ]
then
    echo "Found 'UpdatePlayerSessionCreationPolicyRequest.h', patching if needed"
    sed -i 's/WebSocketPlayerSessionCreationPolicy m_playerSessionCreationPolicy;/WebSocketPlayerSessionCreationPolicy m_playerSessionCreationPolicy = WebSocketPlayerSessionCreationPolicy::NOT_SET;/g' ${FILE_TO_PATCH}
else
    echo "UpdatePlayerSessionCreationPolicyRequest.h not found, skipping patching"
fi

# Perform a cmake project generation and build
# 
# Arguments:
#   $1 : BUILD path
#   $2 : Build SHARED libs
#   $3 : Build Type
build_package() {

    echo "Generating $1"

    cmake -G Ninja -S ${SRC_PATH} -B $1 -DBUILD_SHARED_LIBS=$2 -DCMAKE_BUILD_TYPE=$3
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

#### Build Static/Debug ####"
echo "Building Static/Debug..."
build_package ${BUILD_PATH_ROOT}/build_static_debug OFF Debug

#### Build Static/Release ####
echo "Building Static/Release ..."
build_package ${BUILD_PATH_ROOT}/build_static_release OFF Release

#### Build Shared/Debug ####
echo "Building Shared/Debug..."
build_package ${BUILD_PATH_ROOT}/build_shared_debug ON Debug

#### Build Shared/Release ####
echo "Building Shared/Release..."
build_package ${BUILD_PATH_ROOT}/build_shared_release ON Release

echo "Build Succeeded."

exit 0

