#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

if(TARGET 3rdParty::Python)
    return()
endif()

set(Python_VERSION 3.15.2)
set(Python_INTERPRETER_ID "Python")
set(Python_HOME "${CMAKE_CURRENT_LIST_DIR}/python")
set(Python_EXECUTABLE "${Python_HOME}/python.exe")
set(Python_PATHS
    "${Python_HOME}/Lib"
    "${Python_HOME}/Lib/site-packages"
    "${Python_HOME}/DLLs"
)

set(Python_FOUND TRUE)
if(NOT PAL_PLATFORM_NAME STREQUAL "Windows")
    return()
endif()

set(Python_Development_FOUND TRUE)
set(Python_INCLUDE_DIR "${Python_HOME}/include")
set(Python_LIBRARY_DEBUG "${Python_HOME}/libs/python315_d.lib")
set(Python_LIBRARY_RELEASE "${Python_HOME}/libs/python315.lib")
set(Python_DYLIBS_DEBUG
    "${Python_HOME}/python315_d.dll"
    "${Python_HOME}/python3_d.dll"
    "${Python_HOME}/python315_d.pdb"
    "${Python_HOME}/python3_d.pdb"
)
set(Python_DYLIBS_RELEASE
    "${Python_HOME}/python315.dll"
    "${Python_HOME}/python3.dll"
    "${Python_HOME}/python315.pdb"
    "${Python_HOME}/python3.pdb"
)
set(Python_LIBRARY "$<IF:$<CONFIG:Debug>,${Python_LIBRARY_DEBUG},${Python_LIBRARY_RELEASE}>")
set(Python_DYLIBS "$<IF:$<CONFIG:Debug>,${Python_DYLIBS_DEBUG},${Python_DYLIBS_RELEASE}>")
set(Python_COMPILE_DEFINITIONS DEFAULT_LY_PYTHONHOME="${Python_HOME}")

add_library(3rdParty::Python INTERFACE IMPORTED GLOBAL)
add_library(3rdParty::python ALIAS 3rdParty::Python)
ly_target_include_system_directories(TARGET 3rdParty::Python INTERFACE "${Python_INCLUDE_DIR}")
target_link_libraries(3rdParty::Python INTERFACE "${Python_LIBRARY}")
target_compile_definitions(3rdParty::Python INTERFACE "${Python_COMPILE_DEFINITIONS}")

set_target_properties(3rdParty::Python PROPERTIES
    INTERFACE_IMPORTED_LOCATION "${Python_DYLIBS}"
)
