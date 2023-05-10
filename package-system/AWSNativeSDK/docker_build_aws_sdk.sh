#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# Validate the src path
src_path=src
if [ ! -d $src_path ]
then
    echo "Missing src path"
    exit 1
fi


# Make sure the build path is clear
bld_path=build
rm -rf $bld_path || (echo "Command: rm -rf $bld_path failed" ; exit 1)
mkdir $bld_path


# Make sure the install path is clear
inst_path=install
echo "Command: rm -rf $inst_path"
rm -rf $inst_path || (echo "Command: rm -rf $inst_path failed" ; exit 1)
mkdir $inst_path


configure_and_build() {

    lib_type=$1
    build_shared=OFF
    if [ "$lib_type" == "Shared" ]
    then
        build_shared=ON
    fi

    echo "CMake Configure $build_type $lib_type"

    cmake -S "$src_path" -B "$bld_path/${lib_type}" \
          -G "Ninja" \
          -DTARGET_ARCH=LINUX \
          -DCMAKE_C_COMPILER=/usr/lib/llvm-12/bin/clang \
          -DCMAKE_CXX_COMPILER=/usr/lib/llvm-12/bin/clang++ \
          -DCMAKE_CXX_STANDARD=17 \
          -DCPP_STANDARD=17 \
          -DCMAKE_C_FLAGS="-fPIC" \
          -DCMAKE_CXX_FLAGS="-fPIC" \
          -DENABLE_TESTING=OFF \
          -DENABLE_RTTI=ON \
          -DCUSTOM_MEMORY_MANAGEMENT=ON \
          -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;mobileanalytics;queues;s3;sns;sqs;sts;transfer" \
          -DBUILD_SHARED_LIBS=$build_shared \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_BINDIR="bin" \
          -DCMAKE_INSTALL_LIBDIR="lib" 
    if [ $? -ne 0 ]
    then
        echo "Error generating AWS Native SDK build" 
        exit 1
    fi          

    echo "CMake Build $build_type $lib_type to $bld_path/${lib_type}"
    cmake --build "$bld_path/${lib_type}"
    if [ $? -ne 0 ]
    then
        echo "Error building the ${lib_type} AWS Native SDK libraries"
        exit 1
    fi          

    echo "CMake Install $build_type $lib_type to $inst_path/${lib_type}"
    cmake --install "$bld_path/${lib_type}" --prefix "$inst_path/${lib_type}"
    if [ $? -ne 0 ]
    then
        echo "Error installing the ${lib_type} AWS Native SDK libraries" 
        exit 1
    fi          

}

# Shared
configure_and_build Shared

# Static
configure_and_build Static

echo "Custom Build for AWSNativeSDK finished successfully"

exit 0
