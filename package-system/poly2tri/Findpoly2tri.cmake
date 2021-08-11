#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(LIB_NAME "poly2tri")

set(TARGET_WITH_NAMESPACE "3rdParty::${LIB_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(${LIB_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/${LIB_NAME}/include/${LIB_NAME})
set(${LIB_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/${LIB_NAME}/${LIB_NAME}/lib)

if (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/../debug/lib/poly2tri.lib)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/poly2tri.lib)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/../debug/lib/libpoly2tri.a)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/libpoly2tri.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/../debug/lib/libpoly2tri.a)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/libpoly2tri.a)
endif()

set(${LIB_NAME}_LIBRARY
    "$<$<CONFIG:profile>:${${LIB_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:release>:${${LIB_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:debug>:${${LIB_NAME}_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(
    TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})
target_link_libraries(
    ${TARGET_WITH_NAMESPACE}
    INTERFACE ${${LIB_NAME}_LIBRARY})

set(${LIB_NAME}_FOUND True)