#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR

echo ""
echo "--------------- PYTHON PACKAGE BUILD SCRIPT ----------------"
echo ""
echo "BASIC REQUIREMENTS in case something goes wrong:"
echo "   - git installed and in PATH"
echo "   - packages installed: apt-get build-essential tk8.6-dev python3 libssl-dev tcl8.6-dev libgdbm-compat-dev liblzma-dev libsqlite3-dev libreadline-dev texinfo"
echo "   - python3 with pip in PATH! (i.e. sudo apt install python3 and sudo apt install python3-pip"
echo "   - Note: This script is currently written for buildng on Ubuntu Linux only."
echo "   - Note: installing binaries with pip must result with them being on PATH."
echo ""

# Make sure we have all the required dev packages
REQUIRED_DEV_PACKAGES="tk8.6-dev python3 libssl-dev tcl8.6-dev libgdbm-compat-dev liblzma-dev libsqlite3-dev libreadline-dev texinfo"
ALL_PACKAGES=`apt list 2>/dev/null`
for req_package in $REQUIRED_DEV_PACKAGES
do
    PACKAGE_COUNT=`echo $ALL_PACKAGES | grep $req_package | wc -l`
    if [[ $PACKAGE_COUNT -eq 0 ]]; then
        echo Missing required package $req_package
        exit 1
    fi
done


if [[ ${PACKAGE_CLEAR_TEMP_FOLDERS:-0} -gt 0 ]]; then
    echo "   - PACKAGE_CLEAR_TEMP_FOLDERS env var is set > 0, will clear temp folders."
else
    echo "   - PACKAGE_CLEAR_TEMP_FOLDERS env var not set or = 0, will not clear temp."
fi
echo "   ... this will take about one and a half hours ..."
echo ""

mkdir -p temp


echo ""
echo "--------------- Cloning python from git ---------------"
echo ""
cd temp
git clone https://github.com/python/cpython.git --branch v3.14.7 --depth 1

if [[ ! -d "cpython" ]]; then
    echo "Was unable to create cpython dir via git clone.  Is git installed?"
    exit 1
fi

echo ""
echo "--------------- Cloning libffi 3.4.2 and building static version ---------------"
echo ""
git clone https://github.com/libffi/libffi.git --branch "v3.4.2" --depth 1
if [[ ! -d "libffi" ]]; then
    echo "Was unable to create libffi dir via git clone."
    exit 1
fi

pushd libffi

# According to the README.md for libffi, we need to run autogen.sh first
./autogen.sh
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error running autogen.sh for libffi"
    exit $retVal
fi
 
./configure --prefix=$SCRIPT_DIR/temp/ffi_lib --enable-shared=no CFLAGS='-fPIC' CPPFLAGS='-fPIC'
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error running configuring for libffi"
    exit $retVal
fi

make install
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building libffi"
    exit $retVal
fi

popd

echo ""
echo "--------------- Building zstd ---------------"
echo ""
curl -fsSL https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz -o zstd-1.5.7.tar.gz
echo "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3  zstd-1.5.7.tar.gz" | sha256sum --check
tar -xzf zstd-1.5.7.tar.gz
make -C zstd-1.5.7/lib libzstd.a-release CFLAGS="-O3 -fPIC"
make -C zstd-1.5.7/lib install-static install-includes PREFIX="$SCRIPT_DIR/temp/zstd_lib"


echo ""
echo "--------------- Cloning openssl and building it externally ---------------"
echo ""
git clone https://github.com/openssl/openssl.git --branch "openssl-3.6.3" --depth 1
if [[ ! -d "openssl" ]]; then
    echo "Was unable to create openssl dir via git clone."
    exit 1
fi

pushd openssl

echo ./config --prefix=$SCRIPT_DIR/temp/openssl-local/build --libdir=lib --openssldir=/etc/ssl LDFLAGS='-Wl,-rpath=\$$ORIGIN'
./config --prefix=$SCRIPT_DIR/temp/openssl-local/build --libdir=lib --openssldir=/etc/ssl LDFLAGS='-Wl,-rpath=\$$ORIGIN'

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building openssl"
    exit $retVal
fi

echo make
make
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building openssl (build failure)"
    exit $retVal
fi

echo make test
make test
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building openssl (test failure)"
    exit $retVal
fi

echo make install
make install
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error building openssl (install failure)"
    exit $retVal
fi

popd


cd cpython

echo ""
echo "--------------- Building cpython from source ---------------"
echo ""

# Build from the source with optimizations and shared libs enabled , and override the RPATH and bzip include/lib paths
./configure --prefix=$SCRIPT_DIR/package/python --enable-optimizations --with-openssl=$SCRIPT_DIR/temp/openssl-local/build --with-ensurepip=install --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../ffi_lib/lib -L../zstd_lib/lib' CPPFLAGS='-I../ffi_lib/include -I../zstd_lib/include' CFLAGS='-I../ffi_lib/include -I../zstd_lib/include'
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error running configuring optimized build"
    exit $retVal
fi

make
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error compiling optimized build"
    exit $retVal
fi

# Prepare the package folder
cd $SCRIPT_DIR

# Install the newly built python to the package/python folder
cd $SCRIPT_DIR
cd temp
cd cpython

make install
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error installing python to the package folder"
    exit $retVal
fi


cd $SCRIPT_DIR
mkdir -p package
cd package

cp $SCRIPT_DIR/temp/cpython/LICENSE ./python/LICENSE
cp $SCRIPT_DIR/PackageInfo.json .
cp $SCRIPT_DIR/*.cmake .

cd $SCRIPT_DIR/package/python/bin
ln -s python3 python
cd $SCRIPT_DIR/package


# Move the openssl libraries to the local cpython build for portability
pushd $SCRIPT_DIR/package/python/lib
cp $SCRIPT_DIR/temp/openssl-local/build/lib/libssl.so.3 .
cp $SCRIPT_DIR/temp/openssl-local/build/lib/libcrypto.so.3 .
popd

# Copy the openssl license
cp $SCRIPT_DIR/temp/openssl/LICENSE $SCRIPT_DIR/package/python/LICENSE.OPENSSL
cp $SCRIPT_DIR/temp/zstd-1.5.7/LICENSE $SCRIPT_DIR/package/python/LICENSE.ZSTD


echo ""
echo "--------------- PYTHON WAS BUILT FROM SOURCE ---------------"
echo ""



echo "Package has completed building, and is now in $SCRIPT_DIR/package"

if [[ ${PACKAGE_CLEAR_TEMP_FOLDERS:-0} -gt 0 ]]
    then
        echo "Deleting temp folders because PACKAGE_CLEAR_TEMP_FOLDERS is set to > 0"
        rm -rf $SCRIPT_DIR/temp
    else
        echo "PACKAGE_CLEAR_TEMP_FOLDERS is unset or zero, temp folder retained."
        echo "Running this script again without deleting temp will just update the package without"
        echo "The two hour wait time to build everything from scratch..."

fi
exit 0
