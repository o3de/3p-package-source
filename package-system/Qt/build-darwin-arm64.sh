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
    -nomake examples \
    -nomake tests \
    -release \
    -c++std c++20 \
    -opensource \
    -qt-tiff \
    -qt-zlib \
    -no-icu \
    -dbus-linked \
    -framework \
    -confirm-license "

echo Configuring Qt...
../src/configure ${_OPTS}

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
qtframeworks=(QtLabsPlatform QtQuickControls2 QtQuickParticles QtQuickControls2ImagineStyleImpl QtQuickControls2BasicStyleImpl QtLabsSharedImage QtQmlMeta QtDesigner QtQuickControls2FusionStyleImpl QtQuickShapesDesignHelpers QtQuickWidgets QtQuickControls2Material QtQmlXmlListModel QtShaderTools QtLabsSynchronizer QtQuickLayouts QtQuickControls2Basic QtHelp QtQuickVectorImage QtPrintSupport QtGui QtDBus QtQuickControls2Fusion QtQuickTemplates2 QtQuickDialogs2Utils QtXml QtQuick QtQuickEffects QtCore QtQuickDialogs2QuickImpl QtQmlNetwork QtQml QtQuickVectorImageGenerator QtQmlCore QtQmlWorkerScript QtQuickControls2Impl QtOpenGL QtLabsQmlModels QtQuickControls2Universal QtQmlLocalStorage QtQmlCompiler QtOpenGLWidgets QtUiTools QtLabsSettings QtSvgWidgets QtQuickControls2MacOSStyleImpl QtQuickControls2MaterialStyleImpl QtTest QtWidgets QtQuickShapes QtQuickTest QtNetwork QtQuickControls2UniversalStyleImpl QtSvg QtQuickControls2IOSStyleImpl QtDesignerComponents QtQuickControls2Imagine QtQuickVectorImageHelpers QtQmlModels QtLabsAnimation QtLabsFolderListModel QtQuickControls2FluentWinUI3StyleImpl QtQuickDialogs2 QtLabsWavefrontMesh QtSql QtConcurrent)

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
