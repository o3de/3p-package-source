#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_imath VERSION 1.0 LANGUAGES C CXX)

# Necessary to override iOS toolchain behavior of 
# setting CMAKE_FIND_ROOT_PATH_MODE_PACKAGE to ONLY, which prevents it from looking for packages
# anywhere except in the sysroot (ie, inside xcode's ios SDK subfolder).
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

#ask for a lower version get the new one just to make sure the comparison works right.
find_package(Imath CONFIG 3.1.1 REQUIRED)

add_executable(test_imath ${CMAKE_CURRENT_LIST_DIR}/../imathtest.cpp)
target_link_libraries(test_imath Imath::Imath)

set_target_properties(test_expat PROPERTIES
                 XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED OFF
                 MACOSX_BUNDLE TRUE
                 XCODE_ATTRIBUTE_EXECUTABLE_NAME "test_imath")

