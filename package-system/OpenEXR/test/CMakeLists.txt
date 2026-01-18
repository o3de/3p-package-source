#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_openexr VERSION 1.0 LANGUAGES C CXX)

find_package(OpenEXR)
find_package(Imath)

if (OPENEXR_TEST_VER_3_4)
    add_compile_definitions(OPENEXR_TEST_VER_3_4)
endif()

add_executable(test_openexr test_openexr.cpp)

# note that we use 3rdParty::OpenEXR here.  This will ONLY work 
# if the O3DE version of OpenEXR is used, which is what we are testing for.
target_link_libraries(test_openexr PRIVATE 3rdParty::OpenEXR)

set_target_properties(test_openexr PROPERTIES
                 XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED OFF
                 MACOSX_BUNDLE TRUE
                 XCODE_ATTRIBUTE_EXECUTABLE_NAME "test_OpenEXR")

