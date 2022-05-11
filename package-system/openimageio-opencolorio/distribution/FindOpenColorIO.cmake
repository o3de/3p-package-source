#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if (TARGET 3rdParty::OpenColorIO)
    return()
endif()

if (NOT TARGET Imath::Imath)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(Imath)
    endif()
    find_package(Imath REQUIRED MODULE)
endif()

set(OpenColorIO_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/include)
set(OpenColorIO_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/lib)
set(OpenColorIO_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/bin)
set(OpenColorIO_FOUND True)
set(OpenColorIO_VERSION "2.1.1")

add_library(OpenColorIO::OpenColorIO STATIC IMPORTED GLOBAL)
set_target_properties(OpenColorIO::OpenColorIO PROPERTIES 
    IMPORTED_LOCATION ${OpenColorIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenColorIO${CMAKE_STATIC_LIBRARY_SUFFIX}
    INTERFACE_COMPILE_DEFINITIONS "OIIO_STATIC_DEFINE=1"
)

# windows has Debug libraries available.
if (${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set_target_properties(OpenColorIO::OpenColorIO PROPERTIES 
    IMPORTED_LOCATION_DEBUG ${OpenColorIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenColorIO${CMAKE_STATIC_LIBRARY_SUFFIX})

    # On Windows the yaml lib is built with an extra "md" suffix
    set(_yaml-cpp_LIB_SUFFIX "md")
endif()


target_link_libraries(OpenColorIO::OpenColorIO INTERFACE 
    Imath::Imath
    # private dependencies that we intentionally DO NOT WANT to create friendly targets for:
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/pystring/lib/${CMAKE_STATIC_LIBRARY_PREFIX}pystring${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${CMAKE_CURRENT_LIST_DIR}/privatedeps/yaml-cpp/lib/libyaml-cpp${_yaml-cpp_LIB_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}
)

if (COMMAND ly_target_include_system_directories)
    # O3DE has an extension to fix system directory includes until CMake
    # has a proper fix for it, so if its available, use that:
    ly_target_include_system_directories(TARGET OpenColorIO::OpenColorIO INTERFACE ${OpenColorIO_INCLUDE_DIR})
else()
    # extension is not available (or not necessary anymore) 
    # so use default CMake SYSTEM include feature:
    target_include_directories(OpenColorIO::OpenColorIO SYSTEM INTERFACE ${OpenColorIO_INCLUDE_DIR})
endif()

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(OpenColorIO_RUNTIME_DEPENDENCIES
        ${OpenColorIO_BIN_DIR}/ociobakelut.exe
        ${OpenColorIO_BIN_DIR}/ociocheck.exe
        ${OpenColorIO_BIN_DIR}/ociochecklut.exe
        ${OpenColorIO_BIN_DIR}/ocioconvert.exe
        ${OpenColorIO_BIN_DIR}/ociolutimage.exe
        ${OpenColorIO_BIN_DIR}/ociomakeclf.exe
        ${OpenColorIO_BIN_DIR}/ocioperf.exe
        ${OpenColorIO_BIN_DIR}/ociowrite.exe

        ${OpenColorIO_LIB_DIR}/site-packages/PyOpenColorIO.pyd
    )
else()
    # TODO: Do darwin/linux have any ocio executables we need to add?
    #   If so, do we actually need to add them as targets? If not, we can just
    #   have a single .pyd as the runtime dependency that would be the same on all platforms
    set(OpenColorIO_RUNTIME_DEPENDENCIES
        ${OpenColorIO_LIB_DIR}/site-packages/PyOpenColorIO.pyd
    )
endif()

if (COMMAND ly_add_target_files)
    ly_add_target_files(TARGETS OpenColorIO::OpenColorIO FILES ${OpenColorIO_RUNTIME_DEPENDENCIES})
endif()

# alias the OpenColorIO library to the O3DE 3rdParty library
add_library(3rdParty::OpenColorIO ALIAS OpenColorIO::OpenColorIO)

# if we're NOT in O3DE, it's also useful to show a message indicating that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE OpenColorIO ${OpenColorIO_VERSION} from ${CMAKE_CURRENT_LIST_DIR}")
endif()
