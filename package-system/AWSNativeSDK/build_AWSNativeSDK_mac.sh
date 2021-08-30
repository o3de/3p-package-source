#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

src_path=temp/src
bld_path=temp/build

configure_and_build() {
    build_type=$1
    lib_type=$2
    build_shared=OFF
    if [ "$lib_type" == "Shared" ]
    then
        build_shared=ON
    fi

    echo "CMake Configure $build_type $lib_type"
    CXXFLAGS=-Wno-deprecated-declarations cmake -S "$src_path" -B "$bld_path/${build_type}_${lib_type}" \
          -G "Xcode" \
          -DTARGET_ARCH=APPLE \
          -DCMAKE_OSX_ARCHITECTURES="x86_64" \
          -DCMAKE_CXX_STANDARD=17 \
          -DENABLE_TESTING=OFF \
          -DENABLE_RTTI=ON \
          -DCUSTOM_MEMORY_MANAGEMENT=ON \
          -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;mobileanalytics;queues;s3;sns;sqs;sts;transfer" \
          -DBUILD_SHARED_LIBS=$build_shared \
          -DCMAKE_BUILD_TYPE=$build_type \
          -DCMAKE_INSTALL_BINDIR="bin/$build_type" \
          -DCMAKE_INSTALL_LIBDIR="lib/$build_type" || (echo "CMake Configure $build_type $lib_type failed" ; exit 1)

    echo "CMake Build $build_type $lib_type to $bld_path/${build_type}_${lib_type}"
    cmake --build "$bld_path/${build_type}_${lib_type}" --config $build_type -j 12 || (echo "CMake Build $build_type $lib_type to $bld_path/${build_type}_${lib_type} failed" ; exit 1)
}

# Debug Shared
configure_and_build Debug Shared || exit 1

# Debug Static
configure_and_build Debug Static || exit 1

# Release Shared
configure_and_build Release Shared || exit 1

# Release Static
configure_and_build Release Static || exit 1

echo "Custom Build for AWSNativeSDK finished successfully"
exit 0
