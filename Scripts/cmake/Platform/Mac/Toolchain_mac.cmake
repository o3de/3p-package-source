
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file just exists to provide a place to put defaults that should be present 
# in all 3p packages so that they don't have to seperately define this for each one.

set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "The minimum OSX Version to support" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

# If we need to compile for Mac M1, set CMAKE_APPLE_SILICON_PROCESSOR to arm64 on the command line.
# this will override CMAKE_HOST_SYSTEM_PROCESSOR.
set(CMAKE_SYSTEM_PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR})

# cmake will auto-select the rest.
