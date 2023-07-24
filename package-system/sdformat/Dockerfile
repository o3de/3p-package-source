#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# PROTIP: ARG instructions declared before the FROM instruction
# can only be used in the FROM instructions
# Afterwards, it is required to redeclare the ARG instruction without a default value
# to use IT in the build stage
# Therefore it is better to not declare ARG instructions that are not used as part for the FROM instruction
# until after it
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
# The cpu architecture to base the docker base script from
ARG INPUT_ARCHITECTURE=amd64

# The root to base the docker script base from
ARG INPUT_IMAGE=ubuntu:20.04

FROM ${INPUT_ARCHITECTURE}/${INPUT_IMAGE}

# NOTE: Now it is safe to declare ARG instructions that are used in the build stage
# of the image

# The name of the build script to copy to the docker image to execute
ARG INPUT_DOCKER_BUILD_SCRIPT=docker_build_sdformat.sh

# The optional environment variable for list of folders in the mapped temp folders that represent additional 3P dependent packages
ARG INPUT_DEPENDENT_PACKAGE_FOLDERS

# Set the github tag for gz-cmake
ARG INPUT_DEP_GZ_CMAKE_GIT_TAG=gz-cmake3_3.3.0
ARG INPUT_DEP_TINYXML2_GIT_TAG=9.0.0
# Pinning to the gz-math7 release which libsdformat has a dependency on
ARG INPUT_DEP_GZ_MATH_GIT_TAG=gz-math7_7.2.0
# Pinning to the gz-utils2 to the last release in September 2022
# The libsdformat has an explicit dependency on gz-utils2
ARG INPUT_DEP_GZ_UTILS_GIT_TAG=gz-utils2_2.0.0


# Get access to the user ID and group ID of the user running the docker
ARG USER_ID
ARG GROUP_ID

# The build subfolder where the binary artifacts are built to
ARG INPUT_BUILD_FOLDER=build

# The install subfolder where binary artifacts are copied to
# It is being copied to /data/workspace/temp/install
# which is a local filesystem mounted on the user machine
ARG INPUT_INSTALL_FOLDER=install

# Provide the default CMAKE_BUILD_TYPE for the 3rdParty
ARG INPUT_CMAKE_BUILD_TYPE=Release

ENV WORKSPACE=/data/workspace
ENV LOCAL_FILESYSTEM=$WORKSPACE/temp
ENV DOCKER_BUILD_PATH=$WORKSPACE/$INPUT_BUILD_FOLDER
ENV DOCKER_INSTALL_PATH=$LOCAL_FILESYSTEM/$INPUT_INSTALL_FOLDER
ENV DOWNLOADED_PACKAGE_FOLDERS=$INPUT_DEPENDENT_PACKAGE_FOLDERS
ENV CMAKE_BUILD_TYPE=$INPUT_CMAKE_BUILD_TYPE

WORKDIR $WORKSPACE


# Initialize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

# Install the development packages needed to build libsdformat
RUN apt-get install -y build-essential \
                       cmake \
                       git \
                       ruby


# Add a user called "user" that will be used inside the docker
# It will have the same UID and GID as the outside user
RUN addgroup --gid $GROUP_ID user && \
    adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

RUN chown -R user:user ${WORKSPACE}

# Delete the deps folder as the root user in case it is owned by the root
RUN sh -c "if [ -d ${WORKSPACE}/deps ]; then rm -rf ${WORKSPACE}/deps; fi"

# Start running as the locally created user
USER user

# Pull dependent git repos needed to build libsdformat
RUN mkdir -p ${WORKSPACE}/deps

# Fetch tinyxml2
# Fetch gz-cmake
# Fetch gz-utils
# Fetch gz-math
RUN git clone https://github.com/leethomason/tinyxml2.git \
    --single-branch --branch $INPUT_DEP_TINYXML2_GIT_TAG $WORKSPACE/deps/tinyxml2 && \
    git clone https://github.com/gazebosim/gz-cmake.git \
    --single-branch --branch $INPUT_DEP_GZ_CMAKE_GIT_TAG $WORKSPACE/deps/gz-cmake && \
    git clone https://github.com/gazebosim/gz-utils.git \
    --single-branch --branch $INPUT_DEP_GZ_UTILS_GIT_TAG $WORKSPACE/deps/gz-utils && \
    git clone https://github.com/gazebosim/gz-math.git \
    --single-branch --branch $INPUT_DEP_GZ_MATH_GIT_TAG $WORKSPACE/deps/gz-math

# Prevent the copying of the src folder from being cached
ARG CACHEBUST=1

# Copy the build script specific to this Docker script in order to execute the build
COPY ${INPUT_DOCKER_BUILD_SCRIPT} /data/workspace/
