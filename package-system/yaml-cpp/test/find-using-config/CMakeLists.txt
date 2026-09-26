#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(auto_test_package VERSION 1.0 LANGUAGES C CXX)

#ask for a lower version get the new one just to make sure the comparison works right.
find_package(yaml-cpp 0.8.0...<9.9.9 CONFIG REQUIRED)

add_executable(yaml-cpp-test ${CMAKE_CURRENT_LIST_DIR}/../yaml-cpp-test.cpp)
target_link_libraries(yaml-cpp-test yaml-cpp)
