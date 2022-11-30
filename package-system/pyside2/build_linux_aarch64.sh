#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# Get the python executable from the package dependency
LOCAL_PYTHON3_BIN=$TEMP_FOLDER/python-3.10.5-rev2-linux-aarch64/python/bin/python3

SCRIPT_PATH=`dirname $0`


if [ ! -f "$LOCAL_PYTHON3_BIN" ]
then
    echo "Missing 3P dependency of python-3.10.5 $LOCAL_PYTHON3_BIN"
    echo "You will need to build the 3P version of python under the '`readlink -f ../python`'' folder"
    echo "with the following command:"
    echo
    echo "python3 build_package_image.py"
    echo
    exit 1
fi

# Set the dependent clang compiler for the build script to use
#LLVM_INSTALL_DIR=$TEMP_FOLDER/libclang-release_130-based-linux-Ubuntu20.04-gcc9.3-x86_64/libclang
#PATH=$LLVM_INSTALL_DIR/bin:$PATH
export LLVM_INSTALL_DIR=/usr/lib/llvm-6.0
export LLVM_CONFIG=/usr/bin/llvm-config-6.0
export PYTHON_INCLUDE_DIRS=$TEMP_FOLDER/python-3.10.5-rev2-linux-aarch64/python/include/python3.10


# Get the qt package's qmake location
LOCAL_3P_QTBUILD_PATH=$TEMP_FOLDER/qt-5.15.2-rev8-linux-aarch64/qt
LOCAL_3P_QTBUILD_QMAKE_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/bin/qmake`
LOCAL_3P_QTBUILD_LIB_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/lib`
if [ ! -f "$LOCAL_3P_QTBUILD_QMAKE_PATH" ]
then
    echo "Missing 3P dependency of Qt $LOCAL_3P_QTBUILD_PATH"
    echo
    exit 1
fi

# An additional patch needs to be applied since pyside-tools in the pyside2 repo is a ref 
pushd $TEMP_FOLDER/src/sources/pyside2-tools
PYSIDE_TOOLS_PATCH_FILE=$TEMP_FOLDER/../pyside2-tools.patch
echo Applying patch $PYSIDE_TOOLS_PATCH_FILE to pyside-tools 
git apply --ignore-whitespace $PYSIDE_TOOLS_PATCH_FILE
if [ $? -eq 0 ]; then
    echo "Patch applied"
else
    echo "Git apply failed"
    popd
    exit $retVal
fi
popd


echo Building source
pushd $TEMP_FOLDER/src

LD_LIBRARY_PATH=$LOCAL_3P_QTBUILD_LIB_PATH/
export LD_LIBRARY_PATH

# Build shiboken2 library first since it is 
echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer"
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer


echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone --limited-api=yes --skip-modules=Qml,Quick,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer" --shiboken-config-dir=$TEMP_FOLDER/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.1
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone  --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer --shiboken-config-dir=$TEMP_FOLDER/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.1

popd

exit 0
