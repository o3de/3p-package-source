
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
set(CMAKE_C_FLAGS "-fPIC")
set(CMAKE_CXX_FLAGS "-fPIC")

# cmake will auto-select the rest.
