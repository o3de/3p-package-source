#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES ${QT_PATH}/plugins/iconengines/qsvgicon.dll
    OUTPUT_SUBDIRECTORY iconengines
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES 
        ${QT_PATH}/plugins/imageformats/qgif.dll
        ${QT_PATH}/plugins/imageformats/qicns.dll
        ${QT_PATH}/plugins/imageformats/qico.dll
        ${QT_PATH}/plugins/imageformats/qjpeg.dll
        ${QT_PATH}/plugins/imageformats/qsvg.dll
        ${QT_PATH}/plugins/imageformats/qtga.dll
        ${QT_PATH}/plugins/imageformats/qtiff.dll
        ${QT_PATH}/plugins/imageformats/qwbmp.dll
        ${QT_PATH}/plugins/imageformats/qwebp.dll
    OUTPUT_SUBDIRECTORY imageformats
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/platforms/qminimal.dll
        ${QT_PATH}/plugins/platforms/qwindows.dll
    OUTPUT_SUBDIRECTORY platforms
)

ly_add_target_files(TARGETS 3rdParty::Qt::Widgets::Plugins
    FILES ${QT_PATH}/plugins/styles/qmodernwindowsstyle.dll
    OUTPUT_SUBDIRECTORY styles
)
