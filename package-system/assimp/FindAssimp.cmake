#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# assimp depends on ZLIB.  For maximum compatibility here, we use the
# official ZLIB library name, ie, ZLIB::ZLIB and not o3de 3rdParty::ZLIB.
# O3DE's zlib package will define both.  If we're in O3DE we can also
# auto-download ZLIB.
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB REQUIRED MODULE)
    endif()
    find_package(ZLIB)
endif()

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::assimplib")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(LIB_NAME "assimp")

set(${LIB_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/assimp/include)
set(${LIB_NAME}_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/assimp/bin)
set(${LIB_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/assimp/lib)

if (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/linux/libassimp.so.5.0.1)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/linux/libassimp.so.5.0.1)
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/linux/release/libassimp.a)
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/linux/release/libassimp.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/mac/libassimp.5.0.1.dylib)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/mac/libassimp.5.0.1.dylib)
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/mac/release/libassimp.a)
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/mac/release/libassimp.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${LIB_NAME}_LIBRARY_DEBUG   ${${LIB_NAME}_BIN_DIR}/win_x64/debug/assimp-vc142-mtd.dll)
    set(${LIB_NAME}_LIBRARY_RELEASE ${${LIB_NAME}_BIN_DIR}/win_x64/release/assimp-vc142-mt.dll)
    set(${LIB_NAME}_STATIC_LIBRARY_DEBUG   ${${LIB_NAME}_LIBS_DIR}/win_x64/debug/assimp-vc142-mtd.lib)
    set(${LIB_NAME}_STATIC_LIBRARY_RELEASE ${${LIB_NAME}_LIBS_DIR}/win_x64/release/assimp-vc142-mt.lib)
endif()

# set it to a generator expression for multi-config situations
set(${LIB_NAME}_DYNLIB $<IF:$<CONFIG:Debug>,${${LIB_NAME}_LIBRARY_DEBUG},${${LIB_NAME}_LIBRARY_RELEASE}>)

# Order of linking is not enforced by target_link_libraries  on some compilers
# To workaround this problem, we wrap the static lib in an imported lib and mark the dependency there. That makes
# the DAG algorithm to sort them in the order we need.
add_library(${TARGET_WITH_NAMESPACE}::imported STATIC IMPORTED)

set_target_properties(${TARGET_WITH_NAMESPACE}::imported
    PROPERTIES
        IMPORTED_LOCATION_DEBUG ${${LIB_NAME}_STATIC_LIBRARY_DEBUG}
        IMPORTED_LOCATION_PROFILE ${${LIB_NAME}_STATIC_LIBRARY_RELEASE}
        IMPORTED_LOCATION_RELEASE ${${LIB_NAME}_STATIC_LIBRARY_RELEASE}
)
target_link_libraries(${TARGET_WITH_NAMESPACE}::imported
                            INTERFACE 3rdParty::zlib
)

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})
set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
    INTERFACE_IMPORTED_LOCATION "${${LIB_NAME}_DYNLIB}"
)
target_link_libraries(${TARGET_WITH_NAMESPACE}
                            INTERFACE ${TARGET_WITH_NAMESPACE}::imported
)

set(3RDPARTY_ASSIMP_RUNTIME_DEPENDENCIES "${${LIB_NAME}_DYNLIB}")

# install Python bindings to AssImp (i.e. PyAssImp)
ly_pip_install_local_package_editable(${CMAKE_CURRENT_LIST_DIR}/assimp/port/PyAssimp pyassimp)

set(${LIB_NAME}_FOUND True)
