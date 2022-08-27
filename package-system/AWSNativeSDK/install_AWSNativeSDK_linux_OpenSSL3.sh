#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

src_path=temp/src
bld_path=temp/build
inst_path=temp/install

out_bin_path=$TARGET_INSTALL_ROOT/bin
mkdir -p $out_bin_path/Debug
mkdir -p $out_bin_path/Release

out_include_path=$TARGET_INSTALL_ROOT/include
mkdir -p $out_include_path

out_lib_path=$TARGET_INSTALL_ROOT/lib
mkdir -p $out_lib_path/Debug
mkdir -p $out_lib_path/Release

copy_shared_and_static_libs() {
    local bld_type=$1
    echo "Copying shared .so to $out_bin_path/$bld_type"
    cp -f "$inst_path/${bld_type}_Shared/lib/"*".so"* $out_bin_path/$bld_type/ || (echo "Copying shared .so to $out_bin_path/$bld_type failed" ; exit 1)

    echo "Copying static .a to $out_lib_path/$bld_type"
    cp -f "$inst_path/${bld_type}_Static/lib/"*".a" $out_lib_path/$bld_type/ || (echo "Copying static .a to $out_lib_path/$bld_type failed" ; exit 1)
}

# Debug
copy_shared_and_static_libs Debug || exit 1

# Release
copy_shared_and_static_libs Release || exit 1

echo "Copying include headers to $out_include_path"
cp -f -R "$inst_path/Release_Static/include/"* $out_include_path/ || (echo "Copying include headers to $out_include_path failed" ; exit 1)

echo "Copying LICENSE.txt to $TARGET_INSTALL_ROOT"
cp -f $src_path/LICENSE.txt $TARGET_INSTALL_ROOT/ || (echo "Copying LICENSE.txt to $TARGET_INSTALL_ROOT failed" ; exit 1)

echo "Custom Install for AWSNativeSDK finished successfully"
exit 0
