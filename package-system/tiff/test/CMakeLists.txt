#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.19)

PROJECT(test_TIFF VERSION 1.0 LANGUAGES C)

find_package(TIFF)

add_executable(test_TIFF test_tiff.c)
target_link_libraries(test_TIFF PRIVATE 3rdParty::TIFF)
