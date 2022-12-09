#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT


# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"


# The ISPCTextureCompressor relies on the ispc compiler (v1.16.1) from https://github.com/ispc/ispc.git
# This will be cloned from https://github.com/ispc/ispc.git (branch v1.16.1) and built with the supplied 
# ubuntu 20.04 docker script (docker/ubuntu/20.04/cpu_ispc_build/Dockerfile) and the resulting docker
# image will be used to provide the build environment as well as the required ispc tool needed to 
# build the ISPCTextureCompressor
echo ""
echo "--------------- Cloning ispc v1.16.1 from git ---------------"
echo ""
rm -rf temp/ispc
git clone https://github.com/ispc/ispc.git --branch v1.16.1 --depth 1 temp/ispc || (echo "Error occurred cloning ispc from https://github.com/ispc/ispc.git" ; exit 1)

DOCKER_ISPC_ENV_IMAGE_NAME=ispc_cpu_env
docker build -t ${DOCKER_ISPC_ENV_IMAGE_NAME}:latest ispc/docker/ubuntu/20.04/cpu_ispc_build/ -f ispc/docker/ubuntu/20.04/cpu_ispc_build/Dockerfile || \
        (echo "Error building docker image ${DOCKER_ISPC_ENV_IMAGE_NAME}" ; exit 1)


# Use the temp folder as the docker context path e
DOCKER_ISPC_BUILD_IMAGE_NAME=ispc_text_comp

cp Dockerfile temp/Dockerfile

# Build the image from the base ispc docker to prepare
docker build -t ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest temp

# Run the build command in docker through run. 
# note: The build is not done as part of the image build so that the build output is part of the container
# and we will copy from the container the build artifact
docker run -it ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest "cd /data/workspace/src && make -f Makefile.linux"

# Copy the build artifact from the container into a working folder
rm -rf temp/docker_output
mkdir -p temp/docker_output
echo "Capturing the Container ID for ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest"
CONTAINER_ID=$(docker container ls -l -q --filter "ancestor=${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest")
echo "CI=${CONTAINER_ID}"
if [ -z $CONTAINER_ID ]
then
    echo "Error: Cannot find Container ID for Image ${DOCKER_ISPC_BUILD_IMAGE_NAME}"
    exit 1
fi
docker cp $CONTAINER_ID:/data/workspace/src/build/libispc_texcomp.so temp/docker_output/ || (echo "Error occurred copying libispc_texcomp.so from Docker image ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest." ; exit 1)

exit 0





















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
