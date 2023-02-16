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

# Build the Docker Image
echo "Building the docker build script"
DOCKER_IMAGE_NAME=qt_linux_3p
docker build --build-arg TIFF_PACKAGE_DIR=${TIFF_FOLDER_NAME} --build-arg ZLIB_PACKAGE_DIR=${ZLIB_FOLDER_NAME} -f ../Dockerfile -t ${DOCKER_IMAGE_NAME}:latest . || (echo "Error occurred creating Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)

# Capture the Docker Image ID
IMAGE_ID=$(docker images -q ${DOCKER_IMAGE_NAME}:latest)
if [ -z $IMAGE_ID ]
then
    echo "Error: Cannot find Image ID for ${DOCKER_IMAGE_NAME}"
    exit 1
fi


# Run the Docker Image
echo "Running docker build script"
docker run -v $TEMP_FOLDER/src:/data/workspace/src -v $TEMP_FOLDER/$TIFF_FOLDER_NAME:/data/workspace/$TIFF_FOLDER_NAME -v $TEMP_FOLDER/$ZLIB_FOLDER_NAME:/data/workspace/$ZLIB_FOLDER_NAME -v $TARGET_INSTALL_ROOT:/data/workspace/qt --tty ${DOCKER_IMAGE_NAME}:latest ./docker_build_qt_linux.sh || (echo "Error occurred running Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)

echo Qt installed successfully!

exit 0

