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

FROM ${INPUT_ARCHITECTURE}/${INPUT_IMAGE}

ARG INPUT_ARCHITECTURE
ARG INPUT_DOCKER_BUILD_SCRIPT
ARG INPUT_BUILD_FOLDER

ENV WORKSPACE=/data/workspace
ENV DOCKER_BUILD_PATH=$WORKSPACE/$INPUT_BUILD_FOLDER
ENV BUILD_ARCHITECTURE=$INPUT_ARCHITECTURE

WORKDIR $WORKSPACE

# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

RUN apt-get install -y curl zip unzip tar g++ git wget build-essential libssl-dev checkinstall clang tclsh


# Build cmake 3.20 from source
RUN cd /data/workspace && \
    mkdir -p cmake_src && \
    cd cmake_src && \
    wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz && \
    tar -zvxf cmake-3.20.0.tar.gz && \
    cd cmake-3.20.0 && \
    ./bootstrap && \
    make -j8 && \
    checkinstall --pkgname=cmake --pkgversion="3.20-custom" --default && \
    hash -r

ARG CACHEBUST=1

COPY src /data/workspace/src

COPY ${INPUT_DOCKER_BUILD_SCRIPT} /data/workspace/
