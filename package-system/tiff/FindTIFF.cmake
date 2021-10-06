#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# TIFF depends on ZLIB.  For maximum compatibility here, we use the
# official ZLIB library name, ie, ZLIB::ZLIB and not o3de 3rdParty::ZLIB.
# O3DE's zlib package will define both.  If we're in O3DE we can also
# auto-download ZLIB.
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB REQUIRED MODULE)
    endif()
    find_package(ZLIB)
endif()

# note that all variables defined in find_package will apply in THIS scope
# which is why its a good idea to run them above before we do anything
#  or risk them overwriting our own variables like TARGET_WITH_NAMESPACE:

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::TIFF")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

# the following block sets the variables that are expected
# if you were to use the built-in CMake FindTIFF.cmake
set(TIFF_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/tiff/include)
set(TIFF_INCLUDE_DIR ${TIFF_INCLUDE_DIRS})
set(TIFF_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/tiff/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tiff${CMAKE_STATIC_LIBRARY_SUFFIX})
set(TIFF_LIBRARY ${TIFF_LIBRARIES})
set(TIFF_LIBRARY_RELEASE ${TIFF_LIBRARIES})
set(TIFF_LIBRARY_DEBUG ${TIFF_LIBRARIES})
set(TIFF_FOUND True)

set(TIFF_VERSION_STRING "4.2.0.15")
set(TIFF_VERSION_MAJOR "4")
set(TIFF_VERSION_MINOR "2")
set(TIFF_VERSION_PATCH "0")
set(TIFF_MAJOR_VERSION "4")
set(TIFF_MINOR_VERSION "2")
set(TIFF_PATCH_VERSION "0")
set(TIFF_CXX_FOUND 0) # we don't support TIFF_Cxx feature
set(TIFF_FOUND True)

# add the CMake standard TIFF::TIFF library.  It is a static library.
add_library(TIFF::TIFF STATIC IMPORTED GLOBAL)
set_target_properties(TIFF::TIFF PROPERTIES IMPORTED_LOCATION "${TIFF_LIBRARY}")


target_link_libraries(TIFF::TIFF INTERFACE ZLIB::ZLIB)

if (COMMAND ly_target_include_system_directories)
    # O3DE has an extension to fix system directory includes until CMake
    # has a proper fix for it, so if its available, use that:
    ly_target_include_system_directories(TARGET TIFF::TIFF INTERFACE ${TIFF_INCLUDE_DIRS})
else()
    # extension is not available (or not necessary anymore) 
    # so use default CMake SYSTEM include feature:
    target_include_directories(TIFF::TIFF SYSTEM INTERFACE ${TIFF_INCLUDE_DIRS})
endif()

# alias the TIFF library to the O3DE 3rdParty library
add_library(${TARGET_WITH_NAMESPACE} ALIAS TIFF::TIFF)

# if we're NOT in O3DE, it's also useful to show a message indicating that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using the O3DE version of the TIFF library from ${CMAKE_CURRENT_LIST_DIR}")
endif()
