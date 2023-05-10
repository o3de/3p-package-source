#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

LIB_NAME=python3

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Use the host architecture if not supplied
TARGET_ARCH=${1:-$(uname -m)}

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

# Setup the docker arguments for the target architecture
if [ "${TARGET_ARCH}" = "x86_64" ]
then
    echo "Processing Docker for x86_64"
    TARGET_DOCKER_FILE=Dockerfile.x86_64
    TARGET_DOCKER_PLATFORM_ARG=linux/amd64
    DOCKER_IMAGE_NAME=${LIB_NAME}_linux_3p
elif [ "${TARGET_ARCH}" = "aarch64" ] 
then
    echo "Processing Docker for aarch64"
    TARGET_DOCKER_FILE=Dockerfile.aarch64
    TARGET_DOCKER_PLATFORM_ARG=linux/arm64/v8
    DOCKER_IMAGE_NAME=${LIB_NAME}_linux_aarch64_3p
else
    echo "Unsupported architecture ${TARGET_ARCH}"
    exit 1
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

DOCKER_BUILD_SCRIPT=docker_build_linux.sh

if [ ! -f $DOCKER_BUILD_SCRIPT ]
then
    echo "Invalid docker build script ${DOCKER_BUILD_SCRIPT}"
    exit 1
fi

# Prepare the docker file and use the temp folder as the context root
cp -f ${DOCKER_BUILD_SCRIPT} temp/

pushd temp

# Build the Docker Image
echo "Building the docker build script for ${DOCKER_IMAGE_NAME}"
docker build --build-arg DOCKER_BUILD_SCRIPT=$DOCKER_BUILD_SCRIPT -f ../${TARGET_DOCKER_FILE} -t ${DOCKER_IMAGE_NAME}:latest . 
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
echo "Running build script in the docker image"
docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} --tty ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT}
if [ $? -ne 0 ]
then
    echo Failed to build from docker image ${DOCKER_IMAGE_NAME}:latest
    echo "To log into and troubleshoot the docker container, run the following command:"
    echo ""
    echo "docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} -it --tty ${DOCKER_IMAGE_NAME}:latest"
    echo ""
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

mkdir -p build
docker cp $CONTAINER_ID:/data/workspace/package/python/. build  
if [ $? -ne 0 ]
then
    echo "Error occurred copying build artifacts from Docker container ($CONTAINER_ID)" 
    exit 1
fi

# Clean up the docker image and container
echo "Cleaning up container"
docker container rm $CONTAINER_ID || (echo "Warning: unable to clean up container for image ${DOCKER_IMAGE_NAME}")

echo "Cleaning up image"
docker rmi --force $IMAGE_ID  || (echo "Warning: unable to clean up image ${DOCKER_IMAGE_NAME}")

popd

exit 0
