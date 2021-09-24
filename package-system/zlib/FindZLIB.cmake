#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# the following is like an include guard
set(TARGET_WITH_NAMESPACE "3rdParty::zlib")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

# note that we mimic the behavior or the FindZLIB.cmake that ships with CMake.
# as such, we declare several variables that other 3rdParty Packages which call
# find_package(ZLIB) might be expecting even if O3DE itself does not use them.

# variables required from FindZLIB.cmake in CMake source:

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(ZLIB_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/zlib/lib/zlibstatic.lib)
else()
    set(ZLIB_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/zlib/lib/libz.a)
endif()

set(ZLIB_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/zlib/include)
set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS})
set(ZLIB_LIBRARY ${ZLIB_LIBRARIES})
set(ZLIB_VERSION_STRING "1.2.11")
set(ZLIB_VERSION_MAJOR "1")
set(ZLIB_VERSION_MINOR "2")
set(ZLIB_VERSION_PATCH "11")
set(ZLIB_MAJOR_VERSION "1")
set(ZLIB_MINOR_VERSION "2")
set(ZLIB_PATCH_VERSION "11")
set(ZLIB_FOUND True)

# now declare the targets - O3DE has the namespaced target, CMake has ZLIB::ZLIB
add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)
add_library(ZLIB::ZLIB ALIAS ${TARGET_WITH_NAMESPACE})

# cmake < 3.21 and visual studio < 16.10 don't properly implement SYSTEM includes
# so we use O3DEs patched implementation if it is available and fallback to default if not:
if (COMMAND ly_target_include_system_directories)
    ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${ZLIB_INCLUDE_DIR})
else()
    target_include_directories(${TARGET_WITH_NAMESPACE} SYSTEM INTERFACE ${ZLIB_INCLUDE_DIR})
endif()

# set the library file as the imported location so that things know to link to it:
set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION "${ZLIB_LIBRARY}")

# if we're not in O3DE, it's also helpful to show a message to logs that indicate that this
# library was successfully picked up, and is going to be used.  A good way to know if you're in O3DE or not
# is that O3DE sets various cache variables before using its 3p library.
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using the O3DE version of the ZLIB library from ${CMAKE_CURRENT_LIST_DIR}")
endif()
