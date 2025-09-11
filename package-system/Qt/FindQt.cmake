#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(TARGET 3rdParty::Qt::Core) # Check we are not called multiple times
    return()
endif()

set(QT_PACKAGE_NAME qt)

set(QT_PATH "${CMAKE_CURRENT_LIST_DIR}/qt" CACHE STRING "The root path to Qt" FORCE)
mark_as_advanced(QT_PATH)
if(NOT EXISTS ${QT_PATH})
    message(FATAL_ERROR "Cannot find 3rdParty library ${QT_PACKAGE_NAME} on path ${QT_PATH}")
endif()

# Force-set QtCore's version here to ensure CMake detects Qt's existence and allows AUTOMOC to work
set(Qt6Core_VERSION_MAJOR "6" CACHE STRING "Qt's major version" FORCE)
set(Qt6Core_VERSION_MINOR "10" CACHE STRING "Qt's minor version" FORCE)
set(Qt6Core_VERSION_PATCH "1" CACHE STRING "Qt's patch version" FORCE)
mark_as_advanced(Qt6Core_VERSION_MAJOR)
mark_as_advanced(Qt6Core_VERSION_MINOR)
mark_as_advanced(Qt6Core_VERSION_PATCH)

set(QT6_COMPONENTS
    Core
    Concurrent
    Gui
    LinguistTools
    Network
    OpenGL
    OpenGLWidgets
    Svg
    SvgWidgets
    Test
    Widgets
    Xml
)

include(${CMAKE_CURRENT_LIST_DIR}/Platform/${PAL_PLATFORM_NAME}/Qt_${PAL_PLATFORM_NAME_LOWERCASE}.cmake)

list(APPEND CMAKE_PREFIX_PATH ${QT_LIB_PATH}/cmake/Qt6)

# Clear the cache for found DIRs
unset(Qt6_DIR CACHE)
foreach(component ${QT6_COMPONENTS})
    unset(Qt6${component}_DIR CACHE)
endforeach()

# Populate the Qt6 configurations
find_package(Qt6
    COMPONENTS ${QT6_COMPONENTS}
    REQUIRED
    NO_CMAKE_PACKAGE_REGISTRY 
)

# Now create libraries that wrap the dependency so we can refer to them in our format
foreach(component ${QT6_COMPONENTS})
    if(TARGET Qt6::${component})

        # Convert the includes to system includes
        get_target_property(system_includes Qt6::${component} INTERFACE_INCLUDE_DIRECTORIES)
        set_target_properties(Qt6::${component} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "") # Clear it in case someone refers to it
        ly_target_include_system_directories(TARGET Qt6::${component}
            INTERFACE ${system_includes}
        )

        # Alias the target with our prefix
        add_library(3rdParty::Qt::${component} ALIAS Qt6::${component})
        mark_as_advanced(Qt6${component}_DIR) # Hiding from GUI

        # Qt only has debug and release, we map the configurations we use in o3de. We map all the configurations 
        # except debug to release
        foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
            string(TOUPPER ${conf} UCONF)
            ly_qt_configuration_mapping(${UCONF} MAPPED_CONF)
            set_target_properties(Qt6::${component} PROPERTIES
                MAP_IMPORTED_CONFIG_${UCONF} ${MAPPED_CONF}
            )
        endforeach()

    endif()
endforeach()

# Some extra DIR variables we want to hide from GUI
mark_as_advanced(Qt6_DIR)
mark_as_advanced(Qt6CoreTools_DIR)
mark_as_advanced(Qt6EntryPointPrivate_DIR)
mark_as_advanced(Qt6GuiTools_DIR)
mark_as_advanced(Qt6WidgetsTools_DIR)
mark_as_advanced(Qt6LinguistTools_DIR)

# Qt plugins/translations/aux files. 
# We create libraries that wraps them so they get deployed properly.
# This used to be deployed through winqtdeploy/macqtdeploy, however, those tools
# are old and unmaintaned, macqtdeploy takes long times to run
add_library(3rdParty::Qt::Core::Translations INTERFACE IMPORTED GLOBAL)
file(GLOB tranlation_files ${QT_PATH}/translations/qt_*.qm)
if(tranlation_files)
    ly_add_target_files(TARGETS 3rdParty::Qt::Core::Translations
        FILES ${tranlation_files}
        OUTPUT_SUBDIRECTORY translations
    )
endif()
ly_add_dependencies(Qt6::Core 3rdParty::Qt::Core::Translations)

# plugins, each platform will define the files it has and the OUTPUT_SUBDIRECTORY
set(QT_PLUGINS
    Network
    Gui
    Widgets
)
foreach(plugin ${QT_PLUGINS})
    add_library(3rdParty::Qt::${plugin}::Plugins INTERFACE IMPORTED GLOBAL)
    ly_add_dependencies(Qt6::${plugin} 3rdParty::Qt::${plugin}::Plugins)
endforeach()
include(${CMAKE_CURRENT_LIST_DIR}/Platform/${PAL_PLATFORM_NAME}/QtPlugin_${PAL_PLATFORM_NAME_LOWERCASE}.cmake)

# MOC executable
unset(QT_MOC_EXECUTABLE CACHE)
find_program(QT_MOC_EXECUTABLE moc HINTS "${QT_PATH}/bin" "${QT_PATH}/libexec" REQUIRED)
mark_as_advanced(QT_MOC_EXECUTABLE) # Hiding from GUI

# UIC executable
unset(QT_UIC_EXECUTABLE CACHE)
find_program(QT_UIC_EXECUTABLE uic HINTS "${QT_PATH}/bin" "${QT_PATH}/libexec" REQUIRED)
mark_as_advanced(QT_UIC_EXECUTABLE) # Hiding from GUI

# RCC executable
unset(AUTORCC_EXECUTABLE CACHE)
find_program(AUTORCC_EXECUTABLE rcc HINTS "${QT_PATH}/bin" "${QT_PATH}/libexec" REQUIRED)
mark_as_advanced(AUTORCC_EXECUTABLE) # Hiding from GUI

# LRELEASE executable
unset(QT_LRELEASE_EXECUTABLE CACHE)
find_program(QT_LRELEASE_EXECUTABLE lrelease HINTS "${QT_PATH}/bin" "${QT_PATH}/libexec" REQUIRED)
mark_as_advanced(QT_LRELEASE_EXECUTABLE) # Hiding from GUI

# We don't use AUTOUIC, AUTOMOC or AUTORCC from cmake
# They all use highly custom behavior which is hard to debug when things go wrong (and currently none of them work against O3DE)
# Instead we call the QT generation .exe directly as you would with any other build system
# This is easy to maintain, to understand, and easy to port

#! ly_qt_uic_target: handles qt's ui files by injecting uic generation
#! You are expected to include the generated ui file in your code to use the generated classes
#! Output format is "YourFolder/ui_YourFileName.h"
function(ly_qt_uic_target TARGET all_ui_sources)
    list(FILTER all_ui_sources INCLUDE REGEX "^.*\\.ui$")
    if(NOT all_ui_sources)
        message(FATAL_ERROR "Target ${TARGET} contains AUTOUIC but doesnt have any .ui file")
        return()
    endif()
    
    if(AUTOGEN_BUILD_DIR)
        set(gen_dir ${AUTOGEN_BUILD_DIR})
    else()
        set(gen_dir ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_autogen/include)
    endif()

    foreach(ui_source ${all_ui_sources})
        get_filename_component(filename ${ui_source} NAME_WE)
        get_filename_component(dir ${ui_source} DIRECTORY)
        if(IS_ABSOLUTE ${dir})
            file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
        endif()

        set(outfolder ${gen_dir}/${dir})
        set(outfile ${outfolder}/ui_${filename}.h)
        get_filename_component(infile ${ui_source} ABSOLUTE)

        file(MAKE_DIRECTORY ${outfolder})
        add_custom_command(OUTPUT ${outfile}
          COMMAND ${QT_UIC_EXECUTABLE} -o ${outfile} ${infile}
          MAIN_DEPENDENCY ${infile} VERBATIM
          COMMENT "UIC ${infile}"
        )

        set_source_files_properties(${infile} PROPERTIES SKIP_AUTOUIC TRUE)
        set_source_files_properties(${outfile} PROPERTIES 
            SKIP_AUTOMOC TRUE
            SKIP_AUTOUIC TRUE
            SKIP_AUTORCC TRUE
            GENERATED TRUE
        )
        list(APPEND all_ui_wrapped_sources ${outfile})
    endforeach()

    # Add files to the target
    target_sources(${TARGET} PRIVATE ${all_ui_wrapped_sources})
    source_group("Generated Files" FILES ${all_ui_wrapped_sources})

    # Add include directories relative to the generated folder
    # query for the property first to avoid the "NOTFOUND" in a list
    get_property(has_includes TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES SET)
    if(has_includes)
        get_property(all_include_directories TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES)
        foreach(dir ${all_include_directories})
            if(IS_ABSOLUTE ${dir})
                file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
            endif()
            list(APPEND new_includes ${gen_dir}/${dir})
        endforeach()
    endif()
    list(APPEND new_includes ${gen_dir})
    target_include_directories(${TARGET} PRIVATE ${new_includes})

endfunction()

#! ly_add_translations: adds translations (ts) to a target.
#
# This wrapper will generate a qrc file with those translations and add the files under "prefix" and add them to
# the indicated targets. These files will be added under the "Generated Files" filter
#
# \arg:TARGETS name of the targets that the translations will be added to
# \arg:PREFIX prefix where the translation will be located within the qrc file
# \arg:FILES translation files to add
#
function(ly_add_translations)

    set(options)
    set(oneValueArgs PREFIX)
    set(multiValueArgs TARGETS FILES)

    cmake_parse_arguments(ly_add_translations "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input arguments
    if(NOT ly_add_translations_TARGETS)
        message(FATAL_ERROR "You must provide at least one target")
    endif()
    if(NOT ly_add_translations_FILES)
        message(FATAL_ERROR "You must provide at least a translation file")
    endif()

    qt_add_translations(TRANSLATED_FILES ${ly_add_translations_FILES})

    set(qrc_file_contents 
"<RCC>
    <qresource prefix=\"/${ly_add_translations_PREFIX}\">
")
    foreach(file ${TRANSLATED_FILES})
        get_filename_component(filename ${file} NAME)
        string(APPEND qrc_file_contents "        <file>${filename}</file>
")
    endforeach()
    string(APPEND qrc_file_contents "    </qresource>
</RCC>
")
    set(qrc_file_path ${CMAKE_CURRENT_BINARY_DIR}/i18n_${ly_add_translations_PREFIX}.qrc)
    file(WRITE 
        ${qrc_file_path}
        ${qrc_file_contents}
    )
    set_source_files_properties(
            ${TRANSLATED_FILES}
            ${qrc_file_path}
        PROPERTIES 
            GENERATED TRUE
            SKIP_AUTORCC TRUE
    )
    qt_add_resources(RESOURCE_FILE ${qrc_file_path})

    foreach(target ${ly_add_translations_TARGETS})
        target_sources(${target} PRIVATE "${TRANSLATED_FILES};${qrc_file_path};${RESOURCE_FILE}")
    endforeach()

endfunction()

#! ly_qt_qrc_target: handles qt's .qrc files
#! The .qrc file name that you use must be unique in your compilation module
#! You have to call Q_INIT_RESOURCE(YOUR_QRC_NAME) in a .cpp file to load it
function(ly_qt_qrc_target TARGET all_qrc_sources)
    list(FILTER all_qrc_sources INCLUDE REGEX "^.*\\.qrc$")
    if(NOT all_qrc_sources)
        message("Target ${TARGET} contains AUTORCC but doesnt have any .qrc file")
        return()
    endif()
    
    if(AUTOGEN_BUILD_DIR)
        set(gen_dir ${AUTOGEN_BUILD_DIR})
    else()
        set(gen_dir ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_autogen/include)
    endif()

    foreach(qrc_source ${all_qrc_sources})
        get_filename_component(filename ${qrc_source} NAME_WE)
        get_filename_component(dir ${qrc_source} DIRECTORY)
        if(IS_ABSOLUTE ${dir})
            file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
        endif()

        set(outfolder ${gen_dir}/${dir})
        set(outfile ${outfolder}/qrc_resources_${filename}.cpp)
        get_filename_component(infile ${qrc_source} ABSOLUTE)

        string(RANDOM _random)
        file(MAKE_DIRECTORY ${outfolder})
        add_custom_command(OUTPUT ${outfile}
          COMMAND ${AUTORCC_EXECUTABLE} -name ${filename} -o ${outfile} ${infile}
          MAIN_DEPENDENCY ${infile} VERBATIM
          COMMENT "RCC ${infile}"
        )

        set_source_files_properties(${infile} PROPERTIES SKIP_AUTORCC TRUE)
        set_source_files_properties(${outfile} PROPERTIES 
            SKIP_AUTOMOC TRUE
            SKIP_AUTOUIC TRUE
            SKIP_AUTORCC TRUE
            SKIP_UNITY_BUILD_INCLUSION TRUE
            GENERATED TRUE
        )
        list(APPEND all_qrc_wrapped_sources ${outfile})
    endforeach()

    # Add files to the target
    target_sources(${TARGET} PRIVATE ${all_qrc_wrapped_sources})
    source_group("Generated Files" FILES ${all_qrc_wrapped_sources})

    # Add include directories relative to the generated folder
    # query for the property first to avoid the "NOTFOUND" in a list
    get_property(has_includes TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES SET)
    if(has_includes)
        get_property(all_include_directories TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES)
        foreach(dir ${all_include_directories})
            if(IS_ABSOLUTE ${dir})
                file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
            endif()
            list(APPEND new_includes ${gen_dir}/${dir})
        endforeach()
    endif()
    list(APPEND new_includes ${gen_dir})
    target_include_directories(${TARGET} PRIVATE ${new_includes})

endfunction()

#! ly_qt_moc_target: handles qt's .h files by injecting moc generation
#! Detect all of your .h/.hxx files with Q_OBJECT macro. Q_OBJECT instead of .cpp files won't be catched.
#! You don't need to include the generated moc file anywhere
#! (old code might include them at the end of their .cpp, this is legacy and should be removed).
function(ly_qt_moc_target TARGET all_moc_sources)
    list(FILTER all_moc_sources INCLUDE REGEX "^.*\\.(h|hxx)$")
    if(NOT all_moc_sources)
        message("Target ${TARGET} contains AUTOMOC but doesn't have any Q_OBJECT macro in a .h or .hxx file")
        return()
    endif()

    if(AUTOGEN_BUILD_DIR)
        set(gen_dir ${AUTOGEN_BUILD_DIR})
    else()
        set(gen_dir ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_autogen/include)
    endif()

    foreach(moc_source ${all_moc_sources})
        # Skip files with no Q_OBJECT declarations
        file(READ ${moc_source} TMP)
        string(FIND "${TMP}" "Q_OBJECT" exist)
        if(${exist} EQUAL -1)
            continue()
        endif()

        get_filename_component(filename ${moc_source} NAME_WE)
        get_filename_component(dir ${moc_source} DIRECTORY)
        if(IS_ABSOLUTE ${dir})
            file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
        endif()

        set(outfolder ${gen_dir}/${dir})
        set(outfile ${outfolder}/moc_${filename}.cpp)
        get_filename_component(infile ${moc_source} ABSOLUTE)

        file(MAKE_DIRECTORY ${outfolder})
        add_custom_command(OUTPUT ${outfile}
          COMMAND ${QT_MOC_EXECUTABLE} -o ${outfile} ${infile}
          MAIN_DEPENDENCY ${infile} VERBATIM
          COMMENT "MOC ${infile}"
        )

        set_source_files_properties(${infile} PROPERTIES SKIP_AUTOMOC TRUE)
        set_source_files_properties(${outfile} PROPERTIES 
            SKIP_AUTOMOC TRUE
            SKIP_AUTOUIC TRUE
            SKIP_AUTORCC TRUE
            GENERATED TRUE
        )
        list(APPEND all_moc_wrapped_sources ${outfile})

    endforeach()

    # Add files to the target
    target_sources(${TARGET} PRIVATE ${all_moc_wrapped_sources})
    source_group("Generated Files" FILES ${all_moc_wrapped_sources})

    # Add include directories relative to the generated folder
    # query for the property first to avoid the "NOTFOUND" in a list
    get_property(has_includes TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES SET)
    if(has_includes)
        get_property(all_include_directories TARGET ${TARGET} PROPERTY INCLUDE_DIRECTORIES)
        foreach(dir ${all_include_directories})
            if(IS_ABSOLUTE ${dir})
                file(RELATIVE_PATH dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
            endif()
            list(APPEND new_includes ${gen_dir}/${dir})
        endforeach()
    endif()
    list(APPEND new_includes ${gen_dir})
    target_include_directories(${TARGET} PRIVATE ${new_includes})

endfunction()
