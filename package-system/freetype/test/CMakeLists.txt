#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_Freetype VERSION 1.0 LANGUAGES C)

find_package(Freetype)

add_executable(test_Freetype test_Freetype.c)

# note that we use 3rdParty::TIFF here.  This will ONLY work 
# if the O3DE version of TIFF is used, which is what we are testing for.
target_link_libraries(test_Freetype PRIVATE 3rdParty::Freetype)

set_target_properties(test_Freetype PROPERTIES
                 XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED OFF
                 MACOSX_BUNDLE TRUE
                 XCODE_ATTRIBUTE_EXECUTABLE_NAME "test_Freetype")

