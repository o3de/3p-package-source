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

set(EXPAT_LIBRARY ${CMAKE_CURRENT_LIST_DIR}/expat/lib/${CMAKE_STATIC_LIBRARY_PREFIX}expat${CMAKE_STATIC_LIBRARY_SUFFIX})
set(expat_LIBRARY ${EXPAT_LIBRARY})

set(EXPAT_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/expat/include)
set(expat_INCLUDE_DIR ${EXPAT_INCLUDE_DIR})

set(EXPAT_FOUND TRUE)
set(expat_FOUND TRUE)

add_library(expat::expat STATIC IMPORTED GLOBAL)
set_target_properties(expat::expat PROPERTIES IMPORTED_LOCATION ${EXPAT_LIBRARY})

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
add_library(EXPAT::EXPAT ALIAS expat::expat)

# if we're not in O3DE, it's also extremely helpful to show a message to logs that indicate that this
# library was successfully picked up, as opposed to the system one.
# A good way to know if you're in O3DE or not is that O3DE sets various cache variables before 
# calling find_package, specifically, LY_VERSION_ENGINE_NAME is always set very early:
if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using O3DE expat ${expat_VERSION} from ${CMAKE_CURRENT_LIST_DIR}")
endif()
