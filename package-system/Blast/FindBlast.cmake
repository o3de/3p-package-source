# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root
# of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "Blast")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(_PACKAGE_DIR ${CMAKE_CURRENT_LIST_DIR}/Blast)

set(${MY_NAME}_INCLUDE_DIR ${_PACKAGE_DIR}/sdk/common
                           ${_PACKAGE_DIR}/sdk/extensions/assetutils/include
                           ${_PACKAGE_DIR}/sdk/extensions/authoring/include
                           ${_PACKAGE_DIR}/sdk/extensions/exporter/include
                           ${_PACKAGE_DIR}/sdk/extensions/physx/include
                           ${_PACKAGE_DIR}/sdk/extensions/serialization/include
                           ${_PACKAGE_DIR}/sdk/extensions/shaders/include
                           ${_PACKAGE_DIR}/sdk/extensions/stress/include
                           ${_PACKAGE_DIR}/sdk/globals/include
                           ${_PACKAGE_DIR}/sdk/lowlevel/include
                           ${_PACKAGE_DIR}/sdk/toolkit/include)

set(_LIBS_DIR ${_PACKAGE_DIR}/lib)
set(_DLLS_DIR ${_PACKAGE_DIR}/bin)
if(${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${MY_NAME}_LIBRARIES
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlast_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtAssetUtils_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtAuthoring_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtExporter_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtImport_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtPhysX_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtPxSerialization_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtSerialization_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtShaders_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtStress_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtTkSerialization_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastGlobals_x64.lib
        ${_LIBS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastTk_x64.lib)

    set(${MY_NAME}_RUNTIME_DEPENDENCIES
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlast_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtAssetUtils_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtAuthoring_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtExporter_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtPhysX_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtPxSerialization_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtSerialization_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtShaders_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtStress_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastExtTkSerialization_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastGlobals_x64.dll
        ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/NvBlastTk_x64.dll
    )
    
    # When building O3DE monolithicaly the library PhysXFoundation_64.dll won't be present since
    # PhysX SDK uses a static version of it. Because of this Blast will provide the dll in this case, which
    # is needed by its extended tools libraries NvBlastExtPhysX_x64.dll and NvBlastExtPxSerialization_x64.dll.
    if(LY_MONOLITHIC_GAME)
        list(APPEND ${MY_NAME}_RUNTIME_DEPENDENCIES
            ${_DLLS_DIR}/vc15win64-cmake/$<LOWER_CASE:$<CONFIG>>/PhysXFoundation_64.dll
        )
    endif()
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LIBRARIES})
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})
if(DEFINED ${MY_NAME}_RUNTIME_DEPENDENCIES)
    ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})
endif()

set(${MY_NAME}_FOUND True)
