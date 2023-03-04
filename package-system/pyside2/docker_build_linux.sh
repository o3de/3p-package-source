#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

BASE_ROOT=/data/workspace
DEP_PYTHON_BASE=${BASE_ROOT}/${PYTHON_FOLDER_NAME}
DEP_QT_BASE=${BASE_ROOT}/${QT_FOLDER_NAME}

echo "Using Python at ${DEP_PYTHON_BASE}"
echo "Using Qt at ${DEP_QT_BASE}"

# Get the python executable from the package dependency
LOCAL_PYTHON3_BIN=${DEP_PYTHON_BASE}/python/bin/python3
if [ ! -f $LOCAL_PYTHON3_BIN ]
then
    echo "Required local 3P python not detected"
    exit 1
fi

export PYTHON_INCLUDE_DIRS=${DEP_PYTHON_BASE}/python/include/python3.10
declare -x PYTHON_INCLUDE_DIRS=${DEP_PYTHON_BASE}/python/include/python3.10
export LLVM_INSTALL_DIR=/usr/lib/llvm-12
export LLVM_CONFIG=/usr/bin/llvm-config-12

# Setup the local QT Paths
# Get the qt package's qmake location
LOCAL_3P_QTBUILD_PATH=${DEP_QT_BASE}/qt
LOCAL_3P_QTBUILD_QMAKE_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/bin/qmake`
LOCAL_3P_QTBUILD_LIB_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/lib`
if [ ! -f "$LOCAL_3P_QTBUILD_QMAKE_PATH" ]
then
    echo "Missing 3P dependency of Qt $LOCAL_3P_QTBUILD_PATH"
    echo
    exit 1
fi

# An additional patch needs to be applied since pyside-tools in the pyside2 repo is a ref 
pushd ${BASE_ROOT}/src/sources/pyside2-tools
PYSIDE_TOOLS_PATCH_FILE=${BASE_ROOT}/pyside2-tools.patch
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

mkdir -p /home/ubuntu/github/3p-package-source/package-system/python/linux_aarch64/package/python/include
pushd /home/ubuntu/github/3p-package-source/package-system/python/linux_aarch64/package/python/include
ln -s ${DEP_PYTHON_BASE}/python/include/python3.10 python3.10
popd


echo Building source
pushd ${BASE_ROOT}/src

LD_LIBRARY_PATH=$LOCAL_3P_QTBUILD_LIB_PATH/
export LD_LIBRARY_PATH

# Build shiboken2 library first since it is 
echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer"
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer


echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone --limited-api=yes --skip-modules=Qml,Quick,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer" --shiboken-config-dir=${BASE_ROOT}/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone  --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer --shiboken-config-dir=${BASE_ROOT}/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.1

popd

exit 0

