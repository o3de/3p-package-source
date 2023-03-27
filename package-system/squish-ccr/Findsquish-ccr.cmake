#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# this file actually ingests the library and defines targets.

set(LIB_NAME "squish-ccr")
set(TARGET_WITH_NAMESPACE "3rdParty::${LIB_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(${LIB_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/include)
set(${LIB_NAME}_LIBRARY_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/bin)

add_library(${TARGET_WITH_NAMESPACE} SHARED IMPORTED GLOBAL)

# add include directory
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})

if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
        IMPORTED_LOCATION ${${LIB_NAME}_LIBRARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
        IMPORTED_IMPLIB   ${${LIB_NAME}_LIBRARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
else()
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
        IMPORTED_LOCATION ${${LIB_NAME}_LIBRARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
endif()

# using squish causes your target to get a USING_SQUISH_SDK applied to it.
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE 
    USING_SQUISH_SDK
    SQUISH_USE_SSE=2
    SQUISH_USE_CPP
    SQUISH_USE_CCR
    )

set(${LIB_NAME}_FOUND True)
