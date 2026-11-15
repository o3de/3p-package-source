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
set(Python_HOME "${CMAKE_CURRENT_LIST_DIR}/python/Python.framework/Versions/3.15")
set(Python_EXECUTABLE "${Python_HOME}/bin/python3")
set(Python_PATHS
    "${Python_HOME}/lib"
    "${Python_HOME}/lib/python3.15"
    "${Python_HOME}/lib/python3.15/lib-dynload"
    "${Python_HOME}/lib/python3.15/site-packages"
)

set(Python_FOUND TRUE)
if(NOT PAL_PLATFORM_NAME STREQUAL "Mac")
    return()
endif()

set(Python_Development_FOUND TRUE)
set(Python_INCLUDE_DIR "${Python_HOME}/Headers")
set(Python_LIBRARY "${Python_HOME}/Python")
set(Python_DYLIBS "${Python_LIBRARY}")
set(Python_COMPILE_DEFINITIONS DEFAULT_LY_PYTHONHOME="${Python_HOME}")

add_library(3rdParty::Python INTERFACE IMPORTED GLOBAL)
add_library(3rdParty::python ALIAS 3rdParty::Python)
ly_target_include_system_directories(TARGET 3rdParty::Python INTERFACE "${Python_INCLUDE_DIR}")
target_link_libraries(3rdParty::Python INTERFACE "${Python_LIBRARY}")
target_compile_definitions(3rdParty::Python INTERFACE "${Python_COMPILE_DEFINITIONS}")

set_target_properties(3rdParty::Python PROPERTIES
    INTERFACE_IMPORTED_LOCATION "${Python_DYLIBS}"
)
