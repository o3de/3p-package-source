#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(LIB_NAME "d3dx12")
set(TARGET_WITH_NAMESPACE "3rdParty::${LIB_NAME}")
set(${LIB_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/d3dx12/include)

# declare the target so that others can 'depend on it'
add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_INCLUDE_DIR})
set(${LIB_NAME}_FOUND True)