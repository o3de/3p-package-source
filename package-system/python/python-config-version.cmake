#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(PACKAGE_VERSION 3.15.2)
set(PACKAGE_VERSION_EXACT False)
set(PACKAGE_VERSION_COMPATIBLE False)

if (NOT ${PACKAGE_FIND_NAME} STREQUAL "Python")
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 0 AND NOT PACKAGE_FIND_VERSION_MAJOR EQUAL 3)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 1 AND NOT PACKAGE_FIND_VERSION_MINOR EQUAL 15)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 2 AND NOT PACKAGE_FIND_VERSION_PATCH EQUAL 2)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 3)
    return()
endif()

if (PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
endif()

set(PACKAGE_VERSION_COMPATIBLE TRUE)
