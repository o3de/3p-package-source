#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# we build OpenColorIO statically.  This also means that all its dependencies
# are built statically, which means that if you want to link to OpenColorIO, you will need those
# dependencies too.   Unfortunately, OpenColorIO's install script and its own generated target
# files do not declare these dependencies.   This file "patches" that by providing both OpenColorIO
# and its dependencies.

# this is only for use during building of OpenImageIO.
# it assumes that there is an OpenColorIO 'install' folder relative to this one.

# a useful message since it MUST APPEAR if this is working
message(STATUS "Using the internal FindOpenColorIO.cmake build file")

# where opencolorio itself was installed
set(PYSTRING_INSTALL_PATH ${CMAKE_CURRENT_LIST_DIR}/../temp/pystring_install)
set(YAMLCPP_INSTALL_PATH ${CMAKE_CURRENT_LIST_DIR}/../temp/yaml-cpp_install)
set(OPENCOLORIO_INSTALL_PATH ${CMAKE_CURRENT_LIST_DIR}/../temp/ocio_install)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${OPENCOLORIO_INSTALL_PATH}/lib/cmake")
# bring in OpenColorIO itself, using the above CMAKE_PREFIX_PATH
find_package(OpenColorIO CONFIG REQUIRED)

# declare its dependencies, too.  Specifically, If you depend on OpenColorIO you also need
# pystring::pystring
# sampleicc::sampleicc
# utils::strings
# yaml-cpp (note, no namespace!)

# sampleicc and utils::strings are set as deps but only need to exist to satisfy cmake:
add_library(sampleicc::sampleicc INTERFACE IMPORTED GLOBAL)
add_library(utils::strings INTERFACE IMPORTED GLOBAL)
add_library(utils::from_chars INTERFACE IMPORTED GLOBAL)

# the following is expected to pick up O3DE's expat.
find_package(expat 2.2.8 REQUIRED)

# pystring::pystring - use the one built by OpenColorIO
find_library(pystring_LIBRARY NAMES pystring libpystring HINTS ${PYSTRING_INSTALL_PATH} PATH_SUFFIXES lib64 lib)
add_library(pystring::pystring UNKNOWN IMPORTED GLOBAL)
set_target_properties(pystring::pystring PROPERTIES IMPORTED_LOCATION ${pystring_LIBRARY}
)

# yaml-cpp - use the one built by OpenColorIO
find_library(yaml_cpp_LIBRARY NAMES libyaml-cpp yaml-cpp HINTS ${YAMLCPP_INSTALL_PATH} PATH_SUFFIXES lib64 lib)
add_library(yaml-cpp UNKNOWN IMPORTED GLOBAL)
set_target_properties(yaml-cpp PROPERTIES IMPORTED_LOCATION ${yaml_cpp_LIBRARY}
)

# On Windows only, we need to make sure that this is built statically
# and anything linking against OpenColorIO will link statically as well
if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    target_compile_definitions(OpenColorIO::OpenColorIO
        INTERFACE
            OpenColorIO_SKIP_IMPORTS
    )
endif()
