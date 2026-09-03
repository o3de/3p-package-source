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

case "$(uname -m)" in
    x86_64)
        LIBCLANG_PACKAGE=libclang-release_20.1.3-based-linux-Ubuntu22.04-gcc11.4-x86_64
        ;;
    aarch64)
        LIBCLANG_PACKAGE=libclang-release_20.1.3-based-linux-Debian-11.6-gcc10.2-arm64
        ;;
    *)
        echo "Unsupported Linux architecture: $(uname -m)"
        exit 1
        ;;
esac

# Add additional files needed for pip install
INSTALL_SOURCE=$TEMP_FOLDER/src/build/testenva/install

echo Copy the LICENSE and README files
cp $TEMP_FOLDER/src/LICENSES/* $PACKAGE_BASE/
cp $TEMP_FOLDER/src/README.* $PACKAGE_BASE/

echo Copy the bin folder
mkdir -p $PACKAGE_BASE/bin
cp -r $INSTALL_SOURCE/bin/* $PACKAGE_BASE/bin

echo Patching shiboken6 to use relative library paths
patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib' $PACKAGE_BASE/bin/shiboken6

echo Copy the lib folder
mkdir -p $PACKAGE_BASE/lib
cp -r $INSTALL_SOURCE/lib/* $PACKAGE_BASE/lib/

echo Copy libclang and its license file
LIBCLANG_ROOT="$TEMP_FOLDER/$LIBCLANG_PACKAGE/libclang"
cp "$LIBCLANG_ROOT/lib/libclang.so.20.1.3" "$PACKAGE_BASE/lib/libclang.so.20.1"
cp "$LIBCLANG_ROOT/include/llvm/Support/LICENSE.TXT" "$PACKAGE_BASE/LICENSE.LIBCLANG.TXT"

echo 'Patching the RPATHS of all site-packages shared libraries to remove absolute paths and set them to $ORIGIN'
find $PACKAGE_BASE/lib/python3.10/site-packages/PySide6/ -name "*.so*" -exec patchelf --set-rpath '$ORIGIN:$ORIGIN/../shiboken6' {} \;

echo Make the include folder
mkdir -p $PACKAGE_BASE/include

echo Copy the PySide6 headers and libraries
mkdir -p $PACKAGE_BASE/include/PySide6
cp -r $INSTALL_SOURCE/PySide6/include/* $PACKAGE_BASE/include/PySide6/
cp $INSTALL_SOURCE/PySide6/libpyside6.abi3.so $PACKAGE_BASE/lib/
cp $INSTALL_SOURCE/PySide6/libpyside6.abi3.so.6.11 $PACKAGE_BASE/lib/
patchelf --set-rpath '$ORIGIN:$ORIGIN/../shiboken6' $PACKAGE_BASE/lib/libpyside6.abi3.so.6.11

echo Copy the shiboken6 headers and libraries
mkdir -p $PACKAGE_BASE/include/shiboken6
cp -r $INSTALL_SOURCE/shiboken6/include/* $PACKAGE_BASE/include/shiboken6/
cp $INSTALL_SOURCE/shiboken6/libshiboken6.abi3.so $PACKAGE_BASE/lib/
cp $INSTALL_SOURCE/shiboken6/libshiboken6.abi3.so.6.11 $PACKAGE_BASE/lib/
patchelf --set-rpath '$ORIGIN:$ORIGIN/../shiboken6' $PACKAGE_BASE/lib/libshiboken6.abi3.so.6.11

# Add additional files needed for pip install
cp $TEMP_FOLDER/../__init__.py $PACKAGE_BASE/lib/python3.10/site-packages/
cp $TEMP_FOLDER/../setup.py $PACKAGE_BASE/lib/python3.10/site-packages/

# Copy the share folder
mkdir -p $PACKAGE_BASE/share
cp -r $INSTALL_SOURCE/share/* $PACKAGE_BASE/share/

exit 0
