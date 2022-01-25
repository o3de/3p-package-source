#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#

set(MY_NAME "vulkan-validationlayers")

set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(PATH_TO_DLL ${CMAKE_CURRENT_LIST_DIR}/vulkan-validationlayers/lib/release)
    
    set(${MY_NAME}_RELEASE_RUNTIME_DEPENDENCIES
        ${PATH_TO_DLL}/VkLayer_khronos_validation.dll
    )

    set(${MY_NAME}_RUNTIME_JSON_DEPENDENCIES
        ${PATH_TO_DLL}/VkLayer_khronos_validation.json
    )

    ly_add_target_files(
        TARGETS 
        ${TARGET_WITH_NAMESPACE} 
        FILES 
        ${${MY_NAME}_RELEASE_RUNTIME_DEPENDENCIES} 
        ${${MY_NAME}_RUNTIME_JSON_DEPENDENCIES})
endif()

set(${MY_NAME}_FOUND True)
