#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)

PROJECT(test_OpenSSL VERSION 1.0 LANGUAGES C)

find_package(OpenSSL)

add_executable(test_OpenSSL test_OpenSSL.c)

# note that we use 3rdParty::OpenSSL here.  This will ONLY work 
# if the O3DE version of OpenSSL is used, which is what we are testing for.
target_link_libraries(test_OpenSSL PRIVATE 3rdParty::OpenSSL)
