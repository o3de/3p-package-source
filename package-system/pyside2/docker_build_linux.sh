#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

BASE_ROOT=/data/workspace
PACKAGE_BASE=${BASE_ROOT}/build
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

#export LLVM_INSTALL_DIR=/usr/lib/llvm-12
#export LLVM_CONFIG=/usr/bin/llvm-config-12

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

echo Building source
pushd ${BASE_ROOT}/src

LD_LIBRARY_PATH=$LOCAL_3P_QTBUILD_LIB_PATH/
export LD_LIBRARY_PATH

# Build shiboken2 library first since it is 
echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer"
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=shiboken2 --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer
if [ $? -ne 0 ]
then
    echo "Error building shiobken2 package"
    exit 1
fi

echo "$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone --limited-api=yes --skip-modules=Qml,Quick,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer" --shiboken-config-dir=${BASE_ROOT}/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.
$LOCAL_PYTHON3_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=pyside2 --no-examples --skip-docs --standalone  --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,QtQuickControls2,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer --shiboken-config-dir=${BASE_ROOT}/src/pyside3a_install/py3.10-qt5.15.1-64bit-release/lib/cmake/Shiboken2-5.15.2.1
if [ $? -ne 0 ]
then
    echo "Error building pyside2 package"
    exit 1
fi

popd

echo PACKAGE_BASE=$PACKAGE_BASE
INSTALL_SOURCE=$BASE_ROOT/src/pyside3a_install/`ls $BASE_ROOT/src/pyside3a_install`
echo INSTALL_SOURCE=$INSTALL_SOURCE

# Copy the LICENSE and README files
echo cp $BASE_ROOT/src/LICENSE.FDL $PACKAGE_BASE/
cp $BASE_ROOT/src/LICENSE.FDL $PACKAGE_BASE/
echo copy $BASE_ROOT/src/LICENSE.GPLv3 $PACKAGE_BASE/
cp $BASE_ROOT/src/LICENSE.GPLv3 $PACKAGE_BASE/
echo copy $BASE_ROOT/src/LICENSE.GPLv3-EXCEPT $PACKAGE_BASE/
cp $BASE_ROOT/src/LICENSE.GPLv3-EXCEPT $PACKAGE_BASE/
echo copy $BASE_ROOT/src/LICENSE.LGPLv3 $PACKAGE_BASE/
cp $BASE_ROOT/src/LICENSE.LGPLv3 $PACKAGE_BASE/
echo copy $BASE_ROOT/src/README.* $PACKAGE_BASE/
cp $BASE_ROOT/src/README.* $PACKAGE_BASE/

cp -r $INSTALL_SOURCE/bin $PACKAGE_BASE
cp -r $INSTALL_SOURCE/include $PACKAGE_BASE
cp -r $INSTALL_SOURCE/lib $PACKAGE_BASE
cp -r $INSTALL_SOURCE/share $PACKAGE_BASE

# Copy the dependent libclang.so.12 from the downloaded dependent package

cp $LLVM_INSTALL_DIR/lib/libclang-12.so.1 $PACKAGE_BASE/bin
pushd $PACKAGE_BASE/bin

ln -s libclang-12.so.1 libclang-12.so.1
ln -s libclang.so libclang-12.so.1

popd

# RPATH fixes
$BASE_ROOT/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/libpyside2.abi3.so.5.15.2.1
$BASE_ROOT/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/libshiboken2.abi3.so.5.15.2.1
$BASE_ROOT/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/python3.10/site-packages/shiboken2/shiboken2.abi3.so
$BASE_ROOT/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/bin/shiboken2
$BASE_ROOT/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/bin/pyside2-lupdate

# Add additional files needed for pip install
cp $BASE_ROOT/../__init__.py $PACKAGE_BASE/lib/python3.10/site-packages/
cp $BASE_ROOT/../setup.py $PACKAGE_BASE/lib/python3.10/site-packages/


exit 0

