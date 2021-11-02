#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::freetype")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(freetype_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/freetype/include/freetype2)
set(freetype_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/freetype/lib)
set(freetype_LIBRARY ${freetype_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}freetype$<IF:$<CONFIG:Debug>,d,>${CMAKE_STATIC_LIBRARY_SUFFIX})

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${freetype_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${freetype_LIBRARY})

set(freetype_FOUND True)
