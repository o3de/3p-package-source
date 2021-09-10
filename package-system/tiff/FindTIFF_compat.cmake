#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file is provided to give compatibility to non-o3de-projects
# it defines the same targets as is defined in the default FindTIFF.cmake
# shipped with CMAKE.
# Its meant to be deployed into the zlib subfolder of the package
# and then allows you set the variable TIFF_ROOT on the command line to point at this folder,
# to force it to use this package instead of system TIFF. 

set(TIFF_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/include)
set(TIFF_INCLUDE_DIR ${TIFF_INCLUDE_DIRS})
set(TIFF_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tiff${CMAKE_STATIC_LIBRARY_SUFFIX})
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

add_library(TIFF::TIFF INTERFACE IMPORTED GLOBAL)
set_target_properties(TIFF::TIFF PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${TIFF_INCLUDE_DIRS}")
target_link_libraries(TIFF::TIFF INTERFACE ${TIFF_LIBRARIES})
