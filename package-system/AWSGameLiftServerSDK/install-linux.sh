#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

echo "TEMP_FOLDER=${TEMP_FOLDER}"
echo "TARGET_INSTALL_ROOT=${TARGET_INSTALL_ROOT}"

# Get the path within the source tarball to the root of the source folder for the build
SDK_SRC_SUBPATH=${1:-.}

# Get the install path from the build as the source for the final install package
SRC_INSTALL_PACKAGE_PATH=${TEMP_FOLDER}/install/
if [ ! -d ${SRC_INSTALL_PACKAGE_PATH} ]
then
	echo "Invalid source package path ${SRC_INSTALL_PACKAGE_PATH}"
	exit 1
fi

# Copy an additional notice file
ADDITIONAL_NOTICE_FILE=${TEMP_FOLDER}/src/${SDK_SRC_SUBPATH}/NOTICE_C++_AMAZON_GAMELIFT_SDK.TXT
if [ ! -f ${ADDITIONAL_NOTICE_FILE} ]
then
	echo "Invalid source package path ${SRC_INSTALL_PACKAGE_PATH}"
	exit 1
fi
echo "Copying the additional notice file ${ADDITIONAL_NOTICE_FILE} -> ${TARGET_INSTALL_ROOT}"
cp ${TEMP_FOLDER}/src/${SDK_SRC_SUBPATH}/NOTICE_C++_AMAZON_GAMELIFT_SDK.TXT ${TARGET_INSTALL_ROOT}


# Copy folder with messaging and error checks
# 
# Arguments:
#   $1 : Source folder
#   $2 : Destination folder
copy_folder() {

    SRC_FOLDER=$1
    TGT_FOLDER=$2
    if [ ! -d ${SRC_FOLDER} ]
    then
	    echo "Invalid source folder copy path ${SRC_FOLDER}"
	    exit 1
    fi
    echo "Copying ${SRC_FOLDER} -> ${TARGET_INSTALL_ROOT}"
    cp -r ${SRC_FOLDER} ${TARGET_INSTALL_ROOT}/
    if [ $? -ne 0 ]
    then
    	echo "Error copying ${SRC_FOLDER} -> ${TARGET_INSTALL_ROOT}"
    	exit 1
    fi
}

copy_folder ${SRC_INSTALL_PACKAGE_PATH}/include ${TARGET_INSTALL_ROOT}/

copy_folder ${SRC_INSTALL_PACKAGE_PATH}/cmake ${TARGET_INSTALL_ROOT}/

copy_folder ${SRC_INSTALL_PACKAGE_PATH}/bin ${TARGET_INSTALL_ROOT}/

copy_folder ${SRC_INSTALL_PACKAGE_PATH}/lib ${TARGET_INSTALL_ROOT}/

echo "Installation complete"

exit 0
