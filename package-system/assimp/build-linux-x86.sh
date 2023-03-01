#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

ZLIB_PACKAGE=zlib-1.2.11-rev5-linux

./build-linux.sh $ZLIB_PACKAGE || exit 1

exit 0
