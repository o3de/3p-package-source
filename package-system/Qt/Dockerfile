
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This docker file uses ubuntu 20.04 as the base image to install the dependencies to build Qt from source
#

FROM amd64/ubuntu:20.04
 
WORKDIR /data/workspace

# Initilize apt cache
RUN apt-get clean && apt-get update && apt-get upgrade

# Setup time zone and locale data (necessary for SSL and HTTPS packages)
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata locales keyboard-configuration

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV ENABLE_QT_WAYLAND=0

# Install the development packages needed to build Qt from source
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
                       libtiff-dev \
                       libwayland-dev \
                       libwayland-egl1-mesa \
                       libwayland-server0 \
                       libgles2-mesa-dev \
                       libdrm-dev

# Prepare a target folder within the container to install the build artifacts tp
RUN mkdir -p /data/workspace/qt

RUN git clone --single-branch --recursive --branch v5.15.1 git://code.qt.io/qt/qtwayland.git && \
    ln -s /data/workspace/qtwayland/include/QtWaylandCompositor/5.15.1/QtWaylandCompositor/private/qwayland-server-qt-texture-sharing-unstable-v1.h /data/workspace/qtwayland/src/compositor/qwayland-server-qt-texture-sharing-unstable-v1.h && \
    ln -s /data/workspace/qtwayland/include/QtWaylandCompositor/5.15.1/QtWaylandCompositor/private/wayland-qt-texture-sharing-unstable-v1-server-protocol.h /data/workspace/qtwayland/src/compositor/wayland-qt-texture-sharing-unstable-v1-server-protocol.h

# Copy the build script specific to this Docker script in order to execute the build
COPY docker_build_qt_linux.sh /data/workspace/
