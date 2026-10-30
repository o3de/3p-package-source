#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

cmake_minimum_required(VERSION 3.25)

set(CMAKE_CONFIGURATION_TYPES debug checked profile release)
set_property(GLOBAL PROPERTY XCODE_EMIT_EFFECTIVE_PLATFORM_NAME OFF)

project(PhysX5PackageConsumer LANGUAGES CXX)

find_package(PhysX5 REQUIRED MODULE)

if(TARGET PhysX::PhysXCooking OR TARGET PhysX::PhysXVehicle2)
    message(FATAL_ERROR "Unexpected removed PhysX targets")
endif()

if(EXPECT_GPU)
    if(NOT TARGET PhysX::PhysXGpu OR NOT TARGET PhysX::PVDRuntime)
        message(FATAL_ERROR "GPU runtime or OmniPVD dependency missing")
    endif()

    file(GENERATE
        OUTPUT "${CMAKE_BINARY_DIR}/$<CONFIG>-gpu.txt"
        CONTENT "$<TARGET_FILE:PhysX::PhysXGpu>"
    )
elseif(TARGET PhysX::PhysXGpu)
    message(FATAL_ERROR "Unexpected GPU runtime on a CPU-only platform")
endif()

get_target_property(physx_dependencies PhysX::physx_lib INTERFACE_LINK_LIBRARIES)
if(physx_dependencies MATCHES "PhysXGpu|CUDA::")
    message(FATAL_ERROR "CPU consumer requires the GPU runtime or CUDA development tools")
endif()

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE 3rdParty::PhysX5)
target_compile_definitions(consumer PRIVATE
    "$<$<NOT:$<CONFIG:debug>>:NDEBUG>"
)

file(GENERATE
    OUTPUT "${CMAKE_BINARY_DIR}/$<CONFIG>-consumer.txt"
    CONTENT "$<TARGET_FILE:consumer>"
)
file(GENERATE
    OUTPUT "${CMAKE_BINARY_DIR}/$<CONFIG>-library.txt"
    CONTENT "$<TARGET_FILE:PhysX::PhysX>"
)
