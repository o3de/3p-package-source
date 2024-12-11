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

# Arg 4: Addition optional arg
EXTRA_ARG=$4

# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install/ubuntu/ to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

# Prepare the docker file and use the temp folder as the context root
cp docker_build_qt_linux.sh temp/

pushd temp

# Check if we are building the wayland variation
if [ "$EXTRA_ARG" = "wayland" ]
then
    DOCKERFILE=Dockerfile.wayland
    DOCKER_IMAGE_NAME=qt_linux_3p_wayland
else
    DOCKERFILE=Dockerfile
    DOCKER_IMAGE_NAME=qt_linux_3p
fi

# Build the Docker Image
echo "Building the docker build script"
docker build -f ../$DOCKERFILE -t ${DOCKER_IMAGE_NAME}:latest . 
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
