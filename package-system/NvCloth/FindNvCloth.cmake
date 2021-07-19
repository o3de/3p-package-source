#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "NvCloth")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(_PACKAGE_DIR ${CMAKE_CURRENT_LIST_DIR}/NvCloth)

set(${MY_NAME}_INCLUDE_DIR ${_PACKAGE_DIR}/NvCloth/include 
                           ${_PACKAGE_DIR}/NvCloth/extensions/include
                           ${_PACKAGE_DIR}/PxShared/include)

# It's important to define NV_CLOTH_IMPORT and PX_CALL_CONV without
# giving them a value, otherwise they will cause compilation issues
# because they are used as prefix for classes and functions.
set(${MY_NAME}_COMPILE_DEFINITIONS NV_CLOTH_IMPORT= PX_CALL_CONV= )

set(_LIBS_DIR ${_PACKAGE_DIR}/NvCloth/lib)
if(${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${MY_NAME}_LIBRARY
        ${_LIBS_DIR}/vc141win64-cmake/NvCloth$<$<NOT:$<CONFIG:Release>>:$<UPPER_CASE:$<CONFIG>>>_x64.lib)

    # The NvCloth libs are compiled using /GL, which lld-link does not support.
    set(${MY_NAME}_LINK_OPTIONS
        $<$<STREQUAL:${PAL_TRAIT_COMPILER_ID},Clang>:-fuse-ld=link.exe>)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${MY_NAME}_LIBRARY
        ${_LIBS_DIR}/linux64-cmake/libNvCloth$<$<NOT:$<CONFIG:Release>>:$<UPPER_CASE:$<CONFIG>>>.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(${MY_NAME}_LIBRARY
        ${_LIBS_DIR}/osx64-cmake/libNvCloth$<$<NOT:$<CONFIG:Release>>:$<UPPER_CASE:$<CONFIG>>>.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "iOS")
    set(${MY_NAME}_LIBRARY
        ${_LIBS_DIR}/ios-cmake/libNvCloth$<$<NOT:$<CONFIG:Release>>:$<UPPER_CASE:$<CONFIG>>>.a)
elseif(${PAL_PLATFORM_NAME} STREQUAL "Android")
    set(${MY_NAME}_LIBRARY
        ${_LIBS_DIR}/android-arm64-v8a-cmake/libNvCloth$<$<NOT:$<CONFIG:Release>>:$<UPPER_CASE:$<CONFIG>>>.a)
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LIBRARY})
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})
if(DEFINED ${MY_NAME}_LINK_OPTIONS)
    target_link_options(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LINK_OPTIONS})
endif()

set(${MY_NAME}_FOUND True)
