#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

echo "TEMP_FOLDER=${TEMP_FOLDER}"
echo "TARGET_INSTALL_ROOT=${TARGET_INSTALL_ROOT}"

# Get the install path from the build as the source for the final install package
SRC_INSTALL_PACKAGE_PATH=${TEMP_FOLDER}/build/
if [ ! -d ${SRC_INSTALL_PACKAGE_PATH} ]
then
    echo "Invalid source package path ${SRC_INSTALL_PACKAGE_PATH}"
    exit 1
fi

cp -r ${SRC_INSTALL_PACKAGE_PATH}/include ${TARGET_INSTALL_ROOT}/
cp -r ${SRC_INSTALL_PACKAGE_PATH}/cmake ${TARGET_INSTALL_ROOT}/
cp -r ${SRC_INSTALL_PACKAGE_PATH}/bin ${TARGET_INSTALL_ROOT}/
cp -r ${SRC_INSTALL_PACKAGE_PATH}/lib ${TARGET_INSTALL_ROOT}/
cp -r ${SRC_INSTALL_PACKAGE_PATH}/NOTICE_C++_AMAZON_GAMELIFT_SDK.TXT ${TARGET_INSTALL_ROOT}/

echo "Installation complete"

exit 0
