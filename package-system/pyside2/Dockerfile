
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
                       git \
                       libgl1-mesa-dev \
                       libpcre2-dev \
                       chrpath

RUN apt-get install -y libclang-12-dev

RUN apt upgrade -y

# Prepare a target folder within the container to install the build artifacts tp
RUN mkdir -p /data/workspace/build && \
    mkdir -p /data/workspace/src

run git config --global --add safe.directory /data/workspace/src && \
    git config --global --add safe.directory /data/workspace/src/sources/pyside2-tools

ENV PYTHON_FOLDER_NAME=${PYTHON_FOLDER_NAME}
ENV QT_FOLDER_NAME=${QT_FOLDER_NAME}
ENV LLVM_INSTALL_DIR=/usr/lib/llvm-12
ENV LLVM_CONFIG=/usr/bin/llvm-config-12

# The 3P package for python has some embedded paths from the host machine that was
# used to build it, and pyside2 extracts these paths to deduce the include and lib
# paths. To work around this and make it appear that the dependent 3P python package
# was installed in this docker sctructure, we will instead create a symlink from the
# 3p package's original path to the actual one mapped to the workspace path
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        mkdir -p /home/ubuntu/github/3p-package-source/package-system/python/linux_aarch64/package && \
        cd /home/ubuntu/github/3p-package-source/package-system/python/linux_aarch64/package && \
        ln -s /data/workspace/${PYTHON_FOLDER_NAME}/python python; \
    else \
        mkdir -p /home/github/3p-package-source/package-system/python/linux_x64/package && \
        cd /home/github/3p-package-source/package-system/python/linux_x64/package && \
        ln -s /data/workspace/${PYTHON_FOLDER_NAME}/python python; \
    fi

# Copy the build script specific to this Docker script in order to execute the build
ARG CACHEBUST=1

COPY ${DOCKER_BUILD_SCRIPT} /data/workspace/
COPY src /data/workspace/src/
COPY ${PYTHON_FOLDER_NAME} /data/workspace/${PYTHON_FOLDER_NAME}/
COPY ${QT_FOLDER_NAME} /data/workspace/${QT_FOLDER_NAME}/

ENTRYPOINT ["/bin/bash"]
