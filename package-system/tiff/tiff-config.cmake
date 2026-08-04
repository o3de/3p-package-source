#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file is called to make sure that if we request a specific version
# we respond only to that version

set(PACKAGE_VERSION 4.7.2)
set(PACKAGE_VERSION_EXACT False)
set(PACKAGE_VERSION_COMPATIBLE False)

if (NOT ${PACKAGE_FIND_NAME} STREQUAL "TIFF")
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 0 AND PACKAGE_FIND_VERSION_MAJOR GREATER 4)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 1 AND PACKAGE_FIND_VERSION_MINOR GREATER 7)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 2 AND PACKAGE_FIND_VERSION_PATCH GREATER 2)
    return()
endif()

if (PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
endif()

set(PACKAGE_VERSION_COMPATIBLE TRUE)
