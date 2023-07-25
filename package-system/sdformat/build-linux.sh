#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This script will utilize Docker to build on either AMD64 or AARCH64 architectures. The script will
# also build on both Ubuntu based docker images

DOCKER_BUILD_SCRIPT=docker_build_sdformat.sh
TARGET_INSTALL_FOLDER=install

#
# Collect the required arguments for this ubuntu docker-base build script
#

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Use the host architecture if not supplied
TARGET_ARCH=${1:-$(uname -m)}

# Get the base docker image name
DOCKER_IMAGE_NAME_BASE=${2:-sdformat13}

# Get the ubuntu base version (20.04|22.04)
# Default to Ubuntu 20.04
UBUNTU_BASE=${3:-20.04}

echo "Executing docker-based build from the following arguments"
echo "    DOCKER_IMAGE_NAME_BASE=${DOCKER_IMAGE_NAME_BASE}"
echo "    UBUNTU_BASE=${UBUNTU_BASE}"
echo "    DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT}"
echo "    TARGET_INSTALL_FOLDER=${TARGET_INSTALL_FOLDER}"
echo "    TARGET_ARCH=${TARGET_ARCH}"
echo ""


#
# Make sure docker is installed
#
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

#
# Check the target architecture and determine if the necessary cross compilation requirements are met
#

# If the host and target architecture does not match, make sure the necessary cross compilation packages are installed
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
    # Get the name of command to check that docker is installed
    CHECK_DOCKER_FOR_OS_CALLBACK=$4
    if [ "${CHECK_DOCKER_FOR_OS_CALLBACK}" == "" ]; then
        echo "Missing argument 1: Docker callback function name. This is needed to validate that docker is installed"
        exit 1
    fi

    # Triggers a OS specific callback for checking docker requirements
    # This should be set for the host specific build script (archlinux, ubuntu, etc...)
    ${CHECK_DOCKER_FOR_OS_CALLBACK}
    # If the return code is non-0 then exit the script
    # The callback function would output any error messages
    return_code=$?
    if [ $return_code -ne 0 ]; then
        exit $return_code
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
# Prepare the docker base context based on ${TEMP_FOLDER}
mkdir -p ${TEMP_FOLDER}
cp -f ${DOCKER_BUILD_SCRIPT} ${TEMP_FOLDER}/

echo "Building on ubuntu public.ecr.aws/ubuntu/ubuntu:${UBUNTU_BASE}"

# Build the Docker Image
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME_BASE}_${DOCKER_INPUT_ARCHITECTURE}_3p
echo DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}

echo -e "Building the docker build script for ${DOCKER_IMAGE_NAME_BASE} on ${DOCKER_INPUT_ARCHITECTURE} for Ubuntu $1\n"
CMD_DOCKER_BUILD="\
docker build --build-arg INPUT_DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT}\
    --build-arg INPUT_ARCHITECTURE=${DOCKER_INPUT_ARCHITECTURE}\
    --build-arg INPUT_IMAGE=ubuntu:${UBUNTU_BASE}\
    --build-arg INPUT_DEPENDENT_PACKAGE_FOLDERS=${DOWNLOADED_PACKAGE_FOLDERS}\
    --build-arg USER_ID=$(id -u)\
    --build-arg GROUP_ID=$(id -g)\
    -f Dockerfile -t ${DOCKER_IMAGE_NAME}:latest temp"
echo ${CMD_DOCKER_BUILD}
eval ${CMD_DOCKER_BUILD}
if [ $? -ne 0 ]
then
    echo "Error occurred creating Docker image ${DOCKER_IMAGE_NAME}:latest."
    exit 1
fi

# Run the build script in the docker image
echo "Running build script in the docker image ${DOCKER_IMAGE_NAME}:latest"
echo ""
CMD_DOCKER_RUN="\
docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} \
    --tty \
    --user $(id -u):$(id -g)
    -v ${TEMP_FOLDER}:/data/workspace/temp \
    ${DOCKER_IMAGE_NAME}:latest /data/workspace/${DOCKER_BUILD_SCRIPT}"
echo ${CMD_DOCKER_RUN}
eval ${CMD_DOCKER_RUN}
if [ $? -ne 0 ]
then
    echo Failed to build from docker image ${DOCKER_IMAGE_NAME}:latest
    echo "To log into and troubleshoot the docker container, run the following command:"
    echo ""
    echo "docker run --platform ${TARGET_DOCKER_PLATFORM_ARG} -v ${TEMP_FOLDER}:/data/workspace/temp -it --tty ${DOCKER_IMAGE_NAME}:latest"
    echo ""
    exit 1
fi

echo "Build Complete"

exit 0
