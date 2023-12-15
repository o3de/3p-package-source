#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file is called to make sure that if we request a specific version
# we respond only to that version

set(PACKAGE_VERSION 3.10.13)
set(PACKAGE_VERSION_EXACT False)
set(PACKAGE_VERSION_COMPATIBLE False)

if (NOT ${PACKAGE_FIND_NAME} STREQUAL "Python")
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 0 AND NOT PACKAGE_FIND_VERSION_MAJOR EQUAL 3)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 1 AND NOT PACKAGE_FIND_VERSION_MINOR EQUAL 10)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 2 AND NOT PACKAGE_FIND_VERSION_PATCH EQUAL 11)
    return()
endif()

if (PACKAGE_FIND_VERSION_COUNT GREATER 3)
    return()
endif()

if (PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
endif()

set(PACKAGE_VERSION_COMPATIBLE TRUE)