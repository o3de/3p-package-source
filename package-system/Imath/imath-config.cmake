#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# we're trying to be a drop-in replacement for the FindImath.cmake
# this means not using O3DE-specific functions.

set(Imath_INCLUDE_DIRS ${CMAKE_CURRENT_LIST_DIR}/Imath/include)
set(Imath_LIB_DIR ${CMAKE_CURRENT_LIST_DIR}/Imath/lib)
set(Imath_VERSION_STRING "3.2.2")
set(Imath_VERSION ${Imath_VERSION_STRING})
set(Imath_FOUND  True)

if (NOT TARGET Imath::Imath)
    add_library(Imath::Imath STATIC IMPORTED GLOBAL)
    set_target_properties(Imath::Imath 
        PROPERTIES
        IMPORTED_LOCATION ${Imath_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}Imath-3_2${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set_target_properties(Imath::Imath 
        PROPERTIES
        IMPORTED_LOCATION_DEBUG ${Imath_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}Imath-3_2_d${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    endif()
    # frustratingly, some 3rd party libraries expect the include dir to be like
    #  #include <Imath/ImathConfig.h>
    # while others expect
    #  #include <ImathConfig.h>
    # so spoon feed it...
    target_include_directories(Imath::Imath SYSTEM INTERFACE ${Imath_INCLUDE_DIRS}  ${Imath_INCLUDE_DIRS}/Imath)
    
endif()

if (NOT TARGET 3rdParty::Imath::Imath)
    add_library(3rdParty::Imath::Imath ALIAS Imath::Imath)
endif()

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE's Imath (${Imath_VERSION_STRING}) from ${CMAKE_CURRENT_LIST_DIR}")
endif()

