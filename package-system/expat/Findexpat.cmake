#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# the following is like an include guard:
if (TARGET 3rdParty::expat)
    return()
endif()

# Even though expat itself exports it as lowercase expat, older cmake (and cmake's built-in targets)
# expect uppercase.  So we define both, for backwards compat:
# See https://cmake.org/cmake/help/latest/module/FindEXPAT.html for how CMake exports it.
# in order to support old and new packages, we'll export it as CMake exports it but also
# alias that to older legacy ones.

if (WIN32)
    # on windows, expat adds the nonstandard 'lib' prefix and MD, dMD suffixes for 
    # Multithreaded Dynamic CRT and debug Multithreaded Dynamic CRT
    # We don't use the debug version since its a pure C library with no C++ and thus will
    # not have an ITERATOR_DEBUG_LEVEL conflict
    set(PREFIX_TO_USE "lib")
    set(SUFFIX_TO_USE "MD.lib")
else()
    # on other platforms its just standard prefixes and suffix
    set(PREFIX_TO_USE ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(SUFFIX_TO_USE ${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

set(EXPAT_VERSION_STRING "2.4.2")
set(EXPAT_VERSION "2.4.2") # backward compat
set(expat_VERSION "2.4.2") # backward compat

set(EXPAT_LIBRARY ${CMAKE_CURRENT_LIST_DIR}/expat/lib/${PREFIX_TO_USE}expat${SUFFIX_TO_USE})
set(expat_LIBRARY ${EXPAT_LIBRARY})
set(EXPAT_LIBRARIES ${EXPAT_LIBRARY}) # compatibility with CMake's FindEXPAT.cmake

set(EXPAT_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/expat/include)
set(expat_INCLUDE_DIR ${EXPAT_INCLUDE_DIR})
set(EXPAT_INCLUDE_DIRS ${EXPAT_INCLUDE_DIR})  #compatibility with CMake's FindEXPAT file.

set(EXPAT_FOUND TRUE) #compatibility with CMake's FindEXPAT file.
set(expat_FOUND TRUE)

add_library(expat::expat STATIC IMPORTED GLOBAL)
set_target_properties(expat::expat PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C")
set_target_properties(expat::expat PROPERTIES IMPORTED_LOCATION ${EXPAT_LIBRARY})
target_compile_definitions(expat::expat INTERFACE XML_STATIC)

if (COMMAND ly_target_include_system_directories)
    # inside the O3DE ecosystem, this macro makes sure it works even in cmake < 3.19
    ly_target_include_system_directories(TARGET expat::expat INTERFACE ${EXPAT_INCLUDE_DIR})
else()
    # outside the O3DE ecosystem, we do our best...
    target_include_directories(expat::expat SYSTEM INTERFACE ${EXPAT_INCLUDE_DIR})
endif()

# create O3DE aliases:
add_library(3rdParty::expat ALIAS expat::expat)

# upppercase for compat:
add_library(EXPAT::EXPAT ALIAS expat::expat) #compatibility with CMake's FindEXPAT file.

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:

if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE expat ${expat_VERSION} from ${CMAKE_CURRENT_LIST_DIR}")
endif()
