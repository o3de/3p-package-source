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

if(${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/zlibstaticd.lib)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/zlibstatic.lib)
else()
    set(zlib_LIBRARY_DEBUG   ${zlib_LIBS_DIR}/libz.a)
    set(zlib_LIBRARY_RELEASE ${zlib_LIBS_DIR}/libz.a)
endif()

add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${zlib_INCLUDE_DIR})

set_target_properties(${TARGET_WITH_NAMESPACE}  
    PROPERTIES
        IMPORTED_LOCATION       "${zlib_LIBRARY_RELEASE}"
        IMPORTED_LOCATION_DEBUG "${zlib_LIBRARY_DEBUG}")

set(zlib_FOUND True)

