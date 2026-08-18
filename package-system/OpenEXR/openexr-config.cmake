#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# This version of OpenEXR needs to work with and without O3DE's macros and scripts
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

include(CMakeFindDependencyMacro)

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
if (NOT OpenEXR_FOUND)
    message(FATAL_ERROR "OpenEXR not found despite running the built-in OpenEXR import scripts from ${CMAKE_CURRENT_LIST_DIR}/OpenEXR/lib/cmake")
endif()

# fixup OpenEXR::xxxxxx it forces /EHsc when compiled on windows MSVC, when it should be doing so when targetted to it instead:
set_target_properties(OpenEXR::Iex PROPERTIES INTERFACE_COMPILE_OPTIONS "$<$<CXX_COMPILER_ID:MSVC>:/EHsc>")
set_target_properties(OpenEXR::IlmThread PROPERTIES INTERFACE_COMPILE_OPTIONS "$<$<CXX_COMPILER_ID:MSVC>:/EHsc>")
set_target_properties(OpenEXR::OpenEXRCore PROPERTIES INTERFACE_COMPILE_OPTIONS "$<$<CXX_COMPILER_ID:MSVC>:/EHsc>")
set_target_properties(OpenEXR::OpenEXR PROPERTIES INTERFACE_COMPILE_OPTIONS "$<$<CXX_COMPILER_ID:MSVC>:/EHsc>")
set_target_properties(OpenEXR::OpenEXRUtil PROPERTIES INTERFACE_COMPILE_OPTIONS "$<$<CXX_COMPILER_ID:MSVC>:/EHsc>")

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME AND NOT ALREADY_MENTIONED_OPENEXR)
    set(ALREADY_MENTIONED_OPENEXR TRUE)
    message(STATUS "Using O3DE's OpenEXR ${OpenEXR_VERSION} (BSD-3-Clause) from ${CMAKE_CURRENT_LIST_DIR}")
endif()

# compat - some libraries check for OPENEXR_VERSION even though the correct check is OpenEXR_VERSION
set(OPENEXR_VERSION ${OpenEXR_VERSION})
