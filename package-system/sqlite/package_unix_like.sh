#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


PACKAGE_BASE=$TARGET_INSTALL_ROOT

INSTALL_SOURCE=$TEMP_FOLDER/build

cp $TEMP_FOLDER/src/copyright.txt $PACKAGE_BASE/

# Copy extra source files just for reference
cp $INSTALL_SOURCE/shell.c $PACKAGE_BASE/
cp $INSTALL_SOURCE/sqlite3.c $PACKAGE_BASE/

# Copy the header files
cp $INSTALL_SOURCE/sqlite3ext.h $PACKAGE_BASE/
cp $INSTALL_SOURCE/sqlite3.h $PACKAGE_BASE/

# Copy the debug and release static libraries
mkdir $PACKAGE_BASE/lib

mkdir $PACKAGE_BASE/lib
cp $TEMP_FOLDER/install/lib/libsqlite3.a $PACKAGE_BASE/lib/
cp $TEMP_FOLDER/install/lib/libsqlite3.la $PACKAGE_BASE/lib/
cp -r $TEMP_FOLDER/install/lib/pkgconfig $PACKAGE_BASE/lib/

exit 0
