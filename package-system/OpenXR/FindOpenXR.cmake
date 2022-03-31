#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::OpenXR")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(MY_NAME "OpenXR")

set(${MY_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenXR/include)
set(${MY_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenXR/lib)
set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}openxr_loader${CMAKE_STATIC_LIBRARY_SUFFIX})
set(${MY_NAME}_LIBRARY_DEBUG ${${MY_NAME}_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}openxr_loaderd${CMAKE_STATIC_LIBRARY_SUFFIX})

add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)

set_target_properties(${TARGET_WITH_NAMESPACE}
    PROPERTIES 
        IMPORTED_LOCATION_DEBUG ${${MY_NAME}_LIBRARY_DEBUG}
        IMPORTED_LOCATION ${${MY_NAME}_LIBRARY_RELEASE})

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})

set(${MY_NAME}_FOUND True)