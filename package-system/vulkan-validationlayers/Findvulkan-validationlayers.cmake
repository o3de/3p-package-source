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

add_library(${TARGET_WITH_NAMESPACE} SHARED IMPORTED GLOBAL)

set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION ${_DLL_NAME})
ly_add_target_files(
    TARGETS
    ${TARGET_WITH_NAMESPACE}
    FILES
    ${${MY_NAME}_RUNTIME_JSON_DEPENDENCIES})
)

set(${MY_NAME}_FOUND True)
