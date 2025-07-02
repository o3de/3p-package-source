#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

# Arg 1: The tiff package name
TIFF_FOLDER_NAME=$1

# Arg 2: The zlib package name
ZLIB_FOLDER_NAME=$2

# Arg 3: The openssl package name
OPENSSL_FOLDER_NAME=$3

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Use the host architecture if not supplied
TARGET_ARCH=${4:-$(uname -m)}

#
# Make sure docker is installed
#
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install/ubuntu/ to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

# 
# Check the target architecture and determine if the necessary cross compilation requirements are met
#

# If the host and target architecture does not match, make sure the necessary cross compilation packages are installed
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
    echo "Checking cross compiling requirements."
    for package_check in docker-ce binfmt-support qemu-user-static
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

# Setup the docker arguments 
if [ "${TARGET_ARCH}" = "x86_64" ]
then
    echo "Processing Docker for amd64"

    DOCKER_INPUT_ARCHITECTURE=amd64
    TARGET_DOCKER_PLATFORM_ARG=linux/amd64

elif [ "${TARGET_ARCH}" = "aarch64" ] 
then
    echo "Processing Docker for aarch64"

    DOCKER_INPUT_ARCHITECTURE=arm64v8
    TARGET_DOCKER_PLATFORM_ARG=linux/arm64/v8

else
    echo "Unsupported architecture ${TARGET_ARCH}"
    exit 1
fi

# 

# Prepare the docker file and use the temp folder as the context root
cp docker_build_qt_linux.sh temp/

DOCKERFILE=Dockerfile
DOCKER_IMAGE_NAME_BASE=qt
DOCKER_BUILD_SCRIPT=docker_build_qt_linux.sh
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME_BASE}_${DOCKER_INPUT_ARCHITECTURE}_3p
UBUNTU_BASE=20.04


echo "Executing docker-based build from the following arguments"
echo "    DOCKER_IMAGE_NAME_BASE=${DOCKER_IMAGE_NAME_BASE}"
echo "    UBUNTU_BASE=${UBUNTU_BASE}"
echo "    DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT}"
echo "    TARGET_BUILD_FOLDER=${TARGET_BUILD_FOLDER}"
echo "    TARGET_ARCH=${TARGET_ARCH}"
echo "    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}"
echo ""


# Build the Docker Image 
echo "Building the docker build script for ${DOCKER_IMAGE_NAME_BASE} on ${DOCKER_INPUT_ARCHITECTURE} for Ubuntu $1"
echo ""
CMD_DOCKER_BUILD="\
docker build --build-arg INPUT_DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT}\
 --build-arg INPUT_ARCHITECTURE=${DOCKER_INPUT_ARCHITECTURE}\
 --build-arg INPUT_IMAGE=ubuntu:${UBUNTU_BASE}\
 --platform ${TARGET_DOCKER_PLATFORM_ARG}\
 -f Dockerfile -t ${DOCKER_IMAGE_NAME}:latest temp"
 echo ${CMD_DOCKER_BUILD}
 eval ${CMD_DOCKER_BUILD}
if [ $? -ne 0 ]
then
    echo "Error occurred creating Docker image ${DOCKER_IMAGE_NAME}:latest." 
    exit 1
fi


# Capture the Docker Image ID
IMAGE_ID=$(docker images -q ${DOCKER_IMAGE_NAME}:latest)
if [ -z $IMAGE_ID ]
then
    echo "Error: Cannot find Image ID for ${DOCKER_IMAGE_NAME}"
    exit 1
fi

# Run the Docker Image
echo "Running docker build script"
docker run -v $TEMP_FOLDER/src:/data/workspace/src -v $TEMP_FOLDER/$TIFF_FOLDER_NAME:/data/workspace/o3de_tiff -v $TEMP_FOLDER/$ZLIB_FOLDER_NAME:/data/workspace/o3de_zlib -v $TEMP_FOLDER/$OPENSSL_FOLDER_NAME:/data/workspace/o3de_openssl --tty ${DOCKER_IMAGE_NAME}:latest ./docker_build_qt_linux.sh
if [ $? -ne 0 ]
then
    echo "Error occurred running Docker image ${DOCKER_IMAGE_NAME}:latest." 
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


# Copy the build artifacts from the Docker Container
echo "Copying the built contents from the docker container for image ${DOCKER_IMAGE_NAME}"
docker cp --follow-link $CONTAINER_ID:/data/workspace/qt/. $TARGET_INSTALL_ROOT
if [ $? -ne 0 ]
then
    echo "Error occurred copying build artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest."
    exit 1
fi

# Clean up the docker image and container
echo "Cleaning up container"
docker container rm $CONTAINER_ID
if [ $? -ne 0 ]
then
    echo "Warning: Unable to clean up container for image ${DOCKER_IMAGE_NAME}"
fi

echo "Cleaning up image"
docker rmi --force $IMAGE_ID
if [ $? -ne 0 ]
then
    echo "Warning: Unable to clean up image ${DOCKER_IMAGE_NAME}"
fi

popd

exit 0
