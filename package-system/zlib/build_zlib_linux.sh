#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# Building zlib on ubuntu requires the following packages
REQUIRED_DEV_PACKAGES="cmake ninja-build gcc"
ALL_PACKAGES=`apt list | grep installed  2>/dev/null`
for req_package in $REQUIRED_DEV_PACKAGES
do
    PACKAGE_COUNT=`echo $ALL_PACKAGES | grep $req_package | wc -l`
    if [[ $PACKAGE_COUNT -eq 0 ]]; then
        echo "Missing required package '${req_package}'. Install this package and try again."
        exit 1
    fi
done



cmake -S temp/src -B temp/build \
     -G Ninja \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_C_FLAGS=-fPIC \
     -DSKIP_INSTALL_FILES=YES || exit 1

cmake --build temp/build --target zlibstatic --parallel || exit 1

