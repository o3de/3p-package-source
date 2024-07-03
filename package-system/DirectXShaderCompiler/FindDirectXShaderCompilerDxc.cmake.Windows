#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "DirectXShaderCompilerDxc")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(output_subfolder "Builders/DirectXShaderCompiler")
set(${MY_NAME}_BINARY_DIR ${CMAKE_CURRENT_LIST_DIR}/${MY_NAME}/bin)

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

set(${MY_NAME}_RUNTIME_DEPENDENCIES
		${${MY_NAME}_BINARY_DIR}/Release/dxc.exe
		${${MY_NAME}_BINARY_DIR}/Release/dxil.dll
		${${MY_NAME}_BINARY_DIR}/Release/dxcompiler.dll)
ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} OUTPUT_SUBDIRECTORY ${output_subfolder} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})


set(${MY_NAME}_FOUND True)