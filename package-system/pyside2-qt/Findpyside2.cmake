#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
     
# this file actually ingests the library and defines targets.
     
set(MY_NAME "pyside2")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()
     
add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
     
ly_pip_install_local_package_editable(${CMAKE_CURRENT_LIST_DIR}/pyside2 pyside2)
     
set(${MY_NAME}_FOUND True)
