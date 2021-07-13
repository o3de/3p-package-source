#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(CMakeParseArguments)
include(CMakePackageConfigHelpers)

set(CMAKE_CONFIGURATION_TYPES "debug;release")

function(package_install)

    set(options)
    set(oneValueArgs NAME VERSION URL LICENSE LICENSE_FILE INCLUDE_SUBDIR DEBUG_LIB_SUFFIX)
    set(multiValueArgs)

    cmake_parse_arguments(PACKAGE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT PACKAGE_PLATFORM)
        set(PACKAGE_PLATFORM ${CMAKE_SYSTEM_NAME})
        if(PACKAGE_PLATFORM STREQUAL "Darwin")
            set(PACKAGE_PLATFORM Mac)
        endif()
    endif()
    string(TOLOWER ${PACKAGE_PLATFORM} PACKAGE_PLATFORM)

    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/PackageInfo.json.in ${CMAKE_CURRENT_BINARY_DIR}/PackageInfo.json @ONLY)
    configure_file(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/FindPackageName.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/Find${PACKAGE_NAME}.cmake @ONLY)

    set(${PACKAGE_NAME}_INCLUDE_DIR include/${PACKAGE_INCLUDE_SUBDIR})
    set(${PACKAGE_NAME}_LIBS_DIR lib/$<IF:$<CONFIG:Debug>,debug,release>)
   
    configure_package_config_file(
        ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/PackageName-config.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-config.cmake"
        INSTALL_DESTINATION .
        PATH_VARS 
            ${PACKAGE_NAME}_INCLUDE_DIR
            ${PACKAGE_NAME}_LIBS_DIR
    )
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-config-version.cmake"
        VERSION ${PACKAGE_VERSION}
        COMPATIBILITY ExactVersion
    )
    install(TARGETS ${PACKAGE_NAME} 
        EXPORT 3rdParty::${PACKAGE_NAME} LIBRARY
        CONFIGURATIONS debug release
        ARCHIVE DESTINATION ${${PACKAGE_NAME}_LIBS_DIR}
        PUBLIC_HEADER DESTINATION ${${PACKAGE_NAME}_INCLUDE_DIR}
    )
    install(
        FILES 
            ${PACKAGE_LICENSE_FILE}
            "${CMAKE_CURRENT_BINARY_DIR}/PackageInfo.json"
            "${CMAKE_CURRENT_BINARY_DIR}/Find${PACKAGE_NAME}.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-config.cmake" 
            "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}-config-version.cmake"
        DESTINATION .
    )

endfunction()

