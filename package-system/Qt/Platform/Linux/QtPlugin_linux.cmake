#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Not plugins per-se but extra files associated to each component
foreach(component ${QT6_COMPONENTS})
    if(TARGET Qt6::${component})

        # add the IMPORTED_SONAME files as files to copy
        unset(extra_target_files)
        get_target_property(imported_soname Qt6::${component} IMPORTED_SONAME_RELEASE)
        if(imported_soname)
            list(APPEND extra_target_files ${QT_LIB_PATH}/${imported_soname})
        endif()
        if(extra_target_files)
            ly_add_target_files(TARGETS Qt6::${component} FILES ${extra_target_files})
        endif()

    endif()
endforeach()

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
        ${QT_PATH}/plugins/platforms/libqwayland.so
        ${QT_PATH}/plugins/platforms/libqxcb.so
    OUTPUT_SUBDIRECTORY platforms
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/xcbglintegrations/libqxcb-glx-integration.so
    OUTPUT_SUBDIRECTORY xcbglintegrations
)

# Wayland client plugin set: the wayland QPA plugin above needs at least one
# shell integration to map windows (xdg-shell on modern desktop compositors),
# the decoration plugins for client-side window decorations (compositors like
# GNOME's Mutter do not draw server-side decorations), and the graphics
# integrations for the hardware (EGL) and shared-memory buffer paths.
ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/wayland-shell-integration/libfullscreen-shell-v1.so
        ${QT_PATH}/plugins/wayland-shell-integration/libivi-shell.so
        ${QT_PATH}/plugins/wayland-shell-integration/libqt-shell.so
        ${QT_PATH}/plugins/wayland-shell-integration/libwl-shell-plugin.so
        ${QT_PATH}/plugins/wayland-shell-integration/libxdg-shell.so
    OUTPUT_SUBDIRECTORY wayland-shell-integration
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/wayland-decoration-client/libadwaita.so
        ${QT_PATH}/plugins/wayland-decoration-client/libbradient.so
    OUTPUT_SUBDIRECTORY wayland-decoration-client
)

ly_add_target_files(TARGETS 3rdParty::Qt::Gui::Plugins
    FILES
        ${QT_PATH}/plugins/wayland-graphics-integration-client/libdrm-egl-server.so
        ${QT_PATH}/plugins/wayland-graphics-integration-client/libqt-plugin-wayland-egl.so
        ${QT_PATH}/plugins/wayland-graphics-integration-client/libshm-emulation-server.so
    OUTPUT_SUBDIRECTORY wayland-graphics-integration-client
)

ly_add_dependencies(3rdParty::Qt::Widgets::Plugins Qt6::DBus)
ly_add_target_files(TARGETS 3rdParty::Qt::Widgets::Plugins
    FILES
        ${QT_PATH}/lib/libQt6XcbQpa.so
        ${QT_PATH}/lib/libQt6WaylandClient.so
        ${QT_PATH}/lib/libQt6WlShellIntegration.so
)
