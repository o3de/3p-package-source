#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

# Copy from the lib FFI

WORKSPACE=/data/workspace

mkdir -p $WORKSPACE/package

cp -f -v $WORKSPACE/libexpat/expat/lib/*.h $WORKSPACE/cpython/Modules/expat/
cp -f -v $WORKSPACE/libexpat/expat/lib/*.c $WORKSPACE/cpython/Modules/expat/

echo ""
echo "--------------- Building cpython from source ---------------"
echo ""

cd $WORKSPACE/cpython

# Build from the source with optimizations and shared libs enabled , and override the RPATH and bzip include/lib paths
echo ./configure --prefix=$WORKSPACE/package/python --enable-optimizations --with-openssl=$WORKSPACE/openssl-local/build --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../ffi_lib/lib' CPPFLAGS='-I../ffi_lib/include' CFLAGS='-I../ffi_lib/include' 
./configure --prefix=$WORKSPACE/package/python --enable-optimizations --with-openssl=$WORKSPACE/openssl-local/build --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../ffi_lib/lib' CPPFLAGS='-I../ffi_lib/include' CFLAGS='-I../ffi_lib/include' 
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

# Install the newly built python 3.10.5 to the package/python folder
cd $WORKSPACE/cpython

make install
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error installing python to the package folder"
    exit $retVal
fi

cd $WORKSPACE/package

# Copy the python license file
cp $WORKSPACE/cpython/LICENSE $WORKSPACE/package/python/LICENSE

# Symlink python to python3
cd $WORKSPACE/package/python/bin
ln -s python3 python

# Copy the openssl libraries to the local cpython build for portability
cp $WORKSPACE/openssl-local/build/lib/libssl.so.1.1 $WORKSPACE/package/python/lib/
cp $WORKSPACE/openssl-local/build/lib/libcrypto.so.1.1 $WORKSPACE/package/python/lib/
cd $WORKSPACE/package/python/lib

ln -s libssl.so.1.1 libssl.so.1
ln -s libcrypto.so.1.1 libcrypto.so.1

# Copy the openssl license
cp $WORKSPACE/openssl/LICENSE $WORKSPACE/package/python/LICENSE.OPENSSL


cd $WORKSPACE/package
echo ""
echo "--------------- Upgrading pip ---------------"
echo ""
# the pip that may come from the above repo can be broken, so we'll use get-pip
# and then upgrade it.
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
./python/bin/python3 get-pip.py
rm get-pip.py
PYTHONNOUSERSITE=1 ./python/bin/python3 -m pip install --upgrade pip


# installing pip causes it to put absolute paths to python
# in the pip files (in bin).  For example, pip will have 
# a line at the top that starts with #!/full/path/to/python 
# so we fix those up too. 
# We want to change it from and absolute path to python
# to a multi-line #! that runs python from the same folder as the file is being called from: 
#!/bin/sh 
#"exec" "`dirname $0`/python" "$0" "$@"
sed -i "1s+.*+\#\!/bin/sh+" ./python/bin/pip* 
sed -i "2i\\
\"exec\" \"\`dirname \$0\`/python\" \"\$0\" \"\$\@\" " ./python/bin/pip*

echo ""
echo "--------------- PYTHON WAS BUILT FROM SOURCE ---------------"
echo ""

exit 0
