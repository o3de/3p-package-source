#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# Get the python executable from the package dependency
LOCAL_PYTHON37_BIN=$TEMP_FOLDER/python-3.7.10-rev2-linux/python/bin/python3

SCRIPT_PATH=`dirname $0`


if [ ! -f "$LOCAL_PYTHON37_BIN" ]
then
    echo "Missing 3P dependency of python3.7 $LOCAL_PYTHON37_BIN"
    echo "You will need to build the 3P version of python under the '`readlink -f ../python`'' folder"
    echo "with the following command:"
    echo
    echo "python3 build_package_image.py"
    echo
    exit 1
fi

# Get the qt package's qmake location
LOCAL_3P_QTBUILD_PATH=$TEMP_FOLDER/qt-5.15.2-rev6-linux/qt
LOCAL_3P_QTBUILD_QMAKE_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/bin/qmake`
LOCAL_3P_QTBUILD_LIB_PATH=`readlink -f $LOCAL_3P_QTBUILD_PATH/lib`
if [ ! -f "$LOCAL_3P_QTBUILD_QMAKE_PATH" ]
then
    echo "Missing 3P dependency of Qt $LOCAL_3P_QTBUILD_PATH"
    echo
    exit 1
fi


# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
echo Building source
pushd $TEMP_FOLDER/src

LD_LIBRARY_PATH=$LOCAL_3P_QTBUILD_LIB_PATH/
export LD_LIBRARY_PATH

echo "$LOCAL_PYTHON37_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=all --limited-api=yes --skip-modules=Qml,Quick,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer"
$LOCAL_PYTHON37_BIN setup.py install --qmake=$LOCAL_3P_QTBUILD_QMAKE_PATH --build-type=all --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer

popd

exit 0 