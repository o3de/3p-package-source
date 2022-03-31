#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Not plugins per-se but extra files associated to each component
foreach(component ${QT5_COMPONENTS})
    if(TARGET Qt5::${component})

        # add the IMPORTED_SONAME files as files to copy
        unset(extra_target_files)
        get_target_property(imported_soname Qt5::${component} IMPORTED_SONAME_RELEASE)
        if(imported_soname)
            list(APPEND extra_target_files ${QT_LIB_PATH}/${imported_soname})
        endif()
        if(extra_target_files)
            ly_add_target_files(TARGETS Qt5::${component} FILES ${extra_target_files})
        endif()

    endif()
endforeach()

ly_add_target_files(TARGETS 3rdParty::Qt::Network::Plugins
    FILES ${QT_PATH}/plugins/bearer/libqgenericbearer.so
    OUTPUT_SUBDIRECTORY bearer
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES ${QT_PATH}/plugins/iconengines/libqsvgicon.so
    OUTPUT_SUBDIRECTORY iconengines
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES 
        ${QT_PATH}/plugins/imageformats/libqgif.so
        ${QT_PATH}/plugins/imageformats/libqicns.so
        ${QT_PATH}/plugins/imageformats/libqico.so
        ${QT_PATH}/plugins/imageformats/libqjpeg.so
        ${QT_PATH}/plugins/imageformats/libqsvg.so
        ${QT_PATH}/plugins/imageformats/libqtga.so
        ${QT_PATH}/plugins/imageformats/libqtiff.so
        ${QT_PATH}/plugins/imageformats/libqwbmp.so
        ${QT_PATH}/plugins/imageformats/libqwebp.so
    OUTPUT_SUBDIRECTORY imageformats
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/platforms/libqminimal.so
        ${QT_PATH}/plugins/platforms/libqxcb.so
    OUTPUT_SUBDIRECTORY platforms
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/xcbglintegrations/libqxcb-glx-integration.so
    OUTPUT_SUBDIRECTORY xcbglintegrations
)

ly_add_dependencies(3rdParty::Qt::Widgets::Plugins Qt5::DBus)
ly_add_dependencies(3rdParty::Qt::Widgets::Plugins Qt5::XcbQpa)
