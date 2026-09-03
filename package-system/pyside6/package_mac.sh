#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

set -euo pipefail

echo TEMP_FOLDER=$TEMP_FOLDER
echo TARGET_INSTALL_ROOT=$TARGET_INSTALL_ROOT

PACKAGE_BASE=$TARGET_INSTALL_ROOT

# Add additional files needed for pip install
INSTALL_SOURCE=$TEMP_FOLDER/src/build/testenva/install

echo Copy the LICENSE and README files
cp $TEMP_FOLDER/src/LICENSES/* $PACKAGE_BASE/
cp $TEMP_FOLDER/src/README.* $PACKAGE_BASE/

echo Copy the bin folder
mkdir -p $PACKAGE_BASE/bin
cp -r $INSTALL_SOURCE/bin/* $PACKAGE_BASE/bin

echo Making shiboken6 relocatable
LIBCLANG_ROOT="$TEMP_FOLDER/libclang-release_20.1.3-based-macos-universal/libclang"
QT_LIBRARY_PATH="$TEMP_FOLDER/qt-6.11.2-rev1-mac-arm64/qt/lib"

make_shiboken_relocatable() {
    local shiboken_binary=$1
    install_name_tool -delete_rpath "$LIBCLANG_ROOT/lib" "$shiboken_binary"
    install_name_tool -delete_rpath "$QT_LIBRARY_PATH" "$shiboken_binary"
    install_name_tool -add_rpath @loader_path/../lib "$shiboken_binary"
    install_name_tool -add_rpath ./../lib "$shiboken_binary"
}

make_shiboken_relocatable "$PACKAGE_BASE/bin/shiboken6"

echo Copy the lib folder
mkdir -p $PACKAGE_BASE/lib
cp -r $INSTALL_SOURCE/lib/* $PACKAGE_BASE/lib/
cp "$LIBCLANG_ROOT/lib/libclang.dylib" "$PACKAGE_BASE/lib/"
cp "$LIBCLANG_ROOT/include/llvm/Support/LICENSE.TXT" "$PACKAGE_BASE/LICENSE.LIBCLANG.TXT"


echo Make the include folder
mkdir -p $PACKAGE_BASE/include

echo Copy the PySide6 headers 
mkdir -p $PACKAGE_BASE/include/PySide6
cp -r $INSTALL_SOURCE/PySide6/include/* $PACKAGE_BASE/include/PySide6/

echo Copy the shiboken6 headers 
mkdir -p $PACKAGE_BASE/include/shiboken6
cp -r $INSTALL_SOURCE/shiboken6/include/* $PACKAGE_BASE/include/shiboken6/

echo Update duplicates with symlinks for the dylibs
pushd $PACKAGE_BASE/lib/
rm libpyside6.abi3.dylib
ln -s libpyside6.abi3.6.11.dylib libpyside6.abi3.dylib
rm libshiboken6.abi3.dylib
ln -s libshiboken6.abi3.6.11.dylib libshiboken6.abi3.dylib
popd

echo Copy the shiboken6_generator files
mkdir -p $PACKAGE_BASE/shiboken6_generator
cp -r $INSTALL_SOURCE/shiboken6_generator/* $PACKAGE_BASE/shiboken6_generator/
make_shiboken_relocatable "$PACKAGE_BASE/shiboken6_generator/shiboken6"

# Add additional files needed for pip install
cp $TEMP_FOLDER/../__init__.py $PACKAGE_BASE/lib/python3.10/site-packages/
cp $TEMP_FOLDER/../setup.py $PACKAGE_BASE/lib/python3.10/site-packages/

# Copy the share folder
mkdir -p $PACKAGE_BASE/share
cp -r $INSTALL_SOURCE/share/* $PACKAGE_BASE/share/

exit 0
