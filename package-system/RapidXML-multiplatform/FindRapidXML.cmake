#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(TARGET_NAME "RapidXML")
set(TARGET_WITH_NAMESPACE "3rdParty::${TARGET_NAME}")
set(${TARGET_NAME}_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/${TARGET_NAME}/include)

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${TARGET_NAME}_INCLUDE_DIR})
set(${TARGET_NAME}_FOUND True)
