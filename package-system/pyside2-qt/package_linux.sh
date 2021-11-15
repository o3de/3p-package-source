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

INSTALL_SOURCE=$TEMP_FOLDER/src/pyside3a_install/`ls $TEMP_FOLDER/src/pyside3a_install`
echo INSTALL_SOURCE=$INSTALL_SOURCE

# Copy the LICENSE and README files
cp $TEMP_FOLDER/src/LICENSE.* $PACKAGE_BASE/
cp $TEMP_FOLDER/src/README.* $PACKAGE_BASE/

# Copy the Pyside2 package, and create major version sylmink
cp -r $INSTALL_SOURCE/lib/python3.7/site-packages/PySide2 $PACKAGE_BASE
cp $INSTALL_SOURCE/lib/libpyside2.abi3.so.5.14.2.3 $PACKAGE_BASE/PySide2/
ln -s libpyside2.abi3.so.5.14.2.3 $PACKAGE_BASE/PySide2/libpyside2.abi3.so.5.14

# Copy the shiboken2 package, and create major version sylmink
cp -r $INSTALL_SOURCE/lib/python3.7/site-packages/shiboken2 $PACKAGE_BASE
cp $INSTALL_SOURCE/lib/libshiboken2.abi3.so.5.14.2.3 $PACKAGE_BASE/shiboken2/
ln -s libshiboken2.abi3.so.5.14.2.3 $PACKAGE_BASE/shiboken2/libshiboken2.abi3.so.5.14

# Patch the Pyside2 shared library to resolve shiboken2
$TEMP_FOLDER/src/patchelf --set-rpath ../shiboken2:\$ORIGIN $PACKAGE_BASE/PySide2/libpyside2.abi3.so.5.14.2.3

# Patch the shiboken2.abi.so module to resolve the libshiboken at ORIGIN
$TEMP_FOLDER/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/shiboken2/shiboken2.abi3.so

# Add additional files needed for pip install
cp $TEMP_FOLDER/../__init__.py $PACKAGE_BASE/
cp $TEMP_FOLDER/../setup.py $PACKAGE_BASE/

# Create the additional folder for cmake
mkdir $PACKAGE_ROOT/Platform
mkdir $PACKAGE_ROOT/Platform/Linux
cp $TEMP_FOLDER/../pyside2_linux.cmake $PACKAGE_ROOT/Platform/Linux/

exit 0
