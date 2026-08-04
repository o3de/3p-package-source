#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Compatibility with old scripts that use global variables.
set(yaml-cpp_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/yaml-cpp/include)
set(yaml-cpp_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/yaml-cpp/lib)
set(yaml-cpp_VERSION_STRING "0.9.0")
set(yaml-cpp_VERSION ${yaml-cpp_VERSION_STRING})
set(yaml-cpp_FOUND True)

# Compatibility with newer scripts that use targets
if (NOT TARGET yaml-cpp)
    add_library(yaml-cpp STATIC IMPORTED GLOBAL)
    set_target_properties(yaml-cpp 
        PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
        INTERFACE_COMPILE_DEFINITIONS YAML_CPP_STATIC_DEFINE
        IMPORTED_LOCATION ${yaml-cpp_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set_target_properties(yaml-cpp 
        PROPERTIES
        IMPORTED_LOCATION_DEBUG ${yaml-cpp_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp_d${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    endif()
    target_include_directories(yaml-cpp SYSTEM INTERFACE ${yaml-cpp_INCLUDE_DIRS})
    
endif()

if (NOT TARGET 3rdParty::yaml-cpp)
    add_library(3rdParty::yaml-cpp ALIAS yaml-cpp)
endif()

if (NOT TARGET yaml-cpp::yaml-cpp)
    add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
endif()

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE's yaml-cpp (${yaml-cpp_VERSION_STRING}) from ${CMAKE_CURRENT_LIST_DIR}")
endif()

