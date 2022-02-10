#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "vulkan-validationlayers")

set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(PATH_TO_DLL ${CMAKE_CURRENT_LIST_DIR}/vulkan-validationlayers/lib/release)

set(_DLL_NAME ${PATH_TO_DLL}/VkLayer_khronos_validation${CMAKE_SHARED_LIBRARY_SUFFIX})
set(${MY_NAME}_RUNTIME_JSON_DEPENDENCIES ${PATH_TO_DLL}/VkLayer_khronos_validation.json)

# Using INTERFACE instead of SHARED due to needing to specify IMPORTED_IMPLIB *AND* IMPORTED_LOCATION properties.
# Only the dll file is needed to enable validation.
# SHARED version:
# set(_LIB_NAME ${PATH_TO_DLL}/VkLayer_khronos_validation${CMAKE_STATIC_LIBRARY_SUFFIX})
# set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_IMPLIB ${_LIB_NAME})
# set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION ${_DLL_NAME})
# add_library(${TARGET_WITH_NAMESPACE} SHARED IMPORTED GLOBAL) 

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL) 
ly_add_target_files(
    TARGETS
    ${TARGET_WITH_NAMESPACE}
    FILES
    ${${MY_NAME}_RUNTIME_JSON_DEPENDENCIES}
    ${_DLL_NAME}
)

set(${MY_NAME}_FOUND True)