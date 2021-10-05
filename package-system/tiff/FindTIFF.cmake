#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::tiff")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(TIFF_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/tiff/include)
set(TIFF_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/tiff/lib)
set(TIFF_CXX_FOUND 0)

set(TIFF_LIBRARY_RELEASE ${TIFF_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}tiff${CMAKE_STATIC_LIBRARY_SUFFIX})
set(TIFF_LIBRARY_DEBUG ${TIFF_LIBRARY_RELEASE})

# we set it to a generator expression for multi-config situations:
set(TIFF_LIBRARY                  "$<$<CONFIG:profile>:${TIFF_LIBRARY_RELEASE}>")
set(TIFF_LIBRARY ${TIFF_LIBRARY} "$<$<CONFIG:Release>:${TIFF_LIBRARY_RELEASE}>")
set(TIFF_LIBRARY ${TIFF_LIBRARY} "$<$<CONFIG:Debug>:${TIFF_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${TIFF_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${TIFF_LIBRARY})

set(TIFF_FOUND True)
