#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(QT_LIB_PATH ${QT_PATH}/lib)

list(APPEND QT5_COMPONENTS
    DBus
    XcbQpa
)

function(ly_qt_configuration_mapping in_config out_config)
    set(${out_config} RELEASE PARENT_SCOPE)
endfunction()
