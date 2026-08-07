#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(PACKAGE_VERSION 3.4.13)
set(PACKAGE_VERSION_EXACT False)
set(PACKAGE_VERSION_COMPATIBLE False)

if (NOT ${PACKAGE_FIND_NAME} STREQUAL "OpenEXR")
    return()
endif()

if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
    return()
endif()

set(PACKAGE_VERSION_COMPATIBLE TRUE)

if (PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
endif()
