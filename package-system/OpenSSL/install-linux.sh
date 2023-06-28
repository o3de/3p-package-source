#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# Install from the build folder
TARGET_BUILD_FOLDER=$1
if [ "${TARGET_BUILD_FOLDER}" == "" ]
then
    echo "Missing the target build folder name to create the installation base from"
    exit 1
elif [ ${TARGET_BUILD_FOLDER} == "src" ]
then
    echo "The target build folder cannot be 'src'"
    exit 1
fi

SRC_PATH=${TEMP_FOLDER}/src
BLD_PATH=${TEMP_FOLDER}/${TARGET_BUILD_FOLDER}

echo "BUILD FOLDER=${BLD_PATH}"
echo "TARGET_INSTALL_ROOT=${TARGET_INSTALL_ROOT}"

copy_folder_to_target() {

    local FOLDER=$1

    echo cp -rf ${BLD_PATH}/${FOLDER} ${TARGET_INSTALL_ROOT}/
    cp -rf ${BLD_PATH}/${FOLDER} ${TARGET_INSTALL_ROOT}/
    if [ $? -ne 0 ]
    then
        echo "Error copying the ${FOLDER} folder ${BLD_PATH}/${FOLDER} to ${TARGET_INSTALL_ROOT}/${FOLDER}"
        exit 1
    fi
}


rm -rf ${TARGET_INSTALL_ROOT}
mkdir -p ${TARGET_INSTALL_ROOT}



# Copy the license file
echo "Copying LICENSE to ${TARGET_INSTALL_ROOT}"
cp -f ${SRC_PATH}/LICENSE ${TARGET_INSTALL_ROOT}/
if [ $? -ne 0 ]
then
    echo "Copying LICENSE to ${TARGET_INSTALL_ROOT} failed."
    exit 1
fi

# Copy the include folder
copy_folder_to_target include

# Copy the bin folder
copy_folder_to_target bin

# Copy the lib folder
copy_folder_to_target lib

echo "Custom Install for OpenSSL finished successfully"

exit 0
