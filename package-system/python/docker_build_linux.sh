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
    O3DE_OPENSSL_PACKAGE=OpenSSL-1.1.1t-rev1-linux
    O3DE_SQLITE_PACKAGE=SQLite-3.37.2-rev1-linux
else
    O3DE_OPENSSL_PACKAGE=OpenSSL-1.1.1t-rev1-linux-aarch64
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

echo "Clone and build libFFI statically from ${FFI_GIT_URL} / ${LIBFFI_VERSION}"

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


CMD="./configure --prefix=$LIBFFI_LIB --enable-shared=no CFLAGS='-fPIC' CPPFLAGS='-fPIC' "
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

# Build CPython from source

echo "Building cpython from source ..."
echo ""

pushd ${SRC_PATH}

# Build from the source with optimizations and shared libs enabled , and override the RPATH and bzip include/lib paths
CMD="\
./configure --prefix=${BUILD_FOLDER}/python\
 --enable-optimizations\
 --with-openssl=${OPENSSL_BASE}\
 --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../ffi_lib/lib -L'${SQLITE_BASE}'/lib'\
 CPPFLAGS='-I../ffi_lib/include -I'${SQLITE_BASE}'' CFLAGS='-I../ffi_lib/include -I'${SQLITE_BASE}''"
echo $CMD
eval $CMD
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
cp ${OPENSSL_BASE}/LICENSE ${BUILD_FOLDER}/python/LICENSE.OPENSSL

# Create a symlink from python -> python3
pushd ${BUILD_FOLDER}/python/bin
ln -s python3 python
popd

pushd ${BUILD_FOLDER}

echo "Upgrading pip"

# the pip that may come from the above repo can be broken, so we'll use get-pip
# and then upgrade it.
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
./python/bin/python3 get-pip.py
rm get-pip.py

pushd python/bin

PYTHONNOUSERSITE=1 ./python3 -m pip install --upgrade pip

echo "Upgrading setup tools"

# Update setup tools to resolve https://avd.aquasec.com/nvd/cve-2022-40897
PYTHONNOUSERSITE=1 ./python3 -m pip install setuptools --upgrade setuptools

# Update wheel to resolve https://avd.aquasec.com/nvd/2022/cve-2022-40898/
PYTHONNOUSERSITE=1 ./python3 -m pip install wheel --upgrade wheel

popd #python/bin 

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

popd # ${BUILD_FOLDER}

echo ""
echo "--------------- PYTHON WAS BUILT FROM SOURCE ---------------"
echo ""

exit 0
