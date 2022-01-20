#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_expat VERSION 1.0 LANGUAGES C)

find_package(expat)

add_executable(test_expat test_expat.c)

# note that we use 3rdParty::expat here.  This will ONLY work 
# if the O3DE version of expat is used, which is what we are testing for.
target_link_libraries(test_expat PRIVATE 3rdParty::expat)

set_target_properties(test_expat PROPERTIES
                 XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED OFF
                 MACOSX_BUNDLE TRUE
                 XCODE_ATTRIBUTE_EXECUTABLE_NAME "test_expat")

