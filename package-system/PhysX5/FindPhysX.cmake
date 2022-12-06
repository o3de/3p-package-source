#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "PhysX")
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

set(${MY_NAME}_COMPILE_DEFINITIONS $<$<BOOL:${LY_MONOLITHIC_GAME}>:PX_PHYSX_STATIC_LIB>)

# LY_PHYSX_PROFILE_USE_CHECKED_LIBS allows to override what PhysX configuration to use on O3DE profile.
set(LY_PHYSX_PROFILE_USE_CHECKED_LIBS OFF CACHE BOOL "When ON it uses PhysX SDK checked libraries on O3DE profile configuration")
if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
    set(PHYSX_PROFILE_CONFIG "checked")
else()
    set(PHYSX_PROFILE_CONFIG "profile")
endif()

set(PATH_TO_LIBS ${_PACKAGE_DIR}/bin/$<IF:$<BOOL:${LY_MONOLITHIC_GAME}>,static,shared>/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)
set(PATH_TO_SHARED_LIBS ${_PACKAGE_DIR}/bin/shared/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)

if(DEFINED CMAKE_IMPORT_LIBRARY_SUFFIX)
    set(import_lib_prefix ${CMAKE_IMPORT_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_IMPORT_LIBRARY_SUFFIX})
else()
    set(import_lib_prefix ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

set(${MY_NAME}_LIBRARIES
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXCharacterKinematic_static${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXVehicle_static${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXExtensions_static${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXPvdSDK_static${CMAKE_STATIC_LIBRARY_SUFFIX}
)

set(extra_static_libs ${EXTRA_STATIC_LIBS_NON_MONOLITHIC})
set(extra_shared_libs ${EXTRA_SHARED_LIBS})

if(LY_MONOLITHIC_GAME)
    list(APPEND ${MY_NAME}_LIBRARIES
        ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysX_static${CMAKE_STATIC_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXCooking_static${CMAKE_STATIC_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXFoundation_static${CMAKE_STATIC_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXCommon_static${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    if(extra_shared_libs)
        set(${MY_NAME}_RUNTIME_DEPENDENCIES
            ${extra_shared_libs}
        )
    endif()
else()
    list(APPEND ${MY_NAME}_LIBRARIES
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysX${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXCooking${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXFoundation${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXCommon${import_lib_suffix}
        ${extra_static_libs}
    )
    set(${MY_NAME}_RUNTIME_DEPENDENCIES
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysX${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXCooking${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXFoundation${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXCommon${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${extra_shared_libs}
    )
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LIBRARIES})
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})
if(DEFINED ${MY_NAME}_RUNTIME_DEPENDENCIES)
    ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})
endif()

set(${MY_NAME}_FOUND True)
