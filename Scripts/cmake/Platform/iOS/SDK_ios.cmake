#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# Detect the ios SDK Path and set the SYSROOT
find_program(XCRUN_PROG "xcrun")
execute_process(COMMAND ${XCRUN_PROG} --sdk iphoneos --show-sdk-path
                OUTPUT_VARIABLE IOS_SDK_PATH
                RESULTS_VARIABLE GET_IOS_SDK_RESULT)
if (NOT GET_IOS_SDK_RESULT EQUAL 0)
    message(FATAL_ERROR "Unable to determine the iOS SDK path")
endif()
string(STRIP ${IOS_SDK_PATH} IOS_SDK_PATH)

set(CMAKE_OSX_SYSROOT "${IOS_SDK_PATH}")

