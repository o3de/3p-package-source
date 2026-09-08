#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "SQLite")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

if (LY_SYSTEM_PACKAGE_${MY_NAME})

    find_package(SQLite3)
    if (NOT SQLite3_FOUND)
        message(FATAL_ERROR "LY_SYSTEM_PACKAGE_${MY_NAME} specified but development files for ${MY_NAME} not found.")
    else()
        set_target_properties(SQLite::SQLite3 PROPERTIES LY_SYSTEM_LIBRARY TRUE)
        add_library(${TARGET_WITH_NAMESPACE} ALIAS SQLite::SQLite3)
        set(${MY_NAME}_FOUND True)
    endif()

else()

    set(${MY_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/SQLite)
    set(${MY_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/SQLite/lib)
    set(${MY_NAME}_LIBRARY ${${MY_NAME}_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}sqlite3${CMAKE_STATIC_LIBRARY_SUFFIX})
    
    add_library(${TARGET_WITH_NAMESPACE} STATIC IMPORTED GLOBAL)
    
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES IMPORTED_LOCATION "${${MY_NAME}_LIBRARY}")
    
    ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
    
    target_link_libraries(${TARGET_WITH_NAMESPACE} 
                          INTERFACE ${CMAKE_DL_LIBS})
    
    set(${MY_NAME}_FOUND True)

endif()
