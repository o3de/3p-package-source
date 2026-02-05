#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

# Arg 1: The tiff package name
TIFF_FOLDER_NAME=$1

# Arg 2: The zlib package name
ZLIB_FOLDER_NAME=$2

# Arg 3: The openssl package name
OPENSSL_FOLDER_NAME=$3

# Determine the host architecture
CURRENT_HOST_ARCH=$(uname -m)

# Use the host architecture if not supplied
TARGET_ARCH=${4:-$(uname -m)}

# If the host and target architecture does not match, we stop
if [ "${CURRENT_HOST_ARCH}" != ${TARGET_ARCH} ]
then
   echo "Cross compilation not supported"
   exit 1
fi

# Qt6 dependencies. See https://doc.qt.io/qt-6/linux-requirements.html
sudo apt-get install -y libfontconfig1-dev \
    libfreetype-dev \
    libgtk-3-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxcb-cursor-dev \
    libxcb-glx0-dev \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \
    libxcb-xkb-dev \
    libxcb1-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxrender-dev

QTARRAY="qtbase,qtimageformats,qtsvg,qttranslations,qtwayland"
BUILD_ROOT="${TEMP_FOLDER}/src"
BUILD_PATH="${TEMP_FOLDER}/build"

echo ${BUILD_PATH}

cd ${BUILD_PATH}

_OPTS="-prefix ${TARGET_INSTALL_ROOT} \
    -submodules ${QTARRAY} \
    -platform linux-clang \
    -release \
    -c++std c++20 \
    -opensource \
    -confirm-license "

${BUILD_ROOT}/configure ${_OPTS}
if [ $? -ne 0 ]
then
    echo "Failed to configure QT."
    exit 1
fi

cmake --build . --parallel
if [ $? -ne 0 ]
then
    echo "Failed to install QT."
    exit 1
fi

cmake --install . --config Release
if [ $? -ne 0 ]
then
    echo "Failed to install QT Release."
    exit 1
fi
