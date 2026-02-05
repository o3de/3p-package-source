#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

ly_add_target_files(TARGETS 3rdParty::Qt::Network::Plugins
    FILES ${QT_PATH}/plugins/bearer/libqgenericbearer.dylib
    OUTPUT_SUBDIRECTORY bearer
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES ${QT_PATH}/plugins/iconengines/libqsvgicon.dylib
    OUTPUT_SUBDIRECTORY iconengines
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES 
        ${QT_PATH}/plugins/imageformats/libqgif.dylib
        ${QT_PATH}/plugins/imageformats/libqicns.dylib
        ${QT_PATH}/plugins/imageformats/libqico.dylib
        ${QT_PATH}/plugins/imageformats/libqjpeg.dylib
        ${QT_PATH}/plugins/imageformats/libqsvg.dylib
        ${QT_PATH}/plugins/imageformats/libqtga.dylib
        ${QT_PATH}/plugins/imageformats/libqtiff.dylib
        ${QT_PATH}/plugins/imageformats/libqwbmp.dylib
        ${QT_PATH}/plugins/imageformats/libqwebp.dylib
    OUTPUT_SUBDIRECTORY imageformats
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES 
        ${QT_PATH}/plugins/platforms/libqminimal.dylib
        ${QT_PATH}/plugins/platforms/libqcocoa.dylib
    OUTPUT_SUBDIRECTORY platforms
)

ly_add_target_files(TARGETS 3rdParty::Qt::Widgets::Plugins
    FILES ${QT_PATH}/plugins/styles/libqmacstyle.dylib
    OUTPUT_SUBDIRECTORY styles
)
