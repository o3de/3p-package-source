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

# Only Xcodebuilder 10.x or 11.x are known to build this version of Qt on mac successfully
XCODEBUILD_VERSION=`xcodebuild -version | grep Xcode | awk '{print $2}'`
XCODEBUILD_VERSION_MAJOR=`echo $XCODEBUILD_VERSION | awk -F. '{print $1}'`
echo Xcodebuild version $XCODEBUILD_VERSION detected.
if [ $XCODEBUILD_VERSION_MAJOR -gt "11" ]; then
  echo Error: Xcodebuild version $XCODEBUILD_VERSION detected. Only Xcodebuild version 10 or 11 have been tested with this version of Qt
  exit 1
elif [ $XCODEBUILD_VERSION_MAJOR -lt "10" ]; then
  echo Error: Xcodebuild version $XCODEBUILD_VERSION detected. Only Xcodebuild version 10 or 11 have been tested with this version of Qt
  exit 1
fi

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

# Base the Tiff of the dependent tiff O3DE package (static)
TIFF_PREFIX=$TEMP_FOLDER/tiff-4.2.0.15-rev3-mac/tiff
TIFF_INCDIR=$TIFF_PREFIX/include
TIFF_LIBDIR=$TIFF_PREFIX/lib

# We need to also bring in the zlib dependency since Tiff is a static lib dependency
ZLIB_PREFIX=$TEMP_FOLDER/zlib-1.2.11-rev5-mac/zlib
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
-L $ZLIB_LIBDIR

echo Qt configured, building modules...
qtarray=(qtbase qtgraphicaleffects qtimageformats qtsvg qttools qtmacextras qttranslations)

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

# The installation target on darwin is not installing the framework's header paths in the main
# include folder. Create a symlink to the headers there for backwards compatibility
cd $TARGET_INSTALL_ROOT/include

qtframeworks=(QtConcurrent QtCore QtDBus QtDesigner QtDesignerComponents QtGui QtHelp QtMacExtras QtNetwork QtOpenGL QtPrintSupport QtQml QtQmlModels QtQmlWorkerScript QtQuick QtQuickParticles QtQuickShapes QtQuickTest QtQuickWidgets QtSql QtSvg QtTest QtUiPlugin QtWidgets QtXml QtZlib)
for qtframework in "${qtframeworks[@]}"; do
    if [ -d $TARGET_INSTALL_ROOT/lib/$qtframework.framework/Headers ]; then
        echo "Linking ${TARGET_INSTALL_ROOT}/lib/${qtframework}.framework/Headers/ to ${TARGET_INSTALL_ROOT}/include/${qtframework}"
        ln -s ../lib/$qtframework.framework/Headers/ $qtframework
    else
        echo "Unable to find $TARGET_INSTALL_ROOT/lib/${qtframework}.framework/Headers (${qtframework}) Skipping.."
    fi
done

echo Qt installed successfully!
