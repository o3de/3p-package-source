#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

set -euo pipefail

# Limit Ninja jobs lower to avoid out of memory issues build qtwebengine
export NINJAJOBS=-j12
MAKE_FLAGS=-j32

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
BUILD_PATH=$TEMP_FOLDER/build

QTARRAY="qtbase,qtimageformats,qtsvg,qttranslations,qttools"
[[ -d $BUILD_PATH ]] || mkdir $BUILD_PATH
cd $BUILD_PATH

_OPTS="-prefix ${TARGET_INSTALL_ROOT} \
    -submodules ${QTARRAY} \
    -platform macx-clang \
    -debug-and-release \
    -c++std c++20 \
    -force-debug-info \
    -opensource \
    -qt-tiff \
    -qt-zlib \
    -confirm-license "

echo Configuring Qt...
../src/configure ${_OPTS}

cmake --build . --parallel
if [ $? -ne 0 ]
then
    echo "Failed to install QT."
    exit 1
fi

cmake --install . --config Debug
if [ $? -ne 0 ]
then
    echo "Failed to install QT Debug."
    exit 1
fi

cmake --install . --config RelWithDebInfo
if [ $? -ne 0 ]
then
    echo "Failed to install QT RelWithDebInfo."
    exit 1
fi

echo Qt installed successfully!
