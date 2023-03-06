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

cp docker_build_linux.sh temp/

# The ISPCTextureCompressor relies on the ispc compiler (v1.16.1) from https://github.com/ispc/ispc.git
# This will be cloned from https://github.com/ispc/ispc.git (branch v1.16.1) and built with the supplied 
# ubuntu 20.04 docker script (docker/ubuntu/20.04/cpu_ispc_build/Dockerfile) and the resulting docker
# image will be used to provide the build environment as well as the required ispc tool needed to 
# build the ISPCTextureCompressor
echo "Cloning ispc v1.16.1 from git"

rm -rf temp/ispc

git clone https://github.com/ispc/ispc.git --branch v1.16.1 --depth 1 temp/ispc 
if [ $? -ne 0 ]
then
    echo "Error occurred cloning ispc from https://github.com/ispc/ispc.git"
    exit 1
fi

# If this is aarch64, we need a special patch
if [ "$(uname -m)" = "aarch64" ]
then
    echo "Applying aarch64 patch"
    git -C temp/ispc apply ../ispc_linux_patch_arm64.txt
fi

DOCKER_ISPC_ENV_IMAGE_NAME=ispc_cpu_env
docker build --build-arg SHA=v1.16.1 -t ${DOCKER_ISPC_ENV_IMAGE_NAME}:latest temp/ispc/docker/ubuntu/20.04/cpu_ispc_build/ -f temp/ispc/docker/ubuntu/20.04/cpu_ispc_build/Dockerfile
if [ $? -ne 0 ]
then
    echo "Error building docker image ${DOCKER_ISPC_ENV_IMAGE_NAME}"
    exit 1
fi

# Capture the Docker Image ID for ${DOCKER_ISPC_ENV_IMAGE_NAME}
DOCKER_ISPC_ENV_IMAGE_ID=$(docker images -q ${DOCKER_ISPC_ENV_IMAGE_NAME}:latest)
if [ -z $DOCKER_ISPC_ENV_IMAGE_ID ]
then
    echo "Error: Cannot find Image ID for ${DOCKER_ISPC_ENV_IMAGE_NAME}"
    exit 1
fi

# Using the ispc compiler docker as a base, prepare the docker image to build the ISPCTextureComp library
DOCKER_ISPC_BUILD_IMAGE_NAME=ispc_text_comp

# Build the image from the base ispc docker to prepare
docker build -t ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest -f Dockerfile.linux temp
if [ $? -ne 0 ]
then
    echo "Error building docker image ${DOCKER_ISPC_BUILD_IMAGE_NAME}"
    exit 1
fi

# Capture the Docker Image ID for ${DOCKER_ISPC_BUILD_IMAGE_NAME}
DOCKER_ISPC_BUILD_IMAGE_ID=$(docker images -q ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest)
if [ -z $DOCKER_ISPC_BUILD_IMAGE_ID ]
then
    echo "Error: Cannot find Image ID for ${DOCKER_ISPC_BUILD_IMAGE_NAME}"
    exit 1
fi

# Run the build command in docker through run. 
docker run -it ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest /data/workspace/docker_build_linux.sh
if [ $? -ne 0 ]
then
    echo "Error building ISPCTextureComp library"
    exit 1
fi

echo "Capturing the Container ID for ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest"
DOCKER_ISPC_BUILD_CONTAINER_ID=$(docker container ls -l -q --filter "ancestor=${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest")
echo "CI=${DOCKER_ISPC_BUILD_CONTAINER_ID}"
if [ -z $DOCKER_ISPC_BUILD_CONTAINER_ID ]
then
    echo "Error: Cannot find Container ID for Image ${DOCKER_ISPC_BUILD_IMAGE_NAME}"
    exit 1
fi

# Copy the build artifact to a temp folder for the install script
rm -rf temp/docker_output
mkdir -p temp/docker_output
docker cp $DOCKER_ISPC_BUILD_CONTAINER_ID:/data/workspace/src/build/libispc_texcomp.so temp/docker_output/
if [ $? -ne 0 ]
then
    echo "Error occurred copying libispc_texcomp.so from Docker image ${DOCKER_ISPC_BUILD_IMAGE_NAME}:latest."
    exit 1
fi


# Clean up the docker image and container
echo "Cleaning up containers"
docker container prune -f

echo "Cleaning up image"
docker rmi --force $DOCKER_ISPC_ENV_IMAGE_ID  || (echo "Warning: unable to clean up image ${DOCKER_ISPC_ENV_IMAGE_NAME}")
if [ $? -ne 0 ]
then
    echo "Warning: unable to clean up image ${DOCKER_ISPC_ENV_IMAGE_NAME}"
fi
docker rmi --force $DOCKER_ISPC_BUILD_IMAGE_ID  || (echo "Warning: unable to clean up image ${DOCKER_ISPC_BUILD_IMAGE_NAME}")
if [ $? -ne 0 ]
then
    echo "Warning: unable to clean up image ${DOCKER_ISPC_BUILD_IMAGE_NAME}"
fi

exit 0

