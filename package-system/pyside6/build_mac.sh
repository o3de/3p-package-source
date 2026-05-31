#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

# This script will utilize Docker to build on either AMD64 or AARCH64 architectures. 

set -euo pipefail

echo 
echo TEMP_FOLDER=$TEMP_FOLDER
echo

LOCAL_PYTHON_ROOT=$TEMP_FOLDER/python-3.10.13-rev1-mac-arm64/Python.framework/Versions/Current
LOCAL_PYTHON_BIN=$LOCAL_PYTHON_ROOT/bin/python3

cd $TEMP_FOLDER
$LOCAL_PYTHON_BIN -m venv --system-site-packages --symlinks testenv

pushd $TEMP_FOLDER/testenv/lib
mkdir -p darwin
cd darwin
rm -f libpython3.10.dylib
ln -s $LOCAL_PYTHON_ROOT/lib/libpython3.10.dylib libpython3.10.dylib

cd $TEMP_FOLDER/testenv/include
rm -f python3.10
ln -s $LOCAL_PYTHON_ROOT/include/python3.10 python3.10

popd

source $TEMP_FOLDER/testenv/bin/activate

$TEMP_FOLDER/testenv/bin/pip3 install --upgrade pip

$TEMP_FOLDER/testenv/bin/pip3 install -r $TEMP_FOLDER/src/requirements.txt

echo "Installing build dependencies"

echo Building Pyside6

# pyside6 6.10.2 fails to build with the default Apple Clang compiler and the latest version of llvm (22 at the time of writing),
# so we need to use llvm 20 instead. 

if [[ $(brew list | grep llvm@20 | wc -l) -eq 0 ]]; then
    echo "llvm@20 is not installed. Installing..."
    brew install llvm@20
fi

export PATH="/opt/homebrew/opt/llvm@20/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm@20/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm@20/include"
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm@20"

cd $TEMP_FOLDER/src
$TEMP_FOLDER/testenv/bin/python3 setup.py install \
    --qtpaths=$TEMP_FOLDER/qt-6.10.2-rev6-mac-arm64/qt/bin/qtpaths6 \
    --macos-deployment-target=13.0 \
    --ignore-git \
    --parallel=8 \
    --build-type=all \
    --skip-docs \
    --log-level=verbose \
    --limited-api=yes \
    --no-unity \
    --skip-modules=Quick,MultimediaWidgets,Pdf,PdfWidgets,Positioning,Location,NetworkAuth,Nfc,WebEngineQuick,Multimedia,QuickControls2,QuickTest,QuickWidgets,UiToolsPrivate,RemoteObjects,Positioning,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,AxContainer

exit $?
