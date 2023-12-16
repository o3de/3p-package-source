#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.20)


# The 3P package uses an O3DE custom cmake function 'ly_target_include_system_directories'. Duplicate it here 
function(ly_target_include_system_directories)

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs)

    cmake_parse_arguments(ly_target_include_system_directories "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ly_target_include_system_directories_TARGET)
        message(FATAL_ERROR "Target not provided")
    endif()

    target_compile_options(${ly_target_include_system_directories_TARGET}
        INTERFACE
            ${LY_CXX_SYSTEM_INCLUDE_CONFIGURATION_FLAG}
    )

    target_include_directories(${ly_target_include_system_directories_TARGET} SYSTEM ${ly_target_include_system_directories_UNPARSED_ARGUMENTS})
endfunction()


# The 3P package uses an O3DE custom cmake function 'ly_add_dependencies'. It is used to mark dependencies that need to be
# copied to the final executable path, but that is not needed here, so just stub out
function(ly_add_dependencies TARGET)

endfunction()


PROJECT(test_AWSGameLift VERSION 1.0 LANGUAGES CXX)

find_package(OpenSSL)
find_package(AWSGameLiftServerSDK)

add_executable(test_AWSGameLift test_AWSGameLiftServer.cpp)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)
if (CMAKE_USE_PTHREADS_INIT)
    target_link_libraries(test_AWSGameLift INTERFACE ${CMAKE_THREAD_LIBS_INIT})
else()
    message(WARNING "CMAKE_USE_PTHREADS_INIT is undefined!")
endif ()

target_link_libraries(test_AWSGameLift PRIVATE 3rdParty::OpenSSL 3rdParty::AWSGameLiftServerSDK)
