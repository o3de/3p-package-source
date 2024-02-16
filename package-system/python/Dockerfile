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

# The optional environment variable for list of folders in the mapped temp folders that represent additional 3P dependent packages
ARG INPUT_DEPENDENT_PACKAGE_FOLDERS

FROM ${INPUT_ARCHITECTURE}/${INPUT_IMAGE}

ARG INPUT_DOCKER_BUILD_SCRIPT
ARG INPUT_BUILD_FOLDER
ARG INPUT_DEPENDENT_PACKAGE_FOLDERS

ENV WORKSPACE=/data/workspace
ENV DOCKER_BUILD_PATH=$WORKSPACE/$INPUT_BUILD_FOLDER
ENV DOWNLOADED_PACKAGE_FOLDERS=$INPUT_DEPENDENT_PACKAGE_FOLDERS

WORKDIR $WORKSPACE

# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

# Install the development packages needed to build python
RUN apt-get install -y autoconf \
                       build-essential \
                       cmake \
                       git \
                       libbz2-dev \
                       libgdbm-compat-dev \
                       libgdbm-dev \
                       liblzma-dev \
                       libreadline-dev \
                       libtool \
                       libc6 \
                       python3-dev \
                       python3 \
                       tcl8.6-dev \
                       tk8.6-dev \
                       texinfo \
                       curl

# Prevent the copying of the src folder from being cached
ARG CACHEBUST=1

# Copy the build script specific to this Docker script in order to execute the build
COPY ${INPUT_DOCKER_BUILD_SCRIPT} /data/workspace/
