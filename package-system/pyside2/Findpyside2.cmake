#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
     
set(MY_NAME "pyside2")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

# Install the pyside2 site-packages into Python
add_library(${TARGET_WITH_NAMESPACE} SHARED IMPORTED GLOBAL)

set(PYSIDE_BASE_PATH ${CMAKE_CURRENT_LIST_DIR}/pyside2)

# In addition to the libraries, create a Pyside2::Tools library that handles the shiboken and pyside2-lupdate executables that are part
# of the pyside2 package
set(${MY_NAME}_BIN_DIR ${PYSIDE_BASE_PATH}/bin)
set(${MY_NAME}_LIB_DIR ${PYSIDE_BASE_PATH}/lib)
set(${MY_NAME}_INCLUDE_DIR ${PYSIDE_BASE_PATH}/include)

if (PAL_PLATFORM_NAME STREQUAL "Windows")
    ly_pip_install_local_package_editable(${${MY_NAME}_LIB_DIR}/site-packages pyside2)
elseif (PAL_PLATFORM_NAME STREQUAL "Linux")
    ly_pip_install_local_package_editable(${PYSIDE_BASE_PATH}/lib/python3.10/site-packages pyside2)
endif()

if (PAL_PLATFORM_NAME STREQUAL "Linux")
    set(${MY_NAME}_RUNTIME_DEPENDENCIES
        ${${MY_NAME}_LIB_DIR}/libpyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}.5.15.2.1
        ${${MY_NAME}_LIB_DIR}/libpyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}.5.15
        ${${MY_NAME}_LIB_DIR}/libpyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${${MY_NAME}_LIB_DIR}/libshiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}.5.15.2.1
        ${${MY_NAME}_LIB_DIR}/libshiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}.5.15
        ${${MY_NAME}_LIB_DIR}/libshiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
    
    ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})
endif()

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE}
    INTERFACE 
        ${${MY_NAME}_INCLUDE_DIR}
        ${${MY_NAME}_INCLUDE_DIR}/PySide2
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtConcurrent
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtCore
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtGui
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtNetwork
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtOpenGL
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtOpenGLFunctions
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtSql
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtSvg
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtWidgets
        ${${MY_NAME}_INCLUDE_DIR}/PySide2/QtXml
)

if (PAL_PLATFORM_NAME STREQUAL "Windows")
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES 
        ${MY_NAME}_SHARE_DIR ${CMAKE_CURRENT_LIST_DIR}/pyside2/share
        IMPORTED_IMPLIB "${${MY_NAME}_LIB_DIR}/site-packages/PySide2/pyside2.abi3${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION "${${MY_NAME}_LIB_DIR}/site-packages/PySide2/pyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
        IMPORTED_IMPLIB_DEBUG "${${MY_NAME}_LIB_DIR}/site-packages/PySide2/pyside2_d.cp310-win_amd64${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${${MY_NAME}_LIB_DIR}/site-packages/PySide2/pyside2_d.cp310-win_amd64${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )
elseif (PAL_PLATFORM_NAME STREQUAL "Linux")
    set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES 
        ${MY_NAME}_SHARE_DIR ${CMAKE_CURRENT_LIST_DIR}/pyside2/share
        IMPORTED_LOCATION "${${MY_NAME}_LIB_DIR}/libpyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${${MY_NAME}_LIB_DIR}/libpyside2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )   
endif()

set(${MY_NAME}_TOOLS_BINARIES
    ${${MY_NAME}_BIN_DIR}/pyside2-lupdate${CMAKE_EXECUTABLE_SUFFIX}
    ${${MY_NAME}_BIN_DIR}/shiboken2${CMAKE_EXECUTABLE_SUFFIX}
)

set(${MY_NAME}_TOOLS_PYTHON_SCRIPTS
    ${${MY_NAME}_BIN_DIR}/pyside_tool.py
    ${${MY_NAME}_BIN_DIR}/shiboken_tool.py
)

if (PAL_PLATFORM_NAME STREQUAL "Windows")
    set(${MY_NAME}_TOOLS_DEPENDENCIES
        ${${MY_NAME}_BIN_DIR}/libclang.dll
    )
elseif (PAL_PLATFORM_NAME STREQUAL "Linux")
    set(${MY_NAME}_TOOLS_DEPENDENCIES
    ${${MY_NAME}_BIN_DIR}/libclang.so.13
)
endif()

add_library(${MY_NAME}::Tools SHARED IMPORTED GLOBAL)

ly_add_target_files(TARGETS ${MY_NAME}::Tools FILES
    ${${MY_NAME}_TOOLS_BINARIES}
    ${${MY_NAME}_TOOLS_DEPENDENCIES}
    ${${MY_NAME}_TOOLS_PYTHON_SCRIPTS}
)

ly_target_include_system_directories(TARGET ${MY_NAME}::Tools
    INTERFACE ${${MY_NAME}_INCLUDE_DIR}/shiboken2
)

if (PAL_PLATFORM_NAME STREQUAL "Windows")
    set_target_properties(${MY_NAME}::Tools PROPERTIES  
        IMPORTED_IMPLIB "${${MY_NAME}_LIB_DIR}/site-packages/shiboken2/shiboken2.abi3${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION "${${MY_NAME}_LIB_DIR}/site-packages/shiboken2/shiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
        IMPORTED_IMPLIB_DEBUG "${${MY_NAME}_LIB_DIR}/site-packages/shiboken2/shiboken2_d.cp310-win_amd64${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${${MY_NAME}_LIB_DIR}/site-packages/shiboken2/shiboken2_d.cp310-win_amd64${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )
elseif (PAL_PLATFORM_NAME STREQUAL "Linux")
    set_target_properties(${MY_NAME}::Tools PROPERTIES  
        IMPORTED_LOCATION "${${MY_NAME}_LIB_DIR}/libshiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${${MY_NAME}_LIB_DIR}/libshiboken2.abi3${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )
endif()

add_library(${TARGET_WITH_NAMESPACE}::Tools ALIAS ${MY_NAME}::Tools)

# Add shiboken generator exe tool.
add_executable(${MY_NAME}::ShibokenTool IMPORTED GLOBAL)
set_target_properties(${MY_NAME}::ShibokenTool PROPERTIES IMPORTED_LOCATION "${${MY_NAME}_BIN_DIR}/shiboken2${CMAKE_EXECUTABLE_SUFFIX}")
add_executable(${TARGET_WITH_NAMESPACE}::ShibokenTool ALIAS ${MY_NAME}::ShibokenTool)

function(add_shiboken_project)
    set(oneValueArgs MODULE_NAME NAMESPACE NAME WRAPPED_HEADER TYPESYSTEM_FILE GENERATED_FILES LICENSE_HEADER)
    set(multiValueArgs INCLUDE_DIRS DEPENDENCIES)
    cmake_parse_arguments(add_shiboken_project "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    
    # Validate arguments
    if (NOT add_shiboken_project_MODULE_NAME)
        message(FATAL_ERROR "You must provide a module name matching the package name in the xml typesystem file. This is the name of the output Python module.")
    endif()
    
    if(NOT add_shiboken_project_WRAPPED_HEADER)
        message(FATAL_ERROR "You must provide a header file containing all headers to be reflected.")
    endif()
    
    if(NOT add_shiboken_project_TYPESYSTEM_FILE)
        message(FATAL_ERROR "You must provide a typesystem file containing all items to be reflected.")
    endif()
    
    if(NOT add_shiboken_project_GENERATED_FILES)
        message(FATAL_ERROR "You must provide a cmake file containing all the cpp files that will be generated.")
    endif()
    
    # Include generated_files: this should define the GENERATED_FILES list.
    include(${add_shiboken_project_GENERATED_FILES})
    if(NOT GENERATED_FILES)
        message(FATAL_ERROR "You must provide a GENERATED_FILES list.")
    endif()
    
    # Reformat the include dirs array to add in "-I" to each entry, or shiboken won't work.
    list(TRANSFORM add_shiboken_project_INCLUDE_DIRS PREPEND "-I")                    
    
    # Reformat the generated files list to prepend the containing folder.
    list(TRANSFORM GENERATED_FILES PREPEND "${CMAKE_CURRENT_BINARY_DIR}/${add_shiboken_project_MODULE_NAME}/")
    
    get_property(SHARE_DIR TARGET 3rdParty::pyside2 PROPERTY pyside2_SHARE_DIR)
        
    # Allow AUTOMOC/AUTOUIC on generated files.
    if(POLICY CMP0071)
      cmake_policy(SET CMP0071 NEW)
    endif()
    set(CMAKE_AUTOMOC ON)
    
    set(shiboken_options --generator-set=shiboken --enable-parent-ctor-heuristic
        --enable-pyside-extensions --enable-return-value-heuristic --use-isnull-as-nb_nonzero
        --avoid-protected-hack --language-level=c++17 --debug-level=full
        --license-file=${add_shiboken_project_LICENSE_HEADER}
        ${add_shiboken_project_INCLUDE_DIRS}
        -T${SHARE_DIR}/PySide2
        -T${SHARE_DIR}/PySide2/typesystems
        --output-directory=${CMAKE_CURRENT_BINARY_DIR}
    )
    
    set(generated_sources_dependencies ${add_shiboken_project_WRAPPED_HEADER} ${add_shiboken_project_TYPESYSTEM_FILE})
    
    # Custom shiboken command to generate wrapped files. Set the working directory to qt/bin so that shiboken can load necessary dlls.
    add_custom_command(
        OUTPUT ${GENERATED_FILES}
        COMMAND 3rdParty::pyside2::ShibokenTool ${shiboken_options} ${add_shiboken_project_WRAPPED_HEADER} ${add_shiboken_project_TYPESYSTEM_FILE}
        DEPENDS ${generated_sources_dependencies} 3rdParty::pyside2
        COMMENT "Running generator for ${add_shiboken_project_TYPESYSTEM_FILE}."
        WORKING_DIRECTORY ${QT_PATH}/bin
        VERBATIM
    )
    
    # Set up the project for building the code generated by shiboken.
    ly_add_target(
        NAME ${add_shiboken_project_NAME}.Editor MODULE
        NAMESPACE add_shiboken_project_NAMESPACE
        OUTPUT_NAME ${add_shiboken_project_MODULE_NAME}
        # We need to provide a FILES_CMAKE, but as the files do not yet exist, project creation would fail if it actually 
        # had a FILES list. The files are actually added in by the following TARGET_SOURCES step.
        FILES_CMAKE
            ${add_shiboken_project_GENERATED_FILES}
        BUILD_DEPENDENCIES
            PUBLIC
                3rdParty::pyside2
                Qt5::Widgets
                Qt5::Core
                Qt5::Widgets
                Qt5::Gui
                ${add_shiboken_project_DEPENDENCIES}
            PRIVATE
                3rdParty::pyside2::Tools
    )
        
    ly_create_alias(NAME ${add_shiboken_project_NAME}.Builders NAMESPACE add_shiboken_project_NAMESPACE TARGETS ${add_shiboken_project_NAME}.Editor)
    ly_create_alias(NAME ${add_shiboken_project_NAME}.Tools NAMESPACE add_shiboken_project_NAMESPACE TARGETS ${add_shiboken_project_NAME}.Builders)
    
    target_sources(${add_shiboken_project_NAME}.Editor PRIVATE ${GENERATED_FILES})

    # Building the wrapper files will not work with a unity build.
    set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES UNITY_BUILD OFF)
    
    if (PAL_PLATFORM_NAME STREQUAL "Windows")
        # Append _d to the module name in a debug build.
        set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES DEBUG_POSTFIX "_d")
    
        # Disable various warnings in shiboken generated wrapper code.
        #"conditional expression is constant"
        #"unreferenced formal parameter"
        #"declaration of 'x' hides previous local declaration."
        #"declaration of 'x' hides class member."
        target_compile_options(${add_shiboken_project_NAME}.Editor PRIVATE /wd4127 /wd4100 /wd4456 /wd4458)
    endif()

    # Fix the name of the module.
    set_property(TARGET ${add_shiboken_project_NAME}.Editor PROPERTY PREFIX "")
    set_property(TARGET ${add_shiboken_project_NAME}.Editor PROPERTY SUFFIX ".pyd")

    set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES LINK_FLAGS "${python_additional_link_flags}")
endfunction()

set(${MY_NAME}_FOUND True)
