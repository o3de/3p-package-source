#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(LIB_NAME "lz4")

set(TARGET_WITH_NAMESPACE "3rdParty::${LIB_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(${LIB_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/include)
set(${LIB_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/lib)
set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/../debug/lib/${CMAKE_STATIC_LIBRARY_PREFIX}lz4d${CMAKE_STATIC_LIBRARY_SUFFIX})
set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}lz4${CMAKE_STATIC_LIBRARY_SUFFIX})


add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)
ly_target_include_system_directories(
    TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})

set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
    IMPORTED_LOCATION ${${LIB_NAME}_LIBRARY_RELEASE}
)

if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    # IMPORTED_LOCATION_DEBUG property could be set here if it is desired that Windows
    # uses a debug version of lz4
endif()

set(${LIB_NAME}_FOUND True)
