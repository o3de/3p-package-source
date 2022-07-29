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

if (NOT TARGET expat::expat)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(expat)
    endif()
    find_package(expat REQUIRED MODULE)
endif()

set(OpenColorIO_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/include)
set(OpenColorIO_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/lib)
set(OpenColorIO_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/OpenColorIO/bin)
set(OpenColorIO_FOUND True)
set(OpenColorIO_VERSION "2.1.1")

# On Windows, the shared libraries are under the bin directory,
# but on Linux/Darwin they are still under the lib directory
# Also, on Windows only the OpenColorIO library has a version suffix
if (${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set(OpenColorIO_SHARED_LIB_DIR ${OpenColorIO_BIN_DIR})
    set(_OCIO_VERSION_SUFFIX "_2_1")
else()
    set(OpenColorIO_SHARED_LIB_DIR ${OpenColorIO_LIB_DIR})
    set(_OCIO_VERSION_SUFFIX "")
endif()
set(OpenColorIO_SHARED_LIB ${OpenColorIO_SHARED_LIB_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}OpenColorIO${_OCIO_VERSION_SUFFIX}${CMAKE_SHARED_LIBRARY_SUFFIX})

# We need to make all the shared libraries available as runtime dependencies
# On Windows, there's only the single shared library (.dll)
# On Linux/Darwin, we need to account for all the versioned shared libraries
if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(OpenColorIO_SHARED_LIBS ${OpenColorIO_SHARED_LIB})
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(OpenColorIO_SHARED_LIBS
        ${OpenColorIO_SHARED_LIB}
        ${OpenColorIO_SHARED_LIB}.2.1
        ${OpenColorIO_SHARED_LIB}.2.1.1
    )
else() # Darwin
    set(OpenColorIO_SHARED_LIBS
        ${OpenColorIO_SHARED_LIB}
        ${OpenColorIO_SHARED_LIB_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}OpenColorIO.2.1${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${OpenColorIO_SHARED_LIB_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}OpenColorIO.2.1.1${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
endif()

add_library(OpenColorIO::OpenColorIO SHARED IMPORTED GLOBAL)
set_target_properties(OpenColorIO::OpenColorIO PROPERTIES
    IMPORTED_LOCATION ${OpenColorIO_SHARED_LIB}
)

# windows has Debug libraries available.
if (${CMAKE_SYSTEM_NAME} STREQUAL Windows)
    set(_OCIO_DEBUG_POSTFIX "")
    if ("${CMAKE_BUILD_TYPE}" STREQUAL Debug)
        set(_OCIO_DEBUG_POSTFIX "d")
        set(OpenColorIO_SHARED_LIB_DEBUG ${OpenColorIO_BIN_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}OpenColorIO${_OCIO_DEBUG_POSTFIX}_2_1${CMAKE_SHARED_LIBRARY_SUFFIX})

        set_target_properties(OpenColorIO::OpenColorIO PROPERTIES
            IMPORTED_LOCATION_DEBUG ${OpenColorIO_SHARED_LIB_DEBUG}
            IMPORTED_IMPLIB_DEBUG ${OpenColorIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenColorIO${_OCIO_DEBUG_POSTFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}
        )
    endif()

    set_target_properties(OpenColorIO::OpenColorIO PROPERTIES
        IMPORTED_IMPLIB ${OpenColorIO_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}OpenColorIO${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
endif()

target_link_libraries(OpenColorIO::OpenColorIO INTERFACE 
    Imath::Imath
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

# On Windows, the python bindings are in a pyd
# On Linux/Darwin, they are in an so and a different path as well
if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    set(OpenColorPythonBindings ${OpenColorIO_LIB_DIR}/site-packages/PyOpenColorIO.pyd)
else()
    set(OpenColorPythonBindings ${OpenColorIO_LIB_DIR}/python3.10/site-packages/PyOpenColorIO.so)
endif()

set(OpenColorIO_TOOLS_BINARIES
    ${OpenColorIO_BIN_DIR}/ociobakelut${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ociocheck${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ociochecklut${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ocioconvert${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ociolutimage${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ociomakeclf${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ocioperf${CMAKE_EXECUTABLE_SUFFIX}
    ${OpenColorIO_BIN_DIR}/ociowrite${CMAKE_EXECUTABLE_SUFFIX}
)

add_library(OpenColorIO::OpenColorIO::Runtime INTERFACE IMPORTED GLOBAL)
add_library(OpenColorIO::OpenColorIO::Tools::Binaries INTERFACE IMPORTED GLOBAL)
add_library(OpenColorIO::OpenColorIO::Tools::PythonPlugins INTERFACE IMPORTED GLOBAL)
if (COMMAND ly_add_target_files)
    ly_add_target_files(TARGETS OpenColorIO::OpenColorIO FILES ${OpenColorIO_SHARED_LIBS})

    if (${CMAKE_SYSTEM_NAME} STREQUAL Windows AND "${CMAKE_BUILD_TYPE}" STREQUAL Debug)
        ly_add_target_files(TARGETS OpenColorIO::OpenColorIO FILES ${OpenColorIO_SHARED_LIB_DEBUG})
    endif()

    ly_add_target_files(TARGETS OpenColorIO::OpenColorIO::Runtime FILES
        ${OpenColorIO_SHARED_LIBS}
    )
    ly_add_target_files(TARGETS OpenColorIO::OpenColorIO::Tools::Binaries FILES
        ${OpenColorIO_TOOLS_BINARIES}
    )
    ly_add_target_files(TARGETS OpenColorIO::OpenColorIO::Tools::PythonPlugins FILES
        ${OpenColorPythonBindings}
    )
endif()

# Make sure our tools get the runtime dependency (shared library)
target_link_libraries(OpenColorIO::OpenColorIO::Tools::Binaries INTERFACE
    OpenColorIO::OpenColorIO::Runtime
)
target_link_libraries(OpenColorIO::OpenColorIO::Tools::PythonPlugins INTERFACE
    OpenColorIO::OpenColorIO::Runtime
)

# alias the OpenColorIO library to the O3DE 3rdParty library
add_library(3rdParty::OpenColorIO ALIAS OpenColorIO::OpenColorIO)
add_library(3rdParty::OpenColorIO::Runtime ALIAS OpenColorIO::OpenColorIO::Runtime)
add_library(3rdParty::OpenColorIO::Tools::Binaries ALIAS OpenColorIO::OpenColorIO::Tools::Binaries)
add_library(3rdParty::OpenColorIO::Tools::PythonPlugins ALIAS OpenColorIO::OpenColorIO::Tools::PythonPlugins)

# if we're NOT in O3DE, it's also useful to show a message indicating that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE OpenColorIO ${OpenColorIO_VERSION} from ${CMAKE_CURRENT_LIST_DIR}")
endif()
