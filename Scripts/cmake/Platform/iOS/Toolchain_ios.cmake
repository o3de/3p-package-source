#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "OSX Architectures to support" FORCE)

include(${CMAKE_CURRENT_LIST_DIR}/SDK_ios.cmake)

set(CMAKE_XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")

set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)

set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "14.0" CACHE STRING "The minimum IOS Version to support" FORCE)

set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
