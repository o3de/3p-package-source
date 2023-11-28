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
cp -r $WORKSPACE/temp/src/GameLift-Cpp-ServerSDK-5.1.1/ $WORKSPACE/src || (echo "Error copying src from $WORKSPACE/temp" && exit 1)

SRC_PATH=$WORKSPACE/src

if [ ! -d ${SRC_PATH} ]
then
    echo "Missing expected source path at ${SRC_PATH}"
    exit 1
fi

# Prepare the build root
BUILD_PATH_ROOT=${WORKSPACE}/aws/build
if [ -d ${BUILD_PATH_ROOT} ]
then
    rm -rf ${BUILD_PATH_ROOT}
fi
mkdir -p ${BUILD_PATH_ROOT}

# Apply an additional linker flag option to resolve 'undefined reference to `dlopen' errors
export LDFLAGS="-Wl,--no-as-needed -ldl"

echo "Preparing BUILD_PATH_ROOT '${BUILD_PATH_ROOT}'"

# Perform a cmake project generation and build
# 
# Arguments:
#   $1 : BUILD path
#   $2 : Build SHARED libs
#   $3 : Build Type
build_package() {

    echo "Generating $1"

    lib_type=$1
    if [ "$lib_type" == "Shared" ]
    then
        build_shared=ON
    else
        build_shared=OFF
    fi
    CMD_CMAKE_GENERATE="\
    cmake -S ${SRC_PATH} -B ${BUILD_PATH_ROOT}/${lib_type} \
          -G \"Unix Makefiles\" \
          -DBUILD_SHARED_LIBS=$build_shared \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_MODULE_PATH=$DOWNLOADED_PACKAGE_FOLDERS"
    echo $CMD_CMAKE_GENERATE
    eval $CMD_CMAKE_GENERATE
    if [ $? -ne 0 ]
    then
        echo "Error generating AWS Gamelift Server SDK build" 
        exit 1
    fi          

    CMD_CMAKE_BUILD="\
    cmake --build ${BUILD_PATH_ROOT}/${lib_type}"
    echo $CMD_CMAKE_BUILD
    eval $CMD_CMAKE_BUILD
    if [ $? -ne 0 ]
    then
        echo "Error building the ${lib_type} configuration for AWS Gamelift Server SDK"
        exit 1
    fi

    if [ ! -d ${BUILD_PATH_ROOT}/${lib_type}/prefix ]
    then
        echo "Error locating built binaries at ${BUILD_PATH_ROOT}/${lib_type}/prefix"
        exit 1
    fi
}

# Build the shared library file
build_package Shared

# Build the static library file
build_package Static

# Prepare the build folder to copy out of the docker image and copy the required build artifacts
mkdir -p ${BUILD_FOLDER}

cp -r ${BUILD_PATH_ROOT}/Static/prefix/include ${BUILD_FOLDER}/
cp -r ${BUILD_PATH_ROOT}/Static/prefix/cmake ${BUILD_FOLDER}/
cp -r ${BUILD_PATH_ROOT}/Static/prefix/lib ${BUILD_FOLDER}/
cp -r ${BUILD_PATH_ROOT}/Shared/prefix/lib ${BUILD_FOLDER}/bin

# Copy the license and notice files
cp $WORKSPACE/temp/src/GameLift-Cpp-ServerSDK-5.1.1/GameLift-SDK-Release-5.1.1/LICENSE_AMAZON_GAMELIFT_SDK.TXT ${BUILD_FOLDER}/
cp $WORKSPACE/temp/src/GameLift-Cpp-ServerSDK-5.1.1/GameLift-SDK-Release-5.1.1/NOTICE_C++_AMAZON_GAMELIFT_SDK.TXT ${BUILD_FOLDER}/

echo "Build Succeeded."

exit 0
