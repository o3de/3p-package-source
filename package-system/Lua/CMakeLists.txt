#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.17)

project(lua C)

file(GLOB_RECURSE HDR_LIBLUA *.h)

ADD_LIBRARY ( lualib STATIC onelua.c )

# setting MAKE_LIB will make it create the static library.
# you can alternatively not define it and it will by default make the interpreter executable.
target_compile_definitions( lualib PRIVATE 
            MAKE_LIB)

set_target_properties(lualib
    PROPERTIES
        PUBLIC_HEADER "${HDR_LIBLUA}"
)

include(GNUInstallDirs)

install(TARGETS lualib
        PUBLIC_HEADER
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Lua
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/release
        RUNTIME
            DESTINATION ${CMAKE_INSTALL_BINDIR}/release
        ARCHIVE
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/release
)
