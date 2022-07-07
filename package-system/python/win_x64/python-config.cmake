#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file actually ingests the library and defines targets.
set(MY "Python")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

# this FindPython file is designed to be compatible with the base FindPython
# to at least some degree.  As such, it uses the same variable names:

# this script defines:
# Python_EXECUTABLE - full path to executable
# Python_INTERPRETER_ID - "Python"
# Python_HOME - Where the python folder root is (ie, folder has subfolder of 'Lib')
# Python_PATHS - Where sys.path should point at to find modules, libraries, etc.
# Python_Development_FOUND - The platform we are cross compiling for can link to python
# and a target called 3rdParty::Python that you can use to depend on

set(${MY}_VERSION 3.10.5)
set(${MY}_INTERPRETER_ID    "Python")
set(${MY}_EXECUTABLE        ${CMAKE_CURRENT_LIST_DIR}/python/python.exe)
set(${MY}_HOME              ${CMAKE_CURRENT_LIST_DIR}/python)
set(${MY}_PATHS             ${CMAKE_CURRENT_LIST_DIR}/python/Lib
                            ${CMAKE_CURRENT_LIST_DIR}/python/Lib/site-packages
                            ${CMAKE_CURRENT_LIST_DIR}/python/DLLs) 

# only if we're compiling FOR on one of the available platforms, add the target and libraries:
if (${PAL_PLATFORM_NAME} STREQUAL "Windows" )
    set(${MY}_Development_FOUND TRUE)
    # Do not use these  PYTHON_LIBRARY_* or other variables, instead, use the 
    # target '3rdParty::Python'
    set(${MY}_LIBRARY_DEBUG   ${CMAKE_CURRENT_LIST_DIR}/python/libs/python310_d.lib)
    set(${MY}_LIBRARY_RELEASE ${CMAKE_CURRENT_LIST_DIR}/python/libs/python310.lib)
    set(${MY}_INCLUDE_DIR     ${CMAKE_CURRENT_LIST_DIR}/python/include)
    set(${MY}_DYLIBS_DEBUG    ${CMAKE_CURRENT_LIST_DIR}/python/python310_d.dll ${CMAKE_CURRENT_LIST_DIR}/python/python310_d.dll
                              ${CMAKE_CURRENT_LIST_DIR}/python/python310_d.pdb ${CMAKE_CURRENT_LIST_DIR}/python/python310_d.pdb)
    set(${MY}_DYLIBS_RELEASE  ${CMAKE_CURRENT_LIST_DIR}/python/python310.dll ${CMAKE_CURRENT_LIST_DIR}/python/python310.dll
                              ${CMAKE_CURRENT_LIST_DIR}/python/python310.pdb ${CMAKE_CURRENT_LIST_DIR}/python/python310.pdb)

    set(${MY}_COMPILE_DEFINITIONS DEFAULT_LY_PYTHONHOME="${CMAKE_CURRENT_LIST_DIR}/python")

    # the rest of this file could be reused for almost any target:
    # we set it to a generator expression for multi-config situations:
    set(${MY}_LIBRARY "$<IF:$<CONFIG:Debug>,${${MY}_LIBRARY_DEBUG},${${MY}_LIBRARY_RELEASE}>")
    set(${MY}_DYLIBS "$<IF:$<CONFIG:Debug>,${${MY}_DYLIBS_DEBUG},${${MY}_DYLIBS_RELEASE}>")

    # now set up the target using the above declarations....
    add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
    ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY}_INCLUDE_DIR})
    target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE "${${MY}_LIBRARY}")
    target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE "${${MY}_COMPILE_DEFINITIONS}")

    # we also need to add the python dlls to be copied to the binaries folder...
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES INTERFACE_IMPORTED_LOCATION "${${MY}_DYLIBS}")
endif()

set(${MY}_FOUND True)
