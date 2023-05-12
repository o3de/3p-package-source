#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install/ubuntu/ to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

DOCKER_BUILD_SCRIPT=docker_build_googlebenchmark_linux.sh
DOCKER_IMAGE_NAME=google_benchmark_linux_3p

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

docker build --build-arg DOCKER_BUILD_SCRIPT=$DOCKER_BUILD_SCRIPT -f ../Dockerfile -t ${DOCKER_IMAGE_NAME}:latest . 
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
echo docker run -v $TEMP_FOLDER/src:/data/workspace/src --tty ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT}
docker run -v $TEMP_FOLDER/src:/data/workspace/src --tty ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT}
if [ $? -ne 0 ]
then
    echo Failed to build from docker image ${DOCKER_IMAGE_NAME}:latest
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
docker cp $CONTAINER_ID:/data/workspace/package/. build  
if [ $? -ne 0 ]
then
    echo "Error occurred copying build artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest." 
    exit 1
fi


# Clean up the docker image and container
echo "Cleaning up container"
docker container rm $CONTAINER_ID || (echo "Warning: unable to clean up container for image ${DOCKER_IMAGE_NAME}")

echo "Cleaning up image"
docker rmi --force $IMAGE_ID  || (echo "Warning: unable to clean up image ${DOCKER_IMAGE_NAME}")

popd

exit 0

