#
# Copyright (c) Contributors to the Open 3D Engine Project.
#  For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# force this into config mode, so that it uses the config files instead of module files.
set(Python_DIR ${CMAKE_CURRENT_LIST_DIR})
find_package(Python 3.7.12 REQUIRED CONFIG)
