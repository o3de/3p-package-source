#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
if (TARGET 3rdParty::OpenImageIO)
    return()
endif()

# OpenImageIO depends on OpenColorIO.  This package includes it!
find_package(OpenColorIO)

if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        # if we happen to be inside O3DE we can use its package system to grab ZLIB.
        ly_download_associated_package(ZLIB)
    endif()
    find_package(ZLIB)
endif()

# todo: FIX THIS
if (NOT TARGET PNG::PNG)
    set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_LIST_DIR}/../dependencies/libpng-1.6.37-mac/libpng;${CMAKE_PREFIX_PATH}")
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(PNG)
    endif()
    find_package(PNG MODULE)
endif()

if (NOT TARGET Imath::Imath)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(Imath)
    endif()
    find_package(Imath)
endif()


if (NOT TARGET Freetype::Freetype)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(Freetype)
    endif()
    find_package(Freetype)
endif()

if (NOT TARGET OpenEXR::OpenEXR)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(OpenEXR)
    endif()
    find_package(OpenEXR)
endif()

if (NOT TARGET TIFF::TIFF)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(TIFF)
    endif()
    find_package(TIFF)
endif()


if (NOT TARGET expat::expat)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(expat)
    endif()
    find_package(expat)
endif()

find_package(expat)

# the following block sets the variables that are expected
# if you were to use the built-in CMake FindOpenImageIO.cmake
set(OpenImageIO_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenImageIO/include)
set(OpenImageIO_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenImageIO/lib)
set(OpenImageIO_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenImageIO/bin)
set(OpenImageIO_VERSION "4.2.0.15")
set(OpenImageIO_FOUND True)

add_library(OpenImageIO::OpenImageIO_Util STATIC IMPORTED GLOBAL)
set_target_properties(OpenImageIO::OpenImageIO_Util PROPERTIES 
    IMPORTED_LOCATION ${OpenImageIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenImageIO_Util${CMAKE_STATIC_LIBRARY_SUFFIX})

add_library(OpenImageIO::OpenImageIO STATIC IMPORTED GLOBAL)
set_target_properties(OpenImageIO::OpenImageIO PROPERTIES
    INTERFACE_COMPILE_DEFINITIONS "OIIO_STATIC_DEFINE=1"
    IMPORTED_LOCATION ${OpenImageIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenImageIO${CMAKE_STATIC_LIBRARY_SUFFIX})

target_link_libraries(OpenImageIO::OpenImageIO INTERFACE 
    expat::expat
    OpenImageIO::OpenImageIO_Util
    OpenColorIO::OpenColorIO
    Imath::Imath
    PNG::PNG
    TIFF::TIFF
    OpenEXR::OpenEXR
    OpenEXR::OpenEXRCore
    OpenEXR::OpenEXRUtil
    ZLIB::ZLIB
    Freetype::Freetype
    # private dependencies that we intentionally DO NOT WANT to create friendly targets for:
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_atomic.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_chrono.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_date_time.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_filesystem.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_system.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/Boost/lib/libboost_thread.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/LibJPEGTurbo/lib/libturbojpeg.a
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/LibJPEGTurbo/lib/libjpeg.a
    "-framework Carbon"
    "-framework IOKit"
)

if (COMMAND ly_target_include_system_directories)
    # O3DE has an extension to fix system directory includes until CMake
    # has a proper fix for it, so if its available, use that:
    ly_target_include_system_directories(TARGET OpenImageIO::OpenImageIO INTERFACE ${OpenImageIO_INCLUDE_DIR})
else()
    # extension is not available (or not necessary anymore) 
    # so use default CMake SYSTEM include feature:
    target_include_directories(OpenImageIO::OpenImageIO SYSTEM INTERFACE ${OpenImageIO_INCLUDE_DIR})
endif()

# alias the OpenImageIO library to the O3DE 3rdParty library
add_library(3rdParty::OpenImageIO ALIAS OpenImageIO::OpenImageIO)
add_library(3rdParty::OpenImageIO_Util ALIAS OpenImageIO::OpenImageIO_Util)

# if we're NOT in O3DE, it's also useful to show a message indicating that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using the O3DE version of the OpenImageIO library from ${CMAKE_CURRENT_LIST_DIR}")
endif()

# OpenImageIO Also includes a number of executables, as well as a python module.
