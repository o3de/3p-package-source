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
INSTALL_SOURCE=$TEMP_FOLDER/src/pyside3a_install/`ls $TEMP_FOLDER/src/pyside3a_install`
echo INSTALL_SOURCE=$INSTALL_SOURCE

# Copy the LICENSE and README files
echo cp $TEMP_FOLDER/src/LICENSE.FDL $PACKAGE_BASE/
cp $TEMP_FOLDER/src/LICENSE.FDL $PACKAGE_BASE/
echo copy $TEMP_FOLDER/src/LICENSE.GPLv3 $PACKAGE_BASE/
cp $TEMP_FOLDER/src/LICENSE.GPLv3 $PACKAGE_BASE/
echo copy $TEMP_FOLDER/src/LICENSE.GPLv3-EXCEPT $PACKAGE_BASE/
cp $TEMP_FOLDER/src/LICENSE.GPLv3-EXCEPT $PACKAGE_BASE/
echo copy $TEMP_FOLDER/src/LICENSE.LGPLv3 $PACKAGE_BASE/
cp $TEMP_FOLDER/src/LICENSE.LGPLv3 $PACKAGE_BASE/
echo copy $TEMP_FOLDER/../LICENSES.txt $PACKAGE_BASE/
cp $TEMP_FOLDER/../LICENSES.txt $PACKAGE_BASE/
echo copy $TEMP_FOLDER/src/README.* $PACKAGE_BASE/
cp $TEMP_FOLDER/src/README.* $PACKAGE_BASE/

cp -r $INSTALL_SOURCE/bin $PACKAGE_BASE
cp -r $INSTALL_SOURCE/include $PACKAGE_BASE
cp -r $INSTALL_SOURCE/lib $PACKAGE_BASE
cp -r $INSTALL_SOURCE/share $PACKAGE_BASE

# RPATH fixes
$TEMP_FOLDER/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/libpyside2.abi3.so.5.15.2.1
$TEMP_FOLDER/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/libshiboken2.abi3.so.5.15.2.1
$TEMP_FOLDER/src/patchelf --set-rpath \$ORIGIN $PACKAGE_BASE/lib/python3.10/site-packages/shiboken2/shiboken2.abi3.so

# Add additional files needed for pip install
cp $TEMP_FOLDER/../__init__.py $PACKAGE_BASE/
cp $TEMP_FOLDER/../setup.py $PACKAGE_BASE/

exit 0
