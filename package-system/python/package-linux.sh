#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Install the python build artifacts 
cp -r temp/build/include $TARGET_INSTALL_ROOT
cp -r temp/build/bin $TARGET_INSTALL_ROOT
cp -r temp/build/lib $TARGET_INSTALL_ROOT
cp -r temp/build/share $TARGET_INSTALL_ROOT
cp temp/build/LICENSE $TARGET_INSTALL_ROOT/
cp temp/build/LICENSE.OPENSSL $TARGET_INSTALL_ROOT/

# Install additional cmake files
cp linux_x64/python-config-version.cmake $TARGET_INSTALL_ROOT/../
cp linux_x64/python-config.cmake $TARGET_INSTALL_ROOT/../

exit 0 
