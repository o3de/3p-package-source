
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This docker file uses ubuntu 20.04 as the base image so that the AWS Native C++ libraries will use OpenSSL 3 as the base
# for its dependencies
#

FROM public.ecr.aws/ubuntu/ubuntu:20.04_stable
#FROM ubuntu:20.04
 
WORKDIR /data/workspace

ARG PYTHON_FOLDER_NAME
ARG QT_FOLDER_NAME
ARG DOCKER_BUILD_SCRIPT

# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
# RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration
RUN apt-get -y install tzdata locales keyboard-configuration

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8


# Install the development packages needed to build Qt from source
RUN apt-get install -y cmake \
                       build-essential \
                       clang-12 \
                       llvm-12 \
                       git

RUN apt-get install -y libclang-12-dev

RUN apt upgrade -y

# Prepare a target folder within the container to install the build artifacts tp
RUN mkdir -p /data/workspace/build

run git config --global --add safe.directory /data/workspace/src && \
    git config --global --add safe.directory /data/workspace/src/sources/pyside2-tools

ENV PYTHON_FOLDER_NAME=${PYTHON_FOLDER_NAME}
ENV QT_FOLDER_NAME=${QT_FOLDER_NAME}

ARG CACHEBUST=1

# Copy the build script specific to this Docker script in order to execute the build
COPY ${DOCKER_BUILD_SCRIPT} /data/workspace/
COPY pyside2-tools.patch /data/workspace/

ENTRYPOINT ["/bin/bash"]
