#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

PACKAGE_BASE=$TARGET_INSTALL_ROOT
echo PACKAGE_BASE=$PACKAGE_BASE

# Add additional files needed for pip install
cp $TEMP_FOLDER/../__init__.py $PACKAGE_BASE/lib/python3.10/site-packages/
cp $TEMP_FOLDER/../setup.py $PACKAGE_BASE/lib/python3.10/site-packages/
cp $TEMP_FOLDER/../LICENSES.txt $PACKAGE_BASE/

INSTALL_SOURCE=$TEMP_FOLDER/build
echo INSTALL_SOURCE=$INSTALL_SOURCE

exit 0
