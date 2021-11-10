#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
set(pyside2_SHARED_LIB_PATH ${BASE_PATH}/windows/$<IF:$<CONFIG:Debug>,debug,release>)

# Adding Shared libs
set(pyside2_RUNTIME_DEPENDENCIES
    ${pyside2_SHARED_LIB_PATH}/PySide2/$<IF:$<CONFIG:Debug>,pyside2_d.cp37-win_amd64.dll,pyside2.abi3.dll>
    ${pyside2_SHARED_LIB_PATH}/shiboken2/$<IF:$<CONFIG:Debug>,shiboken2_d.cp37-win_amd64.dll,shiboken2.abi3.dll>
    ${pyside2_SHARED_LIB_PATH}/shiboken2/$<IF:$<CONFIG:Debug>,shiboken2_d.cp37-win_amd64.pyd,shiboken2.pyd>)

