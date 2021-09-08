#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "libpng")

set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")

set(${MY_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/${MY_NAME}/include)
set(${MY_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/${MY_NAME}/lib)

if (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/libpng16.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/libpng16.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Android")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/libpng16.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/libpng16.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/libpng16_staticd.lib)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/libpng16_static.lib)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/libpng16.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/libpng16.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "iOS")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/libpng16.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/libpng16.a)
endif()

# we set it to a generator expression for multi-config situations:
set(libpng_LIBRARY                   "$<$<CONFIG:profile>:${libpng_LIBRARY_RELEASE}>")
set(libpng_LIBRARY ${libpng_LIBRARY} "$<$<CONFIG:Release>:${libpng_LIBRARY_RELEASE}>")
set(libpng_LIBRARY ${libpng_LIBRARY} "$<$<CONFIG:Debug>:${libpng_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${libpng_LIBRARY})

set(${MY_NAME}_FOUND True)
