#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

echo "TEMP_FOLDER=${TEMP_FOLDER}"
echo "TARGET_INSTALL_ROOT=${TARGET_INSTALL_ROOT}"

SRC_PATH=${TEMP_FOLDER}/src
BLD_PATH=${TEMP_FOLDER}/build
INSTALL_PATH=${TEMP_FOLDER}/install


# Copy the include folders to the target root folder
OUT_INCLUDE_PATH=$TARGET_INSTALL_ROOT/include

echo "Copying include headers to ${OUT_INCLUDE_PATH}"
mkdir -p ${OUT_INCLUDE_PATH}
cp -f -R "${INSTALL_PATH}/include/"* ${OUT_INCLUDE_PATH}/ 
if [ $? -ne 0 ]
then
    echo "Copying include headers to ${OUT_INCLUDE_PATH} failed."
    exit 1
fi


# Copy the license file to the target installation root folder
echo "Copying LICENSE.txt to ${TARGET_INSTALL_ROOT}"
cp -f ${SRC_PATH}/LICENSE.txt ${TARGET_INSTALL_ROOT}/
if [ $? -ne 0 ]
then
    echo "Copying LICENSE.txt to ${TARGET_INSTALL_ROOT} failed."
    exit 1
fi

copy_shared_and_static_libs() {

    local OPENSSL_LABEL=$1

    # Copy the shared libraries to the bin folder
    OUT_BIN_PATH=${TARGET_INSTALL_ROOT}/bin/${OPENSSL_LABEL}
    echo "Copying shared libraries (.so) to ${OUT_BIN_PATH}"

    mkdir -p ${OUT_BIN_PATH}
    cp -f -R "${INSTALL_PATH}/bin/${OPENSSL_LABEL}" ${OUT_BIN_PATH}
    if [ $? -ne 0 ]
    then
        echo "Copying shared libraries (.so) to ${OUT_BIN_PATH} failed."
        exit 1
    fi

    # Copy the static libraries to the lib folder
    OUT_LIB_PATH=${TARGET_INSTALL_ROOT}/lib/${OPENSSL_LABEL}
    echo "Copying static libraries (.a) to ${OUT_LIB_PATH}"

    mkdir -p ${OUT_LIB_PATH}
    cp -f -R "${INSTALL_PATH}/lib/${OPENSSL_LABEL}" ${OUT_LIB_PATH}
    if [ $? -ne 0 ]
    then
        echo "Copying static libraries (.a) to ${OUT_LIB_PATH} failed."
        exit 1
    fi

}

copy_shared_and_static_libs openssl-1

copy_shared_and_static_libs openssl-3

echo "Custom Install for AWSNativeSDK finished successfully"

exit 0
