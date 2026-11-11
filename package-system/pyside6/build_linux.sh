#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script


set -euo pipefail

echo 
echo TEMP_FOLDER=$TEMP_FOLDER
echo

case "$(uname -m)" in
    x86_64)
        PACKAGE_SUFFIX=linux
        LIBCLANG_PACKAGE=libclang-release_20.1.3-based-linux-Ubuntu22.04-gcc11.4-x86_64
        ;;
    aarch64)
        PACKAGE_SUFFIX=linux-aarch64
        LIBCLANG_PACKAGE=libclang-release_20.1.3-based-linux-Debian-11.6-gcc10.2-arm64
        ;;
    *)
        echo "Unsupported Linux architecture: $(uname -m)"
        exit 1
        ;;
esac

LOCAL_PYTHON_ROOT=$TEMP_FOLDER/python-3.15.2-rev1-$PACKAGE_SUFFIX/python

cd "$TEMP_FOLDER"
"$LOCAL_PYTHON_ROOT/bin/python3" -m venv --symlinks testenv

source $TEMP_FOLDER/testenv/bin/activate

$TEMP_FOLDER/testenv/bin/pip3 install --upgrade pip

$TEMP_FOLDER/testenv/bin/pip3 install -r $TEMP_FOLDER/src/requirements.txt

echo "Installing build dependencies"

echo Building Pyside6

export LLVM_INSTALL_DIR="$TEMP_FOLDER/$LIBCLANG_PACKAGE/libclang"
export PATH="$LLVM_INSTALL_DIR/bin:$PATH"
export CC="$LLVM_INSTALL_DIR/bin/clang"
export CXX="$LLVM_INSTALL_DIR/bin/clang++"

cd $TEMP_FOLDER/src
$TEMP_FOLDER/testenv/bin/python3 setup.py install \
    --qtpaths=$TEMP_FOLDER/qt-6.12.0-rev1-$PACKAGE_SUFFIX/qt/bin/qtpaths6 \
    --ignore-git \
    --parallel=8 \
    --build-type=all \
    --relwithdebinfo \
    --no-strip \
    --skip-docs \
    --log-level=verbose \
    --limited-api=yes \
    --skip-modules=QmlFeatures,Qml,Quick,PrintSupport,Sql,MultimediaWidgets,Pdf,PdfWidgets,Positioning,Location,NetworkAuth,Nfc,WebEngineQuick,Multimedia,QuickControls2,QuickTest,QuickWidgets,UiToolsPrivate,RemoteObjects,Positioning,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,AxContainer

exit $?
