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

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

# add include directory
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})

if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${LIB_NAME}_LIBRARY   ${${LIB_NAME}_LIBRARY_DIR}/${LIB_NAME}.lib)
else()
    set(${LIB_NAME}_LIBRARY   ${${LIB_NAME}_LIBRARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

set(${LIB_NAME}_RUNTIME_DEPENDENCIES ${${LIB_NAME}_LIBRARY_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})

# for linking
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_LIBRARY})

# add runtime dependencies
ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${LIB_NAME}_RUNTIME_DEPENDENCIES})

# using squish causes your target to get a USING_SQUISH_SDK applied to it.
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE 
    USING_SQUISH_SDK
    SQUISH_USE_SSE=2
    SQUISH_USE_CPP
    SQUISH_USE_CCR
    )

set(${LIB_NAME}_FOUND True)