#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

set -euo pipefail

MAKE_FLAGS=-j32

echo ""
echo "------ BUILDING QT5 FROM SOURCE ------"
echo ""
echo "BASIC REQUIREMENTS in case something goes wrong:"
echo "   - git installed and in PATH"
echo "   - QT5 packages needed for building (https://wiki.qt.io/Building_Qt_5_from_Git)"
echo "   - Note: This script is currently written for buildng on Ubuntu Linux only."
echo "   - Note: installing binaries with pip must result with them being on PATH."
echo ""

# Make sure we have all the required dev packages
REQUIRED_DEV_PACKAGES="libx11-xcb-dev libxcb-icccm4-dev libxcb-shm0-dev libxcb-image0 libxcb-image0-dev libxcb-util-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-sync-dev libxcb-xinerama0-dev libxcb-glx0-dev libgbm-dev libxcb-shape0-dev libxcb-xfixes0-dev libxcb-xkb-dev libfontconfig1-dev libssl-dev libtiff-dev"
ALL_PACKAGES=`apt list 2>/dev/null`
for req_package in $REQUIRED_DEV_PACKAGES
do
    PACKAGE_COUNT=`echo $ALL_PACKAGES | grep $req_package | wc -l`
    if [[ $PACKAGE_COUNT -eq 0 ]]; then
        echo Missing required package $req_package
        exit 1
    fi
done

# Base the Tiff of the dependent tiff O3DE package (static)
TIFF_PREFIX=$TEMP_FOLDER/tiff-4.2.0.15-rev3-linux-arm64/tiff
TIFF_INCDIR=$TIFF_PREFIX/include
TIFF_LIBDIR=$TIFF_PREFIX/lib

# We need to also bring in the zlib dependency since Tiff is a static lib dependency
ZLIB_PREFIX=$TEMP_FOLDER/zlib-1.2.11-rev5-linux-arm64/zlib
ZLIB_INCDIR=$ZLIB_PREFIX/include
ZLIB_LIBDIR=$ZLIB_PREFIX/lib

BUILD_PATH=$TEMP_FOLDER/build

[[ -d $BUILD_PATH ]] || mkdir $BUILD_PATH
cd $BUILD_PATH

echo Configuring Qt...
../src/configure \
-prefix ${TARGET_INSTALL_ROOT} \
-opensource \
-nomake examples \
-nomake tests \
-confirm-license \
-no-icu \
-dbus \
-no-separate-debug-info \
-release \
-force-debug-info \
-qt-libpng \
-qt-libjpeg \
-no-feature-vnc \
-no-feature-linuxfb \
--tiff=system \
-qt-zlib \
-v \
-no-cups \
-no-glib \
-no-feature-renameat2 \
-no-feature-getentropy \
-no-feature-statx \
-no-egl \
-I $TIFF_INCDIR \
-I $ZLIB_INCDIR \
-L $TIFF_LIBDIR \
-L $ZLIB_LIBDIR \
-c++std c++1z \
-openssl \
-fontconfig


echo Qt configured, building modules...
qtarray=(qtbase qtgraphicaleffects qtimageformats qtsvg qttools qtx11extras)

for qtlib in "${qtarray[@]}"; do
    echo Building $qtlib...
    make module-$qtlib $MAKE_FLAGS
    echo Built $qtlib.
done

echo Finished building modules, installing...
for qtlib in "${qtarray[@]}"; do
    echo Installing $qtlib...
    make module-$qtlib-install_subtargets
    echo $qtlib installed.
done

echo Qt installed successfully!
