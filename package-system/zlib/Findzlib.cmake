#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::zlib")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(zlib_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/zlib/include)
set(zlib_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/zlib/lib)

if (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/libz.a)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/libz.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Android")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/libz.a)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/libz.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/zlibstaticd.lib)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/zlibstatic.lib)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/libz.a)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/libz.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "iOS")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/libz.a)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/libz.a)
endif()

# we set it to a generator expression for multi-config situations:
set(zlib_LIBRARY                  "$<$<CONFIG:profile>:${zlib_LIBRARY_RELEASE}>")
set(zlib_LIBRARY ${zlib_LIBRARY} "$<$<CONFIG:Release>:${zlib_LIBRARY_RELEASE}>")
set(zlib_LIBRARY ${zlib_LIBRARY} "$<$<CONFIG:Debug>:${zlib_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${zlib_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${zlib_LIBRARY})

set(zlib_FOUND True)
