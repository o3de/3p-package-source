#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# CMake definition for Lua 5.3.5

cmake_minimum_required(VERSION 3.17)

PROJECT ( lua )

# Headers
SET(HDR_LIBLUA
    lapi.h
    lauxlib.h
    lcode.h
    lctype.h
    ldebug.h
    ldo.h
    lfunc.h
    lgc.h
    llex.h
    llimits.h
    lmem.h
    lobject.h
    lopcodes.h
    lparser.h
    lprefix.h
    lstate.h
    lstring.h
    ltable.h
    ltests.h
    ltm.h
    lua.h
    luaconf.h
    lualib.h
    lundump.h
    lvm.h
    lzio.h
)

# Build Libraries
SET(SRC_LIBLUA
    lapi.c
    lauxlib.c
    lbaselib.c
    lbitlib.c
    lcode.c
    lcorolib.c
    lctype.c
    ldblib.c
    ldebug.c
    ldo.c
    ldump.c
    lfunc.c
    lgc.c
    linit.c
    liolib.c
    llex.c
    lmathlib.c
    lmem.c
    loadlib.c
    lobject.c
    lopcodes.c
    loslib.c
    lparser.c
    lstate.c
    lstring.c
    lstrlib.c
    ltable.c
    ltablib.c
    ltests.c
    ltm.c
    lundump.c
    lutf8lib.c
    lvm.c
    lzio.c
)

LIST(APPEND SRC_LIBLUA ${HDR_LIBLUA})

#Library
ADD_LIBRARY ( lualib STATIC ${SRC_LIBLUA} )

TARGET_LINK_LIBRARIES (lualib)

target_include_directories( lualib PUBLIC include/ )

set_target_properties(lualib
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib/debug/"
        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib/release/"
        LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/lib/debug/"
        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib/release/"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin/debug/"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin/release/"
        PUBLIC_HEADER "${HDR_LIBLUA}"
)

include(GNUInstallDirs)

install(TARGETS lualib
        PUBLIC_HEADER
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Lua
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
        RUNTIME
            DESTINATION ${CMAKE_INSTALL_BINDIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
        ARCHIVE
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/$<$<CONFIG:Debug>:debug>$<$<CONFIG:Release>:release>
)
