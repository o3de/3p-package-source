#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# we build OpenImageIO statically.  This also means that all its dependencies
# are built statically, which means that if you want to link to OpenImageIO, you will need those
# dependencies too.   Unfortunately, OpenImageIO's install script and its own generated target
# files do not deploy these dependencies to install folder.
#   This file "patches" that by providing both OpenImageIO and its dependencies as targets.

# a useful message since it MUST APPEAR if this is working
message(STATUS "Using the internal FindOpenImageIO.cmake build file")

find_package(ZLIB MODULE REQUIRED)
find_package(OpenEXR MODULE REQUIRED)
# PNG::PNG - use the one from O3DE 3p
find_library(png_LIBRARY NAMES png libpng HINTS ${CMAKE_CURRENT_LIST_DIR}/../temp/dependencies/libpng-1.6.37-mac/libpng PATH_SUFFIXES lib64 lib)
add_library(PNG::PNG UNKNOWN IMPORTED GLOBAL)
set_target_properties(PNG::PNG PROPERTIES IMPORTED_LOCATION ${png_LIBRARY}
)
# where opencolorio itself was installed
set(OPENIMAGEIO_INSTALL_DIR ${CMAKE_CURRENT_LIST_DIR}/../temp/oiio_install)

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${OPENIMAGEIO_INSTALL_DIR}/lib/cmake")
# bring in OpenColorIO itself, using the above CMAKE_PREFIX_PATH
find_package(OpenImageIO CONFIG REQUIRED)


