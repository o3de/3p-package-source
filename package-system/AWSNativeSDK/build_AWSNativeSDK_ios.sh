#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

src_path=temp/src
bld_path=temp/build

configure_and_build_static() {
    build_type=$1

    echo "CMake Configure $build_type Static"
    CXXFLAGS="-Wno-deprecated-declarations -Wno-shorten-64-to-32 -fPIC" \
    cmake -S "$src_path" -B "$bld_path/${build_type}_Static" \
          -DTARGET_ARCH=APPLE \
          -DCMAKE_SYSTEM_NAME=Darwin \
          -DCMAKE_OSX_ARCHITECTURES="arm64" \
          -DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
          -DCMAKE_CXX_STANDARD=17 \
          -DENABLE_TESTING=OFF \
          -DENABLE_RTTI=ON \
          -DCUSTOM_MEMORY_MANAGEMENT=ON \
          -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;mobileanalytics;queues;s3;sns;sqs;sts;transfer" \
          -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_BUILD_TYPE=$build_type \
          -DCURL_LIBRARY="temp/curl_install/lib/libcurl.a" \
          -DCURL_INCLUDE_DIR="temp/curl_install/include" \
          -DCMAKE_INSTALL_LIBDIR="lib/$build_type" || (echo "CMake Configure $build_type Static failed" ; exit 1)

    echo "CMake Build $build_type Static to $bld_path/${build_type}_Static"
    cmake --build "$bld_path/${build_type}_Static" --config $build_type -j 12 || (echo "CMake Build $build_type Static to $bld_path/${build_type}_Static failed" ; exit 1)
}

make_configure_and_build_curl() {
  rm -rf "temp/curl"*

  echo "Downloading Curl 7.65.3"
  (cd temp && curl -o curl-7.65.3.zip "https://curl.se/download/curl-7.65.3.zip") || exit 1

  echo "Extract Curl 7.65.3 source"
  unzip  temp/curl-7.65.3.zip -d temp || exit 1

  EXISTING_CFLAGS=$CFLAGS
  export CFLAGS="-arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -miphoneos-version-min=13.0 -fPIC"

  (cd temp/curl-7.65.3 && ./configure --disable-shared --enable-static --enable-ipv6 --with-secure-transport --host="arm-apple-darwin" --prefix=$(pwd)/../curl_install) || exit 1
  (cd temp/curl-7.65.3 && make) || exit 1
  (cd temp/curl-7.65.3 && make install) || exit 1

  export CFLAGS=$EXISTING_CFLAGS
  EXISTING_CFLAGS=
}

# TODO: curl cmake is poorly maintained by community, switch to cmake when it is ready
cmake_configure_and_build_curl() {
  rm -rf "temp/curl"*

  echo "Cloning Curl 7.65.3"
  git clone --single-branch --recursive --branch curl-7_65_3 https://github.com/curl/curl.git temp/curl_src

  echo "CMake Configure Curl Debug Static"
  cmake -S temp/curl_src -B temp/curl_build/Debug_Static \
        -DTARGET_ARCH=APPLE \
        -DCMAKE_SYSTEM_NAME=Darwin \
        -DCMAKE_OSX_ARCHITECTURES="arm64" \
        -DCMAKE_OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
        -DCMAKE_USE_SECTRANSP=ON \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_BUILD_TYPE=Debug\
        -DBUILD_CURL_EXE=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF 

  echo "CMake Build Curl Debug Static to temp/curl_build/Debug_Static"
  cmake --build temp/curl_build/Debug_Static --config Debug -j 12

  echo "CMake Install Curl Debug Static to temp/curl_install/Debug_Static"
  cmake --install temp/curl_build/Debug_Static --prefix temp/curl_install/Debug_Static --config Debug
}

# Curl Static
make_configure_and_build_curl || exit 1

# Debug Static
configure_and_build_static Debug || exit 1

# Release Static
configure_and_build_static Release || exit 1

echo "Custom Build for AWSNativeSDK finished successfully"
exit 0
