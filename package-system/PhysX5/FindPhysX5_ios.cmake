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

set(${MY_NAME}_COMPILE_DEFINITIONS $<$<BOOL:${LY_MONOLITHIC_GAME}>:PX_PHYSX_STATIC_LIB>)

# LY_PHYSX_PROFILE_USE_CHECKED_LIBS allows to override what PhysX configuration to use on O3DE profile.
set(LY_PHYSX_PROFILE_USE_CHECKED_LIBS OFF CACHE BOOL "When ON it uses PhysX SDK checked libraries on O3DE profile configuration")
if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
    set(PHYSX_PROFILE_CONFIG "checked")
else()
    set(PHYSX_PROFILE_CONFIG "profile")
endif()

if(LY_MONOLITHIC_GAME)
    set(PATH_TO_LIBS ${_PACKAGE_DIR}/bin/static/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)
else()
    # iOS uses Frameworks for non-monolithic builds.
    # Frameworks are added and managed by XCode during the build process.
    # At the moment $<CONFIG> does not get replaced for "debug", "profile" or
    # "release" for frameworks when added to XCode, so it's not able to find
    # the frameworks since their path is wrong. To workaround this, for now it
    # will only use the profile configuration since non-monolithic is not used
    # when shipping.
    set(PATH_TO_LIBS ${_PACKAGE_DIR}/bin/shared/${PHYSX_PROFILE_CONFIG})
endif()

set(${MY_NAME}_LIBRARIES
    ${PATH_TO_LIBS}/libPhysXCharacterKinematic_static_64.a
    ${PATH_TO_LIBS}/libPhysXVehicle_static_64.a
    ${PATH_TO_LIBS}/libPhysXExtensions_static_64.a
    ${PATH_TO_LIBS}/libPhysXPvdSDK_static_64.a
)
if(LY_MONOLITHIC_GAME)
    list(APPEND ${MY_NAME}_LIBRARIES
        ${PATH_TO_LIBS}/libPhysX_static_64.a
        ${PATH_TO_LIBS}/libPhysXCooking_static_64.a
        ${PATH_TO_LIBS}/libPhysXFoundation_static_64.a
        ${PATH_TO_LIBS}/libPhysXCommon_static_64.a
    )
else()
    list(APPEND ${MY_NAME}_LIBRARIES
        ${PATH_TO_LIBS}/PhysX.framework
        ${PATH_TO_LIBS}/PhysXCooking.framework
        ${PATH_TO_LIBS}/PhysXFoundation.framework
        ${PATH_TO_LIBS}/PhysXCommon.framework
    )
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LIBRARIES})
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})

# Frameworks do not need to get added as runtime dependencies
# since they are handled by XCode directly. Frameworks will
# be copied into the app when constructed by XCode.

set(${MY_NAME}_FOUND True)
