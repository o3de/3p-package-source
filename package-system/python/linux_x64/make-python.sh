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
echo "   - packages installed: apt-get dev-essential tk8.6-dev python3 libssl-dev tcl8.6-dev libgdbm-compat-dev liblzma-dev libsqlite3-dev libreadline-dev texinfo"
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


if [[ ${PACKAGE_CLEAR_TEMP_FOLDERS} -gt 0 ]]; then
    echo "   - PACKAGE_CLEAR_TEMP_FOLDERS env var is set > 0, will clear temp folders."
else
    echo "   - PACKAGE_CLEAR_TEMP_FOLDERS env var not set or = 0, will not clear temp."
fi
echo "   ... this will take about one and a half hours ..."
echo ""

mkdir -p temp


echo ""
echo "--------------- Cloning python 3.7.12 from git ---------------"
echo ""
cd temp
git clone https://github.com/python/cpython.git --branch v3.7.12 --depth 1

if [[ ! -d "cpython" ]]; then
    echo "Was unable to create cpython dir via git clone.  Is git installed?"
    exit 1
fi

echo ""
echo "--------------- Cloning libexpat 2.4.6 from git and applying update ---------------"
echo ""
git clone https://github.com/libexpat/libexpat.git --branch "R_2_4_6" --depth 1

if [[ ! -d "libexpat" ]]; then
    echo "Was unable to create libexpat dir via git clone.  Is git installed?"
    exit 1
fi

cp -f -v libexpat/expat/lib/*.h cpython/Modules/expat/
cp -f -v libexpat/expat/lib/*.c cpython/Modules/expat/


echo ""
echo "--------------- Cloning bzip2 1.0.8 and building ---------------"
echo ""
git clone git://sourceware.org/git/bzip2.git --branch "bzip2-1.0.8" --depth 1
if [[ ! -d "bzip2" ]]; then
    echo "Was unable to create bzip2 dir via git clone.  Is git installed?"
    exit 1
fi

pushd bzip2

PATCH_FILE=$SCRIPT_DIR/open3d_bzip2.patch
echo Applying patch file $PATCH_FILE
git apply --ignore-whitespace $PATCH_FILE
if [ $retVal -ne 0 ]; then
    echo "Git apply failed"
    exit $retVal
fi

make bzip2

make install PREFIX=install

popd

echo ""
echo "--------------- Cloning libffi 1.0.8 and building static version ---------------"
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
 
./configure --prefix=$SCRIPT_DIR/temp/ffi_lib --enable-shared=no --with-fpic=yes CFLAGS='-fPIC' CPPFLAGS='-fPIC'
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


cd cpython

echo ""
echo "--------------- Building cpython from source ---------------"
echo ""

# Build from the source with optimizations and shared libs enabled , and override the RPATH and bzip include/lib paths
./configure --prefix=$SCRIPT_DIR/package/python --enable-optimizations --enable-shared LDFLAGS='-Wl,-rpath=\$$ORIGIN:\$$ORIGIN/../lib:\$$ORIGIN/../.. -L../bzip2/install/lib -L../ffi_lib/lib' CPPFLAGS='-I../bzip2/install/include -I../ffi_lib/include' CFLAGS='-I../temp/bzip2/install/include -I../ffi_lib/include'
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

# Install the newly built python 3.7.12 to the package/python folder
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

# https://github.com/o3de/o3de/issues/7281 Reports NVD vulnerability in the wininst-*.exe files that
# get included in the package. Since this is a linux only package, we can remove them 
echo "Removing wininst*.exe files"
rm -v $SCRIPT_DIR/package/python/lib/python3.7/distutils/command/wininst-*.exe

echo "Removing out of date pip*.whl"
rm -v $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/_bundled/pip-*.whl

echo "Removing pip references from ensurepip"
cat $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/__init__.py | sed 's/"20.1.1"/"22.0.3"/g' | sed 's/("pip", _PIP_VERSION, "py2.py3"),//g' > $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/__init__.py_temp
rm $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/__init__.py
mv $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/__init__.py_temp $SCRIPT_DIR/package/python/lib/python3.7/ensurepip/__init__.py

echo ""
echo "--------------- PYTHON WAS BUILT FROM SOURCE ---------------"
echo ""

echo "Package has completed building, and is now in $SCRIPT_DIR/package"

if [[ ${PACKAGE_CLEAR_TEMP_FOLDERS} -gt 0 ]]
    then
        echo "Deleting temp folders because PACKAGE_CLEAR_TEMP_FOLDERS is set to > 0"
        rm -rf $SCRIPT_DIR/temp
    else
        echo "PACKAGE_CLEAR_TEMP_FOLDERS is unset or zero, temp folder retained."
        echo "Running this script again without deleting temp will just update the package without"
        echo "The two hour wait time to build everything from scratch..."

fi
exit 0
