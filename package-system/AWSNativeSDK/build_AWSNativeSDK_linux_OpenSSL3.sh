#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# Read the Ubuntu and OpenSSL version from the command line
UBUNTU_VERSION=$1
OPENSSL_MAJOR_VERSION=$2

if [ "$UBUNTU_VERSION" == "2004" ]
then
    echo "Preparing Docker Build based on Ubuntu 20.04 LTS"
elif [ "$UBUNTU_VERSION" == "2204" ]
then
    echo "Preparing Docker Build based on Ubuntu 22.04 LTS"
else
    echo "Unsupported Ubuntu Version: $UBUNTU_VERSION"
    exit 1
endif 

if [ "$OPENSSL_MAJOR_VERSION" == "1" ]
then
    echo "Build based on OpenSSL 1.1.1"
elif [ "$OPENSSL_MAJOR_VERSION" == "3" ]
then
    echo "Build based on OpenSSL 3.0"
else
    echo "Unsupported OpenSSL Major Version: $OPENSSL_MAJOR_VERSION"
    exit 1
endif 

# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

# This script must be ran as root/sudo in order to run Docker
if [ "$(id -u)" != "0" ]
then
    echo "This package script command must be ran with sudo"
    exit 1
fi

# Prepare the docker file and use the temp folder as the context root
cp Dockerfile.ubuntu.${UBUNTU_VERSION} temp/Dockerfile
cp docker_build_aws_sdk.sh temp/


pushd temp


# Build the Docker Image
echo "Building the docker build script"
DOCKER_IMAGE_NAME=aws_native_sdk_ubuntu_${UBUNTU_VERSION}_openssl1
docker build -t ${DOCKER_IMAGE_NAME}:latest . || (echo "Error occurred creating Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)

# Capture the Docker Image ID
IMAGE_ID=$(docker images -q ${DOCKER_IMAGE_NAME}:latest)
if [ -z $IMAGE_ID ]
then
    echo "Error: Cannot find Image ID for ${DOCKER_IMAGE_NAME}"
    exit 1
fi

# Run the Docker Image
echo "Running docker build script"
docker run --tty ${DOCKER_IMAGE_NAME}:latest ./docker_build_aws_sdk.sh $OPENSSL_MAJOR_VERSION || (echo "Error occurred running Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)

echo "Capturing the Container ID"
CONTAINER_ID=$(docker container ls -l -q --filter "ancestor=${DOCKER_IMAGE_NAME}:latest")
if [ -z $CONTAINER_ID ]
then
    echo "Error: Cannot find Container ID for Image ${DOCKER_IMAGE_NAME}"
    exit 1
fi

# Copy the build artifacts from the Docker Container
echo "Copying the built contents from the docker container for image ${DOCKER_IMAGE_NAME}"

rm -rf install
mkdir install

docker cp $CONTAINER_ID:/data/workspace/install/Debug_Static install/ || (echo "Error occurred copying Debug_Static artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)
docker cp $CONTAINER_ID:/data/workspace/install/Debug_Shared install/ || (echo "Error occurred copying Debug_Shared artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)
docker cp $CONTAINER_ID:/data/workspace/install/Release_Static install/ || (echo "Error occurred copying Release_Static artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)
docker cp $CONTAINER_ID:/data/workspace/install/Release_Shared install/ || (echo "Error occurred copying Release_Shared artifacts from Docker image ${DOCKER_IMAGE_NAME}:latest." ; exit 1)

# Clean up the docker image and container
echo "Cleaning up containers"
docker container rm $CONTAINER_ID || (echo "Error occurred trying to clean up container for image ${DOCKER_IMAGE_NAME}")

echo "Cleaning up image"
docker rmi $IMAGE_ID  || (echo "Error occurred trying to clean up image ${DOCKER_IMAGE_NAME}")

popd

exit 0
