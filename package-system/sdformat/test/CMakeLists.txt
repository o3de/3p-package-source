#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

project(test_sdformat VERSION 1.0 LANGUAGES CXX)

find_package(sdformat)

add_executable(test_sdformat test_sdformat.cpp)

# Make sure the O3DE sdformat is being used
target_link_libraries(test_sdformat PRIVATE 3rdParty::sdformat)
