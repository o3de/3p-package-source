#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# note that this script calls find_package(xxxxx) which executes code
# inside other Findxxxx.cmake files as if they are in the current scope
# that means that its not safe to use generic variable names like "TARGETNAME"
# as the other scripts may also use those names.  To be extra safe, prefix
# all our variables with our library name ("Freetype")

set(Freetype_O3DE_TARGETNAME "3rdParty::Freetype")
if (TARGET ${Freetype_O3DE_TARGETNAME})
    # Someone has already run this file before, don't re-run
    return()
endif()

# note that the rest of the world calls this Freetype, as in, capital F Freetype.
# to make sure this is compatible, O3DE will also use it via Freetype instead of freetype
# we create standard named targets to be compatible with what non-O3DE software expects:
set(Freetype_TARGETNAME "Freetype::Freetype")

# we're trying to be a drop-in replacement for the FindFreetype.cmake that is shipped
# with CMake itself, so we set the same variables with the same uppercase for compatibility
# for questions about these variables, see https://cmake.org/cmake/help/latest/module/FindFreetype.html
set(FREETYPE_FOUND True)
set(FREETYPE_INCLUDE_DIR_ft2build ${CMAKE_CURRENT_LIST_DIR}/freetype/include/freetype2)
set(FREETYPE_INCLUDE_DIR_freetype2 ${CMAKE_CURRENT_LIST_DIR}/freetype/include/freetype2/freetype)
set(FREETYPE_INCLUDE_DIRS ${FREETYPE_INCLUDE_DIR_ft2build} ${FREETYPE_INCLUDE_DIR_freetype2})
set(FREETYPE_VERSION_STRING "2.11.1")
set(FREETYPE_VERSION ${FREETYPE_VERSION_STRING})

# an effort to shorten lines:
set(_FT_LIB_DIR  ${CMAKE_CURRENT_LIST_DIR}/freetype/lib/)
set(_FT_LIB_NAME ${CMAKE_STATIC_LIBRARY_PREFIX}freetype${CMAKE_STATIC_LIBRARY_SUFFIX})
set(FREETYPE_LIBRARIES ${_FT_LIB_DIR}/${_FT_LIB_NAME})

# in addition to being a drop-in replacement for the CMake-provided FindFreetype.cmake we also
# declare common names for these variables that are more standard, ie, following the normal casing
# of the find_package system in general:
set(Freetype_FOUND True)

add_library(${Freetype_TARGETNAME} STATIC IMPORTED GLOBAL)
set_target_properties(${Freetype_TARGETNAME} PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C")
set_target_properties(${Freetype_TARGETNAME} PROPERTIES IMPORTED_LOCATION "${FREETYPE_LIBRARIES}")

# freetype depends on ZLIB, too, so if its not included already, we find and use it
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB)
    endif()
    find_package(ZLIB)
endif()
# anyone who links to freetype also links to ZLIB:
target_link_libraries(${Freetype_TARGETNAME} INTERFACE ZLIB::ZLIB)

# cmake < 3.21 and visual studio < 16.10 don't properly implement SYSTEM includes
# so we use O3DEs patched implementation if it is available and fallback to default if not.
# this is futureproof so that when O3DE no longer needs to define this and CMake's system 
# works without fixes, O3DE can erase this implementation and this script will still function.
if (COMMAND ly_target_include_system_directories)
    ly_target_include_system_directories(TARGET ${Freetype_TARGETNAME} INTERFACE ${FREETYPE_INCLUDE_DIRS})
else()
    target_include_directories(${Freetype_TARGETNAME} SYSTEM INTERFACE ${FREETYPE_INCLUDE_DIRS})
endif()

# alias the O3DE name to the official name:
add_library(${Freetype_O3DE_TARGETNAME} ALIAS ${Freetype_TARGETNAME})

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE's Freetype (${FREETYPE_VERSION_STRING}) from ${CMAKE_CURRENT_LIST_DIR}")
endif()

