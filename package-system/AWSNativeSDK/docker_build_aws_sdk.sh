#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# Make sure we have all the required dev packages
REQUIRED_DEV_PACKAGES="zlib1g-dev libssh-dev libssl-dev libcurl4-openssl-dev"
ALL_PACKAGES=`apt list 2>/dev/null`
for req_package in $REQUIRED_DEV_PACKAGES
do
    PACKAGE_COUNT=`echo $ALL_PACKAGES | grep $req_package | wc -l`
    if [[ $PACKAGE_COUNT -eq 0 ]]; then
        echo Missing required package $req_package
        exit 1
    fi
done


# Validate the expected version of OpenSSL for this script from the argument
EXPECTED_OPENSSL_MAJOR=$1
if [ -z $EXPECTED_OPENSSL_MAJOR ]
then
    echo "Missing OpenSSL Major version argument"
    exit 1
fi

OPENSSL_MAJORVERSION=`openssl version | awk '{print $2}' | awk '{print substr($0,1,1)}'`
if [ $OPENSSL_MAJORVERSION -eq $EXPECTED_OPENSSL_MAJOR ]
then
    echo "Validated OpenSSL version $OPENSSL_MAJORVERSION == $EXPECTED_OPENSSL_MAJOR"
else
    echo "Error, expected OpenSSL major version $EXPECTED_OPENSSL_MAJOR, but got $OPENSSL_MAJORVERSION"
    exit 1
fi


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
    build_type=$1
    lib_type=$2
    build_shared=OFF
    if [ "$lib_type" == "Shared" ]
    then
        build_shared=ON
    fi

    echo "CMake Configure $build_type $lib_type"
    CC=/usr/lib/llvm-12/bin/clang CXX=/usr/lib/llvm-12/bin/clang++ cmake -S "$src_path" -B "$bld_path/${build_type}_${lib_type}" \
          -G "Unix Makefiles" \
          -DTARGET_ARCH=LINUX \
          -DCMAKE_CXX_STANDARD=17 \
          -DCPP_STANDARD=17 \
          -DCMAKE_C_FLAGS="-fPIC" \
          -DCMAKE_CXX_FLAGS="-fPIC" \
          -DENABLE_TESTING=OFF \
          -DENABLE_RTTI=ON \
          -DCUSTOM_MEMORY_MANAGEMENT=ON \
          -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;mobileanalytics;queues;s3;sns;sqs;sts;transfer" \
          -DBUILD_SHARED_LIBS=$build_shared \
          -DCMAKE_BUILD_TYPE=$build_type \
          -DCMAKE_INSTALL_BINDIR="bin" \
          -DCMAKE_INSTALL_LIBDIR="lib" || (echo "CMake Configure $build_type $lib_type failed" ; exit 1)

    echo "CMake Build $build_type $lib_type to $bld_path/${build_type}_${lib_type}"

    cmake --build "$bld_path/${build_type}_${lib_type}" -j 12 || (echo "CMake Build $build_type $lib_type to $bld_path/${build_type}_${lib_type} failed" ; exit 1)

    cmake --install "$bld_path/${build_type}_${lib_type}" --prefix "$inst_path/${build_type}_${lib_type}" || (echo "CMake Install $build_type $lib_type to $inst_path/${build_type}_${lib_type} failed" ; exit 1)

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
