#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


echo "TEMP_FOLDER=${TEMP_FOLDER}"
echo "TARGET_INSTALL_ROOT=${TARGET_INSTALL_ROOT}"

SRC_PACKAGE_BASE=${TEMP_FOLDER}/build

# Copy the include folder
cp -r ${SRC_PACKAGE_BASE}/Shared/include $TARGET_INSTALL_ROOT/

# Copy the license file to the target installation root folder
SRC_PATH=${TEMP_FOLDER}/src

echo cp -f ${SRC_PACKAGE_BASE}/README.CURL ${TARGET_INSTALL_ROOT}/
cp -f ${SRC_PACKAGE_BASE}/README.CURL ${TARGET_INSTALL_ROOT}/

echo cp -f ${SRC_PACKAGE_BASE}/COPYING.CURL ${TARGET_INSTALL_ROOT}/
cp -f ${SRC_PACKAGE_BASE}/COPYING.CURL ${TARGET_INSTALL_ROOT}/

echo cp -f -R ${SRC_PACKAGE_BASE}/Shared/lib ${TARGET_INSTALL_ROOT}/bin
cp -f -R ${SRC_PACKAGE_BASE}/Shared/lib ${TARGET_INSTALL_ROOT}/bin

echo cp -f -R ${SRC_PACKAGE_BASE}/Static/lib ${TARGET_INSTALL_ROOT}/lib
cp -f -R ${SRC_PACKAGE_BASE}/Static/lib ${TARGET_INSTALL_ROOT}/lib

echo "Custom Install for AWSNativeSDK finished successfully"

exit 0
