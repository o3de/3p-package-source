#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if (TARGET 3rdParty::Imath)
    return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/o3de_package_utilities.cmake)

o3de_import_existing_config_files(Imath ${CMAKE_CURRENT_LIST_DIR}/OpenEXR/lib/cmake)

o3de_import_targets(NAMESPACE_FROM 
                        Imath
                    NAMESPACE_TO 
                        3rdParty
                    COMPONENTS 
                        Imath 
                        ImathConfig)

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using Imath (${Imath_VERSION}) from ${CMAKE_CURRENT_LIST_DIR}")
endif()