#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
echo "Starting pyside build"

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Use the host architecture if not supplied
TARGET_ARCH=${1:-$(uname -m)}

# 
# Check the target architecture and determine if the necessary cross compilation requirements are met
#

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

if [ "${TARGET_ARCH}" = "aarch64" ]
then
    echo "Building pyside2 for Linux aarch64"
    PYTHON_FOLDER_NAME=python-3.10.13-rev2-linux-aarch64
    QT_FOLDER_NAME=qt-5.15.2-rev9-linux-aarch64
else
    echo "Building pyside2 for Linux x86_64"
    PYTHON_FOLDER_NAME=python-3.10.13-rev2-linux
    QT_FOLDER_NAME=qt-5.15.2-rev9-linux
fi

DOCKER_BUILD_SCRIPT=docker_build_linux.sh
DOCKER_IMAGE_NAME=pyside2_linux_3p
PYSIDE2_TOOL_PATCH=pyside2-tools.patch


# Make sure docker is installed
DOCKER_VERSION=$(docker --version)
if [ $? -ne 0 ]
then
    echo "Required package docker is not installed"
    echo "Follow instructions on https://docs.docker.com/engine/install/ubuntu/ to install docker properly"
    exit 1
fi
echo "Detected Docker Version $DOCKER_VERSION"

echo "Using dependent 3rd Party Library ${PYTHON_FOLDER_NAME}"
echo "Using dependent 3rd Party Library ${QT_FOLDER_NAME}"

# Prepare the docker file and use the temp folder as the context root
cp ${DOCKER_BUILD_SCRIPT} temp/

pushd temp

# An additional patch needs to be applied since pyside-tools
pushd src/sources/pyside2-tools
PYSIDE_TOOLS_PATCH_FILE=${BASE_ROOT}/pyside2-tools.patch
echo Applying patch $PYSIDE_TOOLS_PATCH_FILE to pyside-tools
git apply --ignore-whitespace ../../../../$PYSIDE2_TOOL_PATCH
if [ $? -eq 0 ]; then
    echo "Patch applied"
else
    echo "Git apply failed"
    popd
    exit $retVal
fi
popd

# Build the Docker Image
echo "Building the docker build script"

echo docker build --build-arg PYTHON_FOLDER_NAME=${PYTHON_FOLDER_NAME} --build-arg QT_FOLDER_NAME=${QT_FOLDER_NAME} --build-arg DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT} -f ../Dockerfile -t ${DOCKER_IMAGE_NAME}:latest .
docker build --build-arg PYTHON_FOLDER_NAME=${PYTHON_FOLDER_NAME} --build-arg QT_FOLDER_NAME=${QT_FOLDER_NAME} --build-arg DOCKER_BUILD_SCRIPT=${DOCKER_BUILD_SCRIPT} -f ../Dockerfile -t ${DOCKER_IMAGE_NAME}:latest .
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
echo docker run -it --tty ${DOCKER_IMAGE_NAME}:latest /data/workspace/$DOCKER_BUILD_SCRIPT 
docker run --tty ${DOCKER_IMAGE_NAME}:latest /data/workspace/$DOCKER_BUILD_SCRIPT 
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
docker cp $CONTAINER_ID:/data/workspace/build/. $TARGET_INSTALL_ROOT  
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

