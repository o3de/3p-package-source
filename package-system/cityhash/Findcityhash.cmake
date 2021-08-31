#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#

# this file actually ingests the library and defines targets.
set(TARGET_WITH_NAMESPACE "3rdParty::cityhash")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(MY_NAME "cityhash")

set(${MY_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/cityhash/src)
set(${MY_NAME}_LIBS_DIR ${CMAKE_CURRENT_LIST_DIR}/cityhash/build)

if (${PAL_PLATFORM_NAME} STREQUAL "Android")
    set(${MY_NAME}_ANDROID_BASE    ${${MY_NAME}_LIBS_DIR}/win_x64/android_ndk_r12/android-21/arm64-v8a/clang-3.8)
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_ANDROID_BASE}/debug/libcityhash.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_ANDROID_BASE}/release/libcityhash.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "iOS")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/osx/ios-clang-703.0.31/debug/libcityhash.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/osx/ios-clang-703.0.31/release/libcityhash.a)	
elseif (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/linux/clang-3.8/debug/libcityhash.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/linux/clang-3.8/release/libcityhash.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Mac")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/osx/darwin-clang-703.0.31/debug/libcityhash.a)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/osx/darwin-clang-703.0.31/release/libcityhash.a)
elseif (${PAL_PLATFORM_NAME} STREQUAL "Windows")
    set(${MY_NAME}_LIBRARY_DEBUG   ${${MY_NAME}_LIBS_DIR}/win_x64/vc140/debug/cityhash.lib)
    set(${MY_NAME}_LIBRARY_RELEASE ${${MY_NAME}_LIBS_DIR}/win_x64/vc140/release/cityhash.lib)	
endif()

# we set it to a generator expression for multi-config situations:
set(${MY_NAME}_LIBRARY  
    "$<$<CONFIG:profile>:${${MY_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:Release>:${${MY_NAME}_LIBRARY_RELEASE}>"
    "$<$<CONFIG:Debug>:${${MY_NAME}_LIBRARY_DEBUG}>")

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
target_link_libraries(${TARGET_WITH_NAMESPACE} 
                INTERFACE ${${MY_NAME}_LIBRARY}
                        )

set(${MY_NAME}_FOUND True)