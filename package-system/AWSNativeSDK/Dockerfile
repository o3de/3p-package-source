#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# The cpu architecture to base the docker base script from
ARG INPUT_ARCHITECTURE=amd64

# The root to base the docker script base from
ARG INPUT_IMAGE=ubuntu:20.04

# The build subfolder where the final artifacts are built in this container which will be used to copy the results out of
ARG INPUT_BUILD_FOLDER=build

# The name of the build script to copy to the docker image to execute
ARG INPUT_DOCKER_BUILD_SCRIPT=build.sh

# The git tag to use for the branch for cloning curl from git
ARG INPUT_DEP_CURL_GIT_TAG

# The optional environment variable for list of folders in the mapped temp folders that represent additional 3P dependent packages
ARG INPUT_DEPENDENT_PACKAGE_FOLDERS


FROM ${INPUT_ARCHITECTURE}/${INPUT_IMAGE}

ARG INPUT_DOCKER_BUILD_SCRIPT
ARG INPUT_BUILD_FOLDER
ARG INPUT_DEPENDENT_PACKAGE_FOLDERS
ARG INPUT_DEP_CURL_GIT_TAG

ENV WORKSPACE=/data/workspace
ENV DOCKER_BUILD_PATH=$WORKSPACE/$INPUT_BUILD_FOLDER
ENV DOWNLOADED_PACKAGE_FOLDERS=$INPUT_DEPENDENT_PACKAGE_FOLDERS


WORKDIR $WORKSPACE

# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

# Install the development packages needed to build AWS Native C++ SDK
RUN apt-get install -y cmake \
                       clang-12 \
                       ninja-build \
                       git \
                       build-essential \
                       autoconf \
                       libtool


RUN mkdir -p $WORKSPACE/curl && \
    git -C $WORKSPACE/curl clone https://github.com/curl/curl.git --single-branch --recursive --branch $INPUT_DEP_CURL_GIT_TAG src

# Prevent the copying of the src folder from being cached
ARG CACHEBUST=1

# Copy the build script specific to this Docker script in order to execute the build
COPY ${INPUT_DOCKER_BUILD_SCRIPT} /data/workspace/
