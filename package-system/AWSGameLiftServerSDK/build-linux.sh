#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This script will utilize Docker to build on either AMD64 or AARCH64 architectures. The script will 
# also build on both Ubuntu 20.04 (focal) and Ubuntu 22.04 (jammy) systems because of the dependencies
# on OpenSSL 1.1.1 and Open 3.0 respectively

DOCKER_IMAGE_NAME_BASE=aws_gamelift_server_sdk
DOCKER_BUILD_SCRIPT=docker_build_linux.sh

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Get the path within the source tarball to the root of the source folder for the build
SDK_SRC_SUBPATH=${1:-.}

# Use the host architecture if not supplied
TARGET_ARCH=${2:-$(uname -m)}

# Prepare the target install path
INSTALL_PACKAGE_PATH=${TEMP_FOLDER}/install/

# If the host and target architecture does not match, make sure the necessary cross compilation packages are installed
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
    echo "Checking cross compiling requirements."
    for package_check in docker-ce qemu binfmt-support qemu-user-static
    do
        echo "Checking package $package_check"
        dpkg -s $package_check > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            echo ""
            echo "Missing package $package_check. Make sure to install it with your local package manager." 
            echo ""
            exit 1
        fi
    done

    # Only cross compilation of an ARM64 image on an x86_64 host is supported
    if [ "${TARGET_ARCH}" = "aarch64" ]
    then
        # Make sure qemu-aarch64 is installed properly
        QEMU_AARCH_COUNT=$(update-binfmts --display | grep qemu-aarch64 | wc -l)
        if [ $QEMU_AARCH_COUNT -eq 0 ]
        then
            echo ""
            echo "QEMU aarch64 binary format not registered."
            echo "Run the following command to register"
            echo ""
            echo "sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
            echo ""
            exit 1
        fi
        echo ""
        echo "Cross compiling aarch64 on an amd64 machine validated."
        echo ""
    fi
else
    echo "Building ${TARGET_ARCH} natively."
fi

# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install/ubuntu/ to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"


# Setup the docker arguments 
if [ "${TARGET_ARCH}" = "x86_64" ]
then
    echo "Processing Docker for amd64"

    DOCKER_INPUT_ARCHITECTURE=amd64
    TARGET_DOCKER_PLATFORM_ARG=linux/amd64
    DOCKER_BUILD_ARG=1

elif [ "${TARGET_ARCH}" = "aarch64" ] 
then
    echo "Processing Docker for aarch64"

    DOCKER_INPUT_ARCHITECTURE=arm64v8
    TARGET_DOCKER_PLATFORM_ARG=linux/arm64/v8
    DOCKER_BUILD_ARG=3
else
    echo "Unsupported architecture ${TARGET_ARCH}"
    exit 1
fi

# Prepare to build on both Ubuntu 20.04 and Ubuntu 22.04 based docker images

mkdir -p ${TEMP_FOLDER}
cp -f ${DOCKER_BUILD_SCRIPT} ${TEMP_FOLDER}/

# Args
# $1 : Ubuntu version
# $2 : Include
# $3 : Docker run platform

function execute_docker() {

    # Determine the openssl version based on the ubuntu version (20.04/OpenSSL 1.1.1.x vs 22.04/OpenSSL 3.x)
    if [ $1 = "20.04" ]
    then
        echo "Preparing for OpenSSL 1.1.1.x version"
        BIN_SUBFOLDER_NAME=openssl-1
    elif [ $1 = "22.04" ]
    then
        echo "Preparing for OpenSSL 3.x version"
        BIN_SUBFOLDER_NAME=openssl-3
    else
        echo "Unsupported base build image ubuntu version ${1}"
        exit 1
    fi

    # Build the Docker Image 
    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME_BASE}_focal_${DOCKER_INPUT_ARCHITECTURE}_3p

    echo "Building the docker build script for ${DOCKER_IMAGE_NAME_BASE} on ${DOCKER_INPUT_ARCHITECTURE} for Ubuntu $1"
    echo ""
    echo docker build --build-arg INPUT_DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT} \
                 --build-arg INPUT_ARCHITECTURE=${DOCKER_INPUT_ARCHITECTURE} \
                 --build-arg INPUT_IMAGE=ubuntu:${1} \
                 -f Dockerfile -t ${DOCKER_IMAGE_NAME}:latest temp 
    docker build --build-arg INPUT_DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT} \
                 --build-arg INPUT_ARCHITECTURE=${DOCKER_INPUT_ARCHITECTURE} \
                 --build-arg INPUT_IMAGE=ubuntu:${1} \
                 -f Dockerfile -t ${DOCKER_IMAGE_NAME}:latest temp 
    if [ $? -ne 0 ]
    then
        echo "Error occurred creating Docker image ${DOCKER_IMAGE_NAME}:latest." 
        exit 1
    fi

    # Run the build script in the docker image
    echo "Running build script in the docker image ${DOCKER_IMAGE_NAME}"
    echo ""
    echo docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} \
                   -it --tty \
                   ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT} ${SDK_SRC_SUBPATH}
    docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} \
               --tty \
               ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT} ${SDK_SRC_SUBPATH}
    if [ $? -ne 0 ]
    then
        echo Failed to build from docker image ${DOCKER_IMAGE_NAME}:latest
        echo "To log into and troubleshoot the docker container, run the following command:"
        echo ""
        echo "docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} -it --tty ${DOCKER_IMAGE_NAME}:latest"
        echo ""
        exit 1
    fi

    echo "Build Complete"

    echo "docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} -it --tty ${DOCKER_IMAGE_NAME}:latest"

    # Copy the build artifacts from the docker image

    # Capture the Docker Image ID
    IMAGE_ID=$(docker images -q ${DOCKER_IMAGE_NAME}:latest)
    if [ -z $IMAGE_ID ]
    then
        echo "Error: Cannot find Image ID for ${DOCKER_IMAGE_NAME}"
        exit 1
    fi

    # Capture the container ID
    echo "Capturing the Container ID"
    CONTAINER_ID=$(docker container ls -l -q --filter "ancestor=${DOCKER_IMAGE_NAME}:latest")
    if [ -z $CONTAINER_ID ]
    then
        echo "Error: Cannot find Container ID for Image ${DOCKER_IMAGE_NAME}"
        exit 1
    fi

    DOCKER_BUILD_ROOT=/data/workspace/build/

    if [ ! -f ${INSTALL_PACKAGE_PATH}/include ]
    then
        docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_static_release/prefix/include  ${INSTALL_PACKAGE_PATH}/
    fi
    if [ ! -f ${INSTALL_PACKAGE_PATH}/cmake ]
    then
        docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_static_release/prefix/cmake  ${INSTALL_PACKAGE_PATH}/
    fi

    docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_static_release/prefix/lib  ${INSTALL_PACKAGE_PATH}/lib/Release/${BIN_SUBFOLDER_NAME}
    docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_static_debug/prefix/lib  ${INSTALL_PACKAGE_PATH}/lib/Debug/${BIN_SUBFOLDER_NAME}
    docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_shared_release/prefix/lib  ${INSTALL_PACKAGE_PATH}/bin/Release/${BIN_SUBFOLDER_NAME}
    docker cp $CONTAINER_ID:${DOCKER_BUILD_ROOT}/build_shared_debug/prefix/lib  ${INSTALL_PACKAGE_PATH}/bin/Debug/${BIN_SUBFOLDER_NAME}
}

rm -rf ${INSTALL_PACKAGE_PATH}

mkdir -p ${INSTALL_PACKAGE_PATH}
mkdir -p ${INSTALL_PACKAGE_PATH}/lib/Debug
mkdir -p ${INSTALL_PACKAGE_PATH}/lib/Release
mkdir -p ${INSTALL_PACKAGE_PATH}/bin/Debug
mkdir -p ${INSTALL_PACKAGE_PATH}/bin/Release

# Build for Ubuntu 20.04
execute_docker 20.04 

# Build for Ubuntu 22.04
execute_docker 22.04 

echo "Build successful"

exit 0

