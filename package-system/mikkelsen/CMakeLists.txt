#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.17)

project(mikkelsen)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_library(
    ${CMAKE_PROJECT_NAME} STATIC
    mikktspace.h
    mikktspace.cpp
)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES PUBLIC_HEADER mikktspace.h)

include(../../Scripts/cmake/package.cmake)
package_install(
    NAME ${CMAKE_PROJECT_NAME}
    VERSION 1.0.0.5
    URL "https://github.com/mmikk/MikkTSpace"
    LICENSE Zlib
    LICENSE_FILE LICENSE.txt
    INCLUDE_SUBDIR ${CMAKE_PROJECT_NAME}
)