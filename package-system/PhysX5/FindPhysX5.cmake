#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "PhysX5")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(_PACKAGE_DIR ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx)
option(LY_PHYSX_PROFILE_USE_CHECKED_LIBS "Use PhysX checked libraries for O3DE profile" OFF)

# Keep each installed SDK intact and combine its exported configuration locations.
block(SCOPE_FOR VARIABLES)
    set(PhysX_DIR "${_PACKAGE_DIR}/release/lib/cmake/PhysX")
    find_package(PhysX 5 CONFIG REQUIRED GLOBAL
        PATHS "${_PACKAGE_DIR}/release/lib/cmake/PhysX"
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
    foreach(config debug checked profile)
        set(_IMPORT_PREFIX "${_PACKAGE_DIR}/${config}")
        include("${_IMPORT_PREFIX}/lib/cmake/PhysX/PhysXTargets-${config}.cmake")
    endforeach()
endblock()

if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
    get_property(_physx5_targets DIRECTORY PROPERTY IMPORTED_TARGETS)
    foreach(target IN LISTS _physx5_targets)
        if(target MATCHES "^PhysX::")
            set_property(TARGET ${target} PROPERTY MAP_IMPORTED_CONFIG_PROFILE checked)
        endif()
    endforeach()
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE PhysX::physx_lib)

if(TARGET PhysX::PhysXGpu)
    set(PhysX5_RUNTIME_DEPENDENCIES "$<TARGET_FILE:PhysX::PhysXGpu>")
    if(COMMAND ly_add_target_files)
        ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${PhysX5_RUNTIME_DEPENDENCIES})
    endif()
endif()

set(PhysX5_FOUND TRUE)
