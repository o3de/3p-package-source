#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

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


# Copy the source folder from the read-only $WORKSPACE/temp/src to $WORKSPACE/src
# since the build process will write/modify the source path
SRC_PATH=$WORKSPACE/src
echo "Preparing source folder '${SRC_PATH}'"
cp -r $WORKSPACE/temp/src ${SRC_PATH}


# The dependent 'depends_on_packages' paths are architecture dependent
if [ "$(uname -m)" = "x86_64" ]
then
    O3DE_OPENSSL_PACKAGE=OpenSSL-3.6.3-rev1-linux
    O3DE_SQLITE_PACKAGE=SQLite-3.37.2-rev1-linux
else
    O3DE_OPENSSL_PACKAGE=OpenSSL-3.6.3-rev1-linux-aarch64
    O3DE_SQLITE_PACKAGE=SQLite-3.37.2-rev1-linux-aarch64
fi

# Prepare the dependent O3DE package information for OpenSSL
OPENSSL_BASE=$WORKSPACE/temp/${O3DE_OPENSSL_PACKAGE}/OpenSSL
echo "Using O3DE OpenSSL package from ${O3DE_OPENSSL_PACKAGE}"


# Prepare the dependent O3DE package information for SQLite
SQLITE_BASE=$WORKSPACE/temp/${O3DE_SQLITE_PACKAGE}/SQLite
echo "Using O3DE SQLite3 package from ${SQLITE_BASE}"


# Prepare the dependent libffi package from github to use 
LIBFFI_VERSION="v3.4.2"
LIBFFI_GIT_URL="https://github.com/libffi/libffi.git"
LIBFFI_SRC=ffi_src
LIBFFI_SRC_PATH=${WORKSPACE}/${LIBFFI_SRC}
LIBFFI_LIB_PATH=${WORKSPACE}/ffi_lib

echo "Clone and build libFFI statically from ${LIBFFI_GIT_URL} / ${LIBFFI_VERSION}"

CMD="git -C ${WORKSPACE} clone ${LIBFFI_GIT_URL} --branch ${LIBFFI_VERSION} --depth 1 ${LIBFFI_SRC}"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Failed cloning libffi from ${LIBFFI_GIT_URL}"
    exit 1
fi

pushd ${LIBFFI_SRC_PATH}

CMD="./autogen.sh"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "'autogen' failed for libffi at ${LIBFFI_SRC_PATH}"
    exit 1
fi


CMD="./configure --prefix=$LIBFFI_LIB_PATH --enable-shared=no CFLAGS='-fPIC' CPPFLAGS='-fPIC' "
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "'configure' failed for libffi at ${LIBFFI_SRC_PATH}"
    exit 1
fi

CMD="make install"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "'configure' failed for libffi at ${LIBFFI_SRC_PATH}"
    exit 1
fi

popd

ZSTD_VERSION="1.5.7"
ZSTD_ARCHIVE="zstd-${ZSTD_VERSION}.tar.gz"
ZSTD_ARCHIVE_SHA256="eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3"
ZSTD_SRC_PATH="${WORKSPACE}/zstd-${ZSTD_VERSION}"
ZSTD_LIB_PATH="${WORKSPACE}/zstd_lib"

curl -fsSL "https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/${ZSTD_ARCHIVE}" -o "${WORKSPACE}/${ZSTD_ARCHIVE}"
echo "${ZSTD_ARCHIVE_SHA256}  ${WORKSPACE}/${ZSTD_ARCHIVE}" | sha256sum --check
tar -xzf "${WORKSPACE}/${ZSTD_ARCHIVE}" -C "${WORKSPACE}"
make -C "${ZSTD_SRC_PATH}/lib" libzstd.a-release CFLAGS="-O3 -fPIC"
make -C "${ZSTD_SRC_PATH}/lib" install-static install-includes PREFIX="${ZSTD_LIB_PATH}"

# Build CPython from source

echo "Building cpython from source ..."
echo ""

pushd ${SRC_PATH}

export PKG_CONFIG_PATH="${OPENSSL_BASE}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export PKG_CONFIG="pkg-config --define-prefix --static"
export LIBSQLITE3_CFLAGS="-I${SQLITE_BASE}"
export LIBSQLITE3_LIBS="-L${SQLITE_BASE}/lib -lsqlite3 -lm -ldl -lz -lpthread"

# Build from the source with optimizations and shared libs enabled , and override the RPATH and bzip include/lib paths
./configure --prefix=${BUILD_FOLDER}/python\
 --enable-optimizations\
 --with-ensurepip=install\
 --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../ffi_lib/lib -L../zstd_lib/lib'\
 CPPFLAGS='-I../ffi_lib/include -I../zstd_lib/include' CFLAGS='-I../ffi_lib/include -I../zstd_lib/include'
if [ $? -ne 0 ]
then
    echo "'configure' failed for cpython at ${SRC_PATH}"
    exit 1
fi

CMD="make"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "'make' failed for cpython at ${SRC_PATH}"
    exit 1
fi

CMD="make install"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "'make install' failed for cpython at ${SRC_PATH}"
    exit 1
fi

popd

echo "Preparing additional python files"

# Copy the python license
cp ${SRC_PATH}/LICENSE ${BUILD_FOLDER}/python/LICENSE

# Also copy the openssl license since its linked against the dependent O3DE OpenSSL static package
cp ${OPENSSL_BASE}/LICENSE.txt ${BUILD_FOLDER}/python/LICENSE.OPENSSL
cp ${ZSTD_SRC_PATH}/LICENSE ${BUILD_FOLDER}/python/LICENSE.ZSTD

# Create a symlink from python -> python3
pushd ${BUILD_FOLDER}/python/bin
ln -s python3 python
popd

echo ""
echo "--------------- PYTHON WAS BUILT FROM SOURCE ---------------"
echo ""

exit 0
