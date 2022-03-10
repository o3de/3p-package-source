#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_PNG VERSION 1.0 LANGUAGES C)

find_package(PNG)

add_executable(test_PNG test_png.c)

# note that we use 3rdParty::PNG here.  This will ONLY work 
# if the O3DE version of PNG is used, which is what we are testing for.
target_link_libraries(test_PNG PRIVATE 3rdParty::PNG)

set_target_properties(test_PNG PROPERTIES
                 XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED OFF
                 MACOSX_BUNDLE TRUE
                 XCODE_ATTRIBUTE_EXECUTABLE_NAME "test_PNG")

