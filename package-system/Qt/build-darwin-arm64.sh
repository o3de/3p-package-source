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
QT_SOURCE_ROOT=$TEMP_FOLDER/src

QTARRAY="qtbase,qtimageformats,qtsvg,qttranslations,qttools"
[[ -d $BUILD_PATH ]] || mkdir $BUILD_PATH
cd $BUILD_PATH

_OPTS="-prefix ${TARGET_INSTALL_ROOT} \
    -submodules ${QTARRAY} \
    -skip qtdeclarative \
    -skip qtactiveqt \
    -platform macx-clang \
    -nomake examples \
    -nomake tests \
    -release \
    -c++std c++20 \
    -opensource \
    -qt-tiff \
    -qt-zlib \
    -qt-webp \
    -no-jasper \
    -no-mng \
    -no-icu \
    -no-dbus \
    -no-feature-printsupport \
    -no-feature-sql \
    -no-feature-designer \
    -feature-linguist \
    -no-feature-assistant \
    -no-feature-distancefieldgenerator \
    -no-feature-kmap2qmap \
    -no-feature-pixeltool \
    -no-feature-qdbus \
    -no-feature-qdoc \
    -no-feature-qtattributionsscanner \
    -no-feature-qtdiag \
    -no-feature-qtplugininfo \
    -framework \
    -confirm-license \
    -- \
    -DCMAKE_INSTALL_MESSAGE=NEVER"

echo Configuring Qt...
${QT_SOURCE_ROOT}/configure ${_OPTS}

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

# The installation target on darwin is not installing the framework's header paths in the main
# include folder. Create a symlink to the headers there for backwards compatibility
qtframeworks=(QtConcurrent QtCore QtGui QtNetwork QtOpenGL QtOpenGLWidgets QtSvg QtSvgWidgets QtTest QtUiTools QtWidgets QtXml)

cd $TARGET_INSTALL_ROOT/include
for qtframework in "${qtframeworks[@]}"; do
    if [ -d $TARGET_INSTALL_ROOT/lib/$qtframework.framework/Headers ]; then
        echo "Linking ${TARGET_INSTALL_ROOT}/lib/${qtframework}.framework/Headers to ${TARGET_INSTALL_ROOT}/include/${qtframework}"
        ln -sfF ../lib/$qtframework.framework/Headers $qtframework
    else
        echo "Unable to find $TARGET_INSTALL_ROOT/lib/${qtframework}.framework/Headers (${qtframework}) Skipping.."
    fi
done

echo Qt installed successfully!
