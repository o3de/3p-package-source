
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

ARG TIFF_PACKAGE_DIR
ARG ZLIB_PACKAGE_DIR


# Initilize apt cache
RUN apt-get clean && apt-get update

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# Install the development packages needed to build AWS Native C++ SDK
RUN apt-get install -y qtbase5-dev \ 
                       build-essential \
                       perl \
                       python3 \
                       git \
                       '^libxcb.*-dev' \
                       libx11-xcb-dev \
                       libglu1-mesa-dev \ 
                       libxrender-dev \
                       libxi-dev \
                       libxkbcommon-dev \
                       libxkbcommon-x11-dev \
                       libgbm-dev \
                       libxext-dev \
                       libfontconfig1-dev \ 
                       libssl-dev \
                       libtiff-dev


# Prevent the copying of the src folder from being cached
ARG CACHEBUST=1

#RUN cd /data/workspace && \
#    mkdir src

# Copy the git synced source from the context base to this container
#COPY src  /data/workspace/src/

# Copy the dependent 3P libraries to the docker image
#RUN mkdir ${TIFF_PACKAGE_DIR}
COPY ${TIFF_PACKAGE_DIR} /data/workspace/${TIFF_PACKAGE_DIR}

#RUN mkdir ${ZLIB_PACKAGE_DIR}
COPY ${ZLIB_PACKAGE_DIR} /data/workspace/${ZLIB_PACKAGE_DIR}

# Copy the build script specific to this Docker script in order to execute the build
COPY docker_build_qt_linux.sh /data/workspace/






