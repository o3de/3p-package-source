#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

ly_add_target_files(TARGETS 3rdParty::Qt::Network::Plugins
    FILES ${QT_PATH}/plugins/bearer/qgenericbearer$<$<CONFIG:debug>:d>.dll
    OUTPUT_SUBDIRECTORY bearer
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES ${QT_PATH}/plugins/iconengines/qsvgicon$<$<CONFIG:debug>:d>.dll
    OUTPUT_SUBDIRECTORY iconengines
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES 
        ${QT_PATH}/plugins/imageformats/qgif$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qicns$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qico$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qjpeg$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qsvg$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qtga$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qtiff$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qwbmp$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/imageformats/qwebp$<$<CONFIG:debug>:d>.dll
    OUTPUT_SUBDIRECTORY imageformats
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/platforms/qminimal$<$<CONFIG:debug>:d>.dll
        ${QT_PATH}/plugins/platforms/qwindows$<$<CONFIG:debug>:d>.dll
    OUTPUT_SUBDIRECTORY platforms
)

ly_add_target_files(TARGETS 3rdParty::Qt::Widgets::Plugins
    FILES ${QT_PATH}/plugins/styles/qwindowsvistastyle$<$<CONFIG:debug>:d>.dll
    OUTPUT_SUBDIRECTORY styles
)

