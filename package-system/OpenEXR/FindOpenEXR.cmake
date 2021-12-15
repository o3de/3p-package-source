#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if (TARGET 3rdParty::OpenEXR)
    return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/o3de_package_utilities.cmake)

# OpenEXR depends on ZLIB.  For maximum compatibility here, we use the
# official ZLIB library name, ie, ZLIB::ZLIB and not o3de 3rdParty::ZLIB.
# O3DE's zlib package will define both.  If we're in O3DE we can also
# auto-download ZLIB.
if (NOT TARGET ZLIB::ZLIB)
    if (COMMAND ly_download_associated_package)
        ly_download_associated_package(ZLIB REQUIRED MODULE)
    endif()
    find_package(ZLIB REQUIRED)
endif()

find_package(Imath MODULE REQUIRED) # will bring in the FindImath.cmake in the same folder
find_package(OpenEXR CONFIG REQUIRED)

set(OpenEXR_COMPONENTS
    OpenEXR::OpenEXRConfig
    OpenEXR::IexConfig
    OpenEXR::IlmThreadConfig
    OpenEXR::Iex
    OpenEXR::IlmThread
    OpenEXR::OpenEXRCore
    OpenEXR::OpenEXRUtil
    OpenEXR::OpenEXR
)

foreach(component ${OpenEXR_COMPONENTS})
    if(TARGET ${component})
        # convert the includes to system includes
        get_target_property(system_includes ${component} INTERFACE_INCLUDE_DIRECTORIES)
        set_target_properties(${component} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "") # Clear it in case someone refers to it
        
        if (COMMAND ly_target_include_system_directories)
            ly_target_include_system_directories(TARGET ${component} INTERFACE ${system_includes})
        else()
            target_include_directories(${component} SYSTEM INTERFACE ${system_includes})
        endif()

        # Alias the target with 3rdParty prefix
        add_library(3rdParty::${component} ALIAS ${component})

        # inside the loop where it sets the system includes for each component
        foreach(conf IN LISTS CMAKE_CONFIGURATION_TYPES)
            string(TOUPPER ${conf} UCONF)
            if (${UCONF} STREQUAL "DEBUG" AND ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
                set_target_properties(${component} PROPERTIES 
                                        MAP_IMPORTED_CONFIG_${UCONF} DEBUG)
            else()
                set_target_properties(${component} PROPERTIES 
                                        MAP_IMPORTED_CONFIG_${UCONF} RELEASE)
            endif()
        endforeach()
    else()
        message(WARNING "Target not found in OpenEXR: ${component}")
    endif()
endforeach()

# read the existing config files that OpenEXR made when it compiled:
o3de_import_existing_config_files(OpenEXR ${CMAKE_CURRENT_LIST_DIR}/OpenEXR/lib/cmake)

# map from "OpenEXR::xxxxx to 3rdParty::xxxxxx"
o3de_import_targets(NAMESPACE_FROM 
                        OpenEXR
                    NAMESPACE_TO 
                        3rdParty
                    COMPONENTS 
                        OpenEXRConfig
                        IexConfig
                        IlmThreadConfig
                        Iex
                        IlmThread
                        OpenEXRCore
                        OpenEXRUtil
                        OpenEXR)

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using OpenEXR ${OpenEXR_VERSION} from ${CMAKE_CURRENT_LIST_DIR}")
endif()

# compat - some libraries check for OPENEXR_VERSION even though the correct check is OpenEXR_VERSION
set(OPENEXR_VERSION ${OpenEXR_VERSION})
