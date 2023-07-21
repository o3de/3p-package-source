#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

LIB_NAME=sdformat

# Install from the install folder
TARGET_INSTALL_FOLDER=$1
if [ "${TARGET_INSTALL_FOLDER}" == "" ]
then
    echo "Missing the target install folder name to create the installation base from"
    exit 1
elif [ ${TARGET_INSTALL_FOLDER} == "src" ]
then
    echo "The target install folder cannot be 'src'"
    exit 1
fi

SRC_PATH=${TEMP_FOLDER}/src
BLD_PATH=${TEMP_FOLDER}/${TARGET_INSTALL_FOLDER}
DEP_INSTALL_PATH=${TEMP_FOLDER}/deps/${TARGET_INSTALL_FOLDER}

echo "SOURCE INSTALL FOLDER=${BLD_PATH}"
echo "SOURCE DEPENDENCIES INSTALL FOLDER=${DEP_INSTALL_PATH}"
echo "TARGET INSTALL ROOT=${TARGET_INSTALL_ROOT}"

copy_folder_to_target() {

    local FOLDER=$1

    CMD="cp -rf ${BLD_PATH}/${FOLDER} ${TARGET_INSTALL_ROOT}/"
    echo $CMD
    $CMD
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

# Copy the sdformat include folder
copy_folder_to_target include


# Copy the sdformat lib folder
copy_folder_to_target lib

# Copy the dependent libraries include files for sdformat (tinyxml2, gz-utils, gz-math)
# exclude the gz-cmake folder, since it is not needed to use the library.

# Change directory to the dependency install path so that `find` can use relative paths
pushd ${DEP_INSTALL_PATH}/include > /dev/null
# Use cp --parents to preserve the directory structure
# Skip copying directories via the `find -not -type d` command
find . -path ./gz/cmake* -prune -o \( -not -type d \) -print | xargs -i{} cp --parents {} ${TARGET_INSTALL_ROOT}/include

# Change back to 'temp' directory
popd > /dev/null

# Now change to the lib directory
pushd ${DEP_INSTALL_PATH}/lib > /dev/null
# Copy the dependent library archive and shared object files for sdformat (tinyxml2, gz-utils, gz-math)
find . -not -type d | xargs -i{} cp --parents {} ${TARGET_INSTALL_ROOT}/lib

# Change back to 'temp' directory
popd > /dev/null
echo "Custom Install for ${LIB_NAME} finished successfully"

exit 0
