#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

TIFF_PACKAGE=tiff-4.2.0.15-rev3-linux
ZLIB_PACKAGE=zlib-1.2.11-rev5-linux
OPENSSL_PACKAGE=OpenSSL-1.1.1t-rev1-linux

./build-linux.sh $TIFF_PACKAGE $ZLIB_PACKAGE $OPENSSL_PACKAGE

exit $?
