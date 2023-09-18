#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


# Validate the bld path input
BUILD_FOLDER=${DOCKER_BUILD_PATH}
if [ "${BUILD_FOLDER}" == "" ]
then
    echo "Missing required build target folder environment"
    exit 1
elif [ "${BUILD_FOLDER}" == "temp" ]
then
    echo "Build target folder environment cannot be 'temp'"
    exit 1
fi


# Locate the dependent OpenSSL package
OPENSSL_REGEX='(OpenSSL-([A-Za-z0-9\.\-]+)-(linux|linux-aarch64))'
[[ $DOWNLOADED_PACKAGE_FOLDERS =~ $OPENSSL_REGEX ]]
DEPENDENT_OPENSSL=${BASH_REMATCH[1]}

if [ $DEPENDENT_OPENSSL == "" ]
then
    echo "Unable to detect dependent OpenSSL package"
    exit 1
fi
DEPENDENT_OPENSSL_BASE=$WORKSPACE/temp/${DEPENDENT_OPENSSL}/OpenSSL
if [ ! -d ${DEPENDENT_OPENSSL_BASE} ]
then
    echo "Unable to detect dependent OpenSSL package at ${DEPENDENT_OPENSSL_BASE}"
    exit 1
fi
echo "Detected dependent OpenSSL package at ${DEPENDENT_OPENSSL_BASE}"


# Locate the dependent ZLIB package
OPENZLIB_REGEX='(zlib-([A-Za-z0-9\.\-]+)-(linux|linux-aarch64))'
[[ $DOWNLOADED_PACKAGE_FOLDERS =~ $OPENZLIB_REGEX ]]
DEPENDENT_ZLIB=${BASH_REMATCH[1]}

if [ $DEPENDENT_ZLIB == "" ]
then
    echo "Unable to detect dependent zlib package"
    exit 1
fi
DEPENDENT_ZLIB_BASE=$WORKSPACE/temp/${DEPENDENT_ZLIB}/zlib
if [ ! -d ${DEPENDENT_ZLIB_BASE} ]
then
    echo "Unable to detect dependent zlib package at ${DEPENDENT_ZLIB_BASE}"
    exit 1
fi
echo "Detected dependent zlib package at ${DEPENDENT_ZLIB_BASE}"


# Prepare curl
CURL_BASE=/data/workspace/curl
CURL_SRC=${CURL_BASE}/src
CURL_INSTALL=${CURL_BASE}/install
if [ ! -d $CURL_BASE ]
then
    echo "Unable to find source curl library ($CURL_SRC) from this docker image"
    exit 1
fi

# Build curl from source
pushd $CURL_BASE/src

CMD="autoreconf -fi"
echo ${CMD}
eval ${CMD}
if [ $? -ne 0 ]
then
    echo "Failed generating configuration for curl"
    exit 1
fi


CMD="./configure --with-ssl=${DEPENDENT_OPENSSL_BASE}/ --with-zlib=${DEPENDENT_ZLIB_BASE} --prefix=${CURL_INSTALL} --enable-proxy"
echo ${CMD}
eval ${CMD}
if [ $? -ne 0 ]
then
    echo "Failed configuring curl"
    exit 1
fi

CMD="make"
echo ${CMD}
eval ${CMD}
if [ $? -ne 0 ]
then
    echo "Failed building curl"
    exit 1
fi

CMD="make install"
echo ${CMD}
eval ${CMD}
if [ $? -ne 0 ]
then
    echo "Failed installing curl"
    exit 1
fi

popd

# Copy the source folder from the read-only $WORKSPACE/temp/src to $WORKSPACE/src
# since the build process will write/modify the source path
echo "Preparing source folder '$WORKSPACE/src'"
cp -r $WORKSPACE/temp/src $WORKSPACE/ || (echo "Error copying src from $WORKSPACE/temp" && exit 1)

SRC_PATH=$WORKSPACE/src

if [ ! -d ${SRC_PATH} ]
then
    echo "Missing expected source path at ${SRC_PATH}"
    exit 1
fi

BUILD_PATH=$WORKSPACE/aws/build
if [ -d ${BUILD_PATH} ]
then
    rm -rf ${BUILD_PATH}
fi

INSTALL_PATH=${BUILD_FOLDER}
if [ -d ${INSTALL_PATH} ]
then
    rm -rf ${INSTALL_PATH}
fi

configure_and_build() {

    lib_type=$1
    dep_curl_lib=${CURL_INSTALL}/lib/libcurl.a
    if [ "$lib_type" == "Shared" ]
    then
        build_shared=ON
    else
        build_shared=OFF
    fi

    echo "CMake Configure $build_type $lib_type"

    CMD="cmake -S ${SRC_PATH} -B ${BUILD_PATH}/${lib_type} \
 -G Ninja \
 -DTARGET_ARCH=LINUX \
 -DCMAKE_C_COMPILER=/usr/lib/llvm-12/bin/clang \
 -DCMAKE_CXX_COMPILER=/usr/lib/llvm-12/bin/clang++ \
 -DCMAKE_CXX_STANDARD=17 \
 -DCPP_STANDARD=17 \
 -DCMAKE_C_FLAGS=\"-fPIC -Wno-option-ignored\" \
 -DCMAKE_CXX_FLAGS=\"-fPIC -Wno-option-ignored\" \
 -DENABLE_TESTING=OFF \
 -DENABLE_RTTI=ON \
 -DCUSTOM_MEMORY_MANAGEMENT=ON \
 -DBUILD_ONLY=\"access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;queues;s3;sns;sqs;sts;transfer\" \
 -DBUILD_SHARED_LIBS=$build_shared \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_BINDIR=\"bin\" \
 -DCMAKE_INSTALL_LIBDIR=\"lib\" \
 -DCMAKE_MODULE_PATH=\"$DOWNLOADED_PACKAGE_FOLDERS\" \
 -DCURL_INCLUDE_DIR=${CURL_INSTALL}/include \
 -DCURL_LIBRARY=${dep_curl_lib}"

    echo ${CMD}
    eval ${CMD}
    if [ $? -ne 0 ]
    then
        echo "Error generating AWS Native SDK build" 
        exit 1
    fi

    CMD="cmake --build \"${BUILD_PATH}/${lib_type}\" "
    echo ${CMD}
    eval ${CMD}
    if [ $? -ne 0 ]
    then
        echo "Error building the ${lib_type} AWS Native SDK libraries"
        exit 1
    fi

    CMD="cmake --install \"${BUILD_PATH}/${lib_type}\" --prefix \"${INSTALL_PATH}/${lib_type}\" "
    echo ${CMD}
    eval ${CMD}
    if [ $? -ne 0 ]
    then
        echo "Error installing the ${lib_type} AWS Native SDK libraries" 
        exit 1
    fi

    cp ${dep_curl_lib} ${INSTALL_PATH}/${lib_type}/lib/
}

# Static
configure_and_build Static

# Shared
configure_and_build Shared

# Copy the curl-related copyright and readme
cp ${CURL_SRC}/README ${INSTALL_PATH}/README.CURL
cp ${CURL_SRC}/COPYING ${INSTALL_PATH}/COPYING.CURL

echo "Custom Build for AWSNativeSDK finished successfully"

exit 0
