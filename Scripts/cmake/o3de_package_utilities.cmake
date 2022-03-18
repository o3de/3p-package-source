#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

include(CMakeParseArguments)

# You can pull this file into your package build script
# by copying it to the output folder or by using the following via 
# pull_and_build_from_git.py (recommended):

# "extra_files_to_copy": [
#    ["../../Scripts/cmake/o3de_package_utilities.cmake", "o3de_package_utilities.cmake"]
# ],

# then use include(${CMAKE_CURRENT_LIST_DIR}/o3de_package_utilities.cmake) in your package Find file.

# o3de_import_targets(
    # NAMESPACE_FROM from_namespac]   <--- optional
    # NAMESPACE_TO to_namespace       <--- optional
    # COMPONENTS component component component ...) <--- mandatory
# For each component in the list of COMPONENTS, 
#     This function will change the includes of target ${NAMESPACE_FROM}::${component} to
#     be using system includes instead of regular includes.
#     It also maps the IMPORTED_LOCATION configurations.  It does so by
#     checking the imported configurations that are provided for the target ${NAMESPACE_FROM}::${component} 
#     compared to the configurations that are currently active in the project being configured by CMake.
#     Any configurations that are present in both are preserved, while any mismatches get defaulted to RELEASE.
#        For example, if the target provides "Debug", and "Release" imported locations, and the project
#        being compiled uses "Debug", "RelWithDebInfo", "Release"
#        it will map "Debug" -> "Debug"
#                "Release" -> "Release"
#                "RelWithDebInfo" -> "Release"
#     Finally, if NAMESPACE_TO is specified, it will create an alias from
#     {NAMESPACE_FROM}::${component} to ${NAMESPACE_TO}::${component}.
#     NAMESPACE_TO is usually "3rdParty" for O3DE.

function(o3de_import_targets)
    set(singleValues NAMESPACE_FROM NAMESPACE_TO)
    set(multiValues COMPONENTS)
    
    cmake_parse_arguments(_o3de_import_targets
                     ""
                     "${singleValues}"
                     "${multiValues}"
                    ${ARGN})

    if (NOT _o3de_import_targets_COMPONENTS)
        message(FATAL_ERROR "You must specify COMPONENTS for o3de_import_targets")
    endif()

    if (_o3de_import_targets_NAMESPACE_FROM)
        set(from_namespace_prefix "${_o3de_import_targets_NAMESPACE_FROM}::")
    endif()

    if (_o3de_import_targets_NAMESPACE_TO)
        set(to_namespace_prefix "${_o3de_import_targets_NAMESPACE_TO}::")
    endif()

    if (_o3de_import_targets_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unexpected Arguments: ${_o3de_import_targets_UNPARSED_ARGUMENTS}")
    endif()

    foreach(component IN LISTS _o3de_import_targets_COMPONENTS)
        set(component_target_name ${from_namespace_prefix}${component})
        if(TARGET ${component_target_name})

            # convert the includes to system includes to account for older CMake versions:
            get_target_property(system_includes ${component_target_name} INTERFACE_INCLUDE_DIRECTORIES)
            set_target_properties(${component_target_name} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "") # Clear it in case someone refers to it
            if (COMMAND ly_target_include_system_directories)
                ly_target_include_system_directories(TARGET ${component_target_name} INTERFACE ${system_includes})
            else()
                target_include_directories(${component_target_name} SYSTEM INTERFACE ${system_includes})
            endif()

            # Alias the target in the new namespace:
            if (to_namespace_prefix AND from_namespace_prefix AND NOT "${to_namespace_prefix}" STREQUAL "${from_namespace_prefix}")
                add_library(${to_namespace_prefix}${component} ALIAS ${component_target_name})
            endif()

            # get the list of imported configurations:
            get_target_property(imported_configs_on_target ${component_target_name} IMPORTED_CONFIGURATIONS)

            # often, 3p libraries come with a limited set of configs (like just Debug+Release, or just Release)
            # but projects using them have more than that (for example, RelWithDebInfo or Profile or some other
            # custom name).  This uses MAP_IMPORTED_CONFIG_xxxxxx yyyyy to declare that when a project is being
            # built with xxxxxx config (ie, RELWITHDEBINFO), it should use yyyyy config from the imported target
            # ie, 'RELEASE'.
            foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
                string(TOUPPER ${conf} UCONF)
                if (${UCONF} IN_LIST imported_configs_on_target)
                    # if the imported target actually has a config with the same name, then use that config:
                    set_target_properties(${component_target_name} PROPERTIES MAP_IMPORTED_CONFIG_${UCONF} ${UCONF})
                else() 
                    # there is no such config on the imported target, we default to RELEASE.
                    set_target_properties(${component_target_name} PROPERTIES 
                                            MAP_IMPORTED_CONFIG_${UCONF} RELEASE)
                endif()
            endforeach()
        else()
            message(FATAL_ERROR "Expected target not found: ${component_target_name}")
        endif()
    endforeach()
endfunction()

# o3de_import_existing_config_files(package_name search_dir)
# sets the appropriate variables that will force cmake to search
# the search_dir, then calls find_package(${package_name} CONFIG REQUIRED)
# restores any global vars that are not package-specific afterwards.
# after calling this, consider calling o3de_import_targets to correct any mapping
# problems and make it compatible with O3DE's expectations.

macro(o3de_import_existing_config_files package_name search_dir)
    # some platform toolchains switch CMake into a mode where it will not search
    # sysroot or the CMAKE_PREFIX_PATHs, so we use the FIND_ROOT_PATH.
    # for other platforms, we set the xxxx_ROOT value.
    set(_old_find_root_path ${CMAKE_FIND_ROOT_PATH})
    set(CMAKE_FIND_ROOT_PATH ${search_dir} ${CMAKE_FIND_ROOT_PATH})
    set(${package_name}_ROOT ${search_dir})
    # its also possible that an older version of _DIR has been cached.
    unset(${package_name}_DIR CACHE)
    unset(${package_name}_DIR)
    find_package(${package_name} CONFIG REQUIRED)
    # reset these variables back to what they were.
    set(CMAKE_FIND_ROOT_PATH ${_old_find_root_path})
    if (NOT ${package_name}_FOUND)
        message(FATAL_ERROR "Could not import configs for ${package_name} from ${search_dir}")
    endif()
    mark_as_advanced(${package_name}_DIR) # Hiding from GUI
endmacro()
