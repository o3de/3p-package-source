#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(QT_LIB_PATH ${QT_PATH}/lib)

# Suppress the following warnings about using private Qt modules
#
#  This project is using headers of the GuiPrivate module and will therefore
#  be tied to this specific Qt module build version.  Running this project
#  against other versions of the Qt modules may crash at any arbitrary point.
#  This is not a bug, but a result of using Qt internals.  You have been
#  warned!
set(QT_NO_PRIVATE_MODULE_WARNING ON)

list(APPEND QT6_COMPONENTS
    DBus
    GuiPrivate
    WaylandClient
)

function(ly_qt_configuration_mapping in_config out_config)
    set(${out_config} RELEASE PARENT_SCOPE)
endfunction()
