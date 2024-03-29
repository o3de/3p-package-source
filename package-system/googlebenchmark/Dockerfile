
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This docker file uses ubuntu 20.04 as the base image so that the AWS Native C++ libraries will use OpenSSL 3 as the base
# for its dependencies
#

FROM public.ecr.aws/ubuntu/ubuntu:20.04_stable
 
WORKDIR /data/workspace

ARG DOCKER_BUILD_SCRIPT

# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration wget gpg

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update

# Install the development packages needed to build Qt from source
RUN apt-get install -y build-essential \
                       cmake \
                       ninja-build \
                       libpcre3-dev 


RUN apt upgrade -y

# Prepare a target folder within the container to install the build artifacts tp
RUN mkdir -p /data/workspace/build && \
    mkdir -p /data/workspace/src


ARG CACHEBUST=1

# Copy the build script specific to this Docker script in order to execute the build
COPY ${DOCKER_BUILD_SCRIPT} /data/workspace/
COPY src /data/workspace/src/

