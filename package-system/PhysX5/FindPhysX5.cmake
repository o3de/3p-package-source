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

set(${MY_NAME}_INCLUDE_DIR
    ${_PACKAGE_DIR}/include
    ${_PACKAGE_DIR}/include/foundation
    ${_PACKAGE_DIR}/include/geometry
)

# We will only use the static libs for linking
set(${MY_NAME}_COMPILE_DEFINITIONS PX_PHYSX_STATIC_LIB)

# LY_PHYSX_PROFILE_USE_CHECKED_LIBS allows to override what PhysX configuration to use on O3DE profile.
set(LY_PHYSX_PROFILE_USE_CHECKED_LIBS OFF CACHE BOOL "When ON it uses PhysX SDK checked libraries on O3DE profile configuration")
if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
    set(PHYSX_PROFILE_CONFIG "checked")
else()
    set(PHYSX_PROFILE_CONFIG "profile")
endif()

# Set the generator-expression path to the static libs
set(PATH_TO_LIBS ${_PACKAGE_DIR}/bin/static/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)

if(DEFINED CMAKE_IMPORT_LIBRARY_SUFFIX)
    set(import_lib_prefix ${CMAKE_IMPORT_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_IMPORT_LIBRARY_SUFFIX})
else()
    set(import_lib_prefix ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

set(extra_static_libs ${EXTRA_STATIC_LIBS})
set(extra_shared_libs ${EXTRA_SHARED_LIBS})

# The order of PhysX 5.x static libraries is important for static targets. We will loop through in order and define
# each static library explicitly, while setting their dependency as a chain to ensure the order is preserved

set(IMPORTED_PHYSICS_LIBS_SUFFIX
    PhysX_static_64
    PhysXPvdSDK_static_64
    PhysXVehicle_static_64
    PhysXVehicle2_static_64
    PhysXCharacterKinematic_static_64
    PhysXExtensions_static_64
    PhysXCooking_static_64
    PhysXCommon_static_64
    PhysXFoundation_static_64
)

foreach(PHYSICS_LIB ${IMPORTED_PHYSICS_LIBS_SUFFIX})

    # Set the individual target names to include a ${MY_NAME} prefix in order to prevent collisions
    # with other 3rd party PhysX Packages of different versions while retaining the same actual
    # filename

    set(PHYSICS_LIB_NAME ${MY_NAME}${PHYSICS_LIB})

    add_library(${PHYSICS_LIB_NAME}::imported STATIC IMPORTED GLOBAL)

    # Set the import location (note: generator expressions are not supported as properties here, so each config needs to be explicit for its location)
    set_target_properties(${PHYSICS_LIB_NAME}::imported
        PROPERTIES
            IMPORTED_LOCATION_DEBUG   ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx/bin/static/debug/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
            IMPORTED_LOCATION_PROFILE ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx/bin/static/${PHYSX_PROFILE_CONFIG}/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
            IMPORTED_LOCATION_RELEASE ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx/bin/static/release/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
    )

    # Set the target libraries dependency on any previous lib to build the order chain
    target_link_libraries(${PHYSICS_LIB_NAME}::imported INTERFACE
        ${PREVIOUS_PHYSICS_LIB}
        ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    set (PREVIOUS_PHYSICS_LIB ${PHYSICS_LIB_NAME}::imported)

endforeach()

add_library(${MY_NAME}_STATIC_LIBS::imported INTERFACE IMPORTED GLOBAL)

# Set the final ${MY_NAME}_STATIC_LIBS to the last static target defined to complete the chain
target_link_libraries(${MY_NAME}_STATIC_LIBS::imported INTERFACE
    ${PREVIOUS_PHYSICS_LIB}
    ${extra_static_libs}
)

# Add any optional shared library dependency as a runtime dependency
if(extra_shared_libs)
    set(${MY_NAME}_RUNTIME_DEPENDENCIES
        ${extra_shared_libs}
    )
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})

target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${MY_NAME}_STATIC_LIBS::imported)

target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})

if(DEFINED ${MY_NAME}_RUNTIME_DEPENDENCIES)
    ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})
endif()

set(${MY_NAME}_FOUND True)
