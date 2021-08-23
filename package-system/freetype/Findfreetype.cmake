#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
