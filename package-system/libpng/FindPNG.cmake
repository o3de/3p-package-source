#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# PNG depends on ZLIB.  For maximum compatibility here, we use the
# official ZLIB library name, ie, ZLIB::ZLIB and not O3DE 3rdParty::ZLIB.
# O3DE's zlib package will define both.  If we're in O3DE we can also
# auto-download ZLIB.
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB REQUIRED MODULE)
    endif()
    find_package(ZLIB)
endif()

# note that this file follows the conventions set by CMake's own 
# FindPNG.cmake file.  So the variables declared in it will satisfy
# as a drop in replacement for the original FindPNG.cmake from the
# CMake package.  See https://cmake.org/cmake/help/latest/module/FindPNG.html

set(PNG_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/png/include)
set(PNG_LIB_DIRS ${CMAKE_CURRENT_LIST_DIR}/png/lib)

if (WIN32)
    set(PNG_LIBRARIES ${PNG_LIB_DIRS}/libpng16_static${CMAKE_STATIC_LIBRARY_SUFFIX})
else()
    set(PNG_LIBRARIES ${PNG_LIB_DIRS}/${CMAKE_STATIC_LIBRARY_PREFIX}png16${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

set(PNG_VERSION_STRING "1.6.37")

add_library(PNG::PNG STATIC IMPORTED GLOBAL)
set_target_properties(PNG::PNG PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C")
set_target_properties(PNG::PNG PROPERTIES IMPORTED_LOCATION ${PNG_LIBRARIES})

if (COMMAND ly_target_include_system_directories)
    # inside the O3DE ecosystem, this macro makes sure it works even in cmake < 3.19
    ly_target_include_system_directories(TARGET PNG::PNG INTERFACE ${PNG_INCLUDE_DIRS})
else()
    # outside the O3DE ecosystem, we do our best...
    target_include_directories(PNG::PNG SYSTEM INTERFACE ${PNG_INCLUDE_DIRS})
endif()

# quietly see if we need to link to libm for pow().  some systems need this, some don't.
set(ADDITIONAL_SYSTEM_LIB_DEPENDENCIES "")

function(check_if_libm_required output_variable_name) # function scope so that any changes to the environment are reverted
    include(CheckLibraryExists)
    set(CMAKE_REQUIRED_QUIET TRUE)
    check_library_exists(m pow "" LIBM CMAKE_REQUIRED_QUIET)
    if(LIBM)
        set(${output_variable_name} "m" PARENT_SCOPE)
    endif()
endfunction()

check_if_libm_required(ADDITIONAL_SYSTEM_LIB_DEPENDENCIES)

target_link_libraries(PNG::PNG INTERFACE ZLIB::ZLIB ${ADDITIONAL_SYSTEM_LIB_DEPENDENCIES})

# now that PNG::PNG is fully defined, alias it to 3rdParty::PNG for O3DE:
add_library(3rdParty::PNG ALIAS PNG::PNG)

set(PNG_FOUND TRUE)
# if we're NOT in O3DE, it's also useful to show a message indicating that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using the O3DE version of the PNG library from ${CMAKE_CURRENT_LIST_DIR}")
endif()
