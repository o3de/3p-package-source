#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::SQLite")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(MY_NAME "SQLite")

set(${MY_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/SQLite)
set(${MY_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/SQLite/lib)

set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/debug/${CMAKE_STATIC_LIBRARY_PREFIX}sqlite3${CMAKE_STATIC_LIBRARY_SUFFIX})
set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/release/${CMAKE_STATIC_LIBRARY_PREFIX}sqlite3${CMAKE_STATIC_LIBRARY_SUFFIX})

# we set it to a generator expression for multi-config situations:
set(${MY_NAME}_LIBRARY  
    "$<$<CONFIG:profile>:${${MY_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:Release>:${${MY_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:Debug>:${${MY_NAME}_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)
set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION "${${MY_NAME}_LIBRARY_RELEASE}")
set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION_DEBUG "${${MY_NAME}_LIBRARY_DEBUG}")

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} 
                      INTERFACE ${CMAKE_DL_LIBS})

set(${MY_NAME}_FOUND True)
