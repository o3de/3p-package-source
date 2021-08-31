#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file is provided to give compatibility to non-o3de-projects
# it defines the same targets as is defined in the default FindZLIB.cmake
# shipped with CMAKE.
# Its meant to be deployed into the zlib subfolder of the package
# and then allows you set the variable ZLIB_ROOT on the command line to point at this folder,
# to force it to use this package instead of system ZLIB.

set(ZLIB_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/include)
set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS})
set(ZLIB_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/lib/zlibstatic.lib)
set(ZLIB_LIBRARY ${ZLIB_LIBRARIES})
set(ZLIB_FOUND True)
set(ZLIB_VERSION_STRING "1.2.11")
set(ZLIB_VERSION_MAJOR "1")
set(ZLIB_VERSION_MINOR "2")
set(ZLIB_VERSION_PATCH "11")
set(ZLIB_MAJOR_VERSION "1")
set(ZLIB_MINOR_VERSION "2")
set(ZLIB_PATCH_VERSION "11")

add_library(ZLIB::ZLIB INTERFACE IMPORTED GLOBAL)
set_target_properties(ZLIB::ZLIB PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIRS}")
target_link_libraries(ZLIB::ZLIB INTERFACE ${ZLIB_LIBRARIES})
