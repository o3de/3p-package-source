#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# REQUIREMENTS:
#  * 'git' installed and on path
#  * 'python3' installed and on path (can be any version > 2.7 including 3.x)
#  * xcode command line tools installed and on path ('install_name_tool' and 'otool')

# HOW IT WORKS:
# * Downloads https://github.com/gregneagle/relocatable-python.git (Apache 2.0 License)
# * applies the above with open3d_patch.patch (See contents of that patch).
# * Fetches python from the official python repository
# * patches python with open3d_python.patch to shortcut the package building process (we don't need)
#   a full installer, just the framework.
# * Ensures you have the necessary environment vars set and pip packages installed in a pip virtualenv
# * builds python using python.org official mac package builder we've patched.
# * Uses the relocatable-python script to generate a 'package' folder containing real python but
#    with rpaths patched to be relocatable.
# * Replaces the 'identifier' of the main python dylib to be relative to current dir.
# * Deploys the finished framework to a the package layout folder using rsync.
# * Copies the license files inside python to the package layout folder
# * Copies the other package system file (json and cmake) to the pacakge layout folder.
#
# The result is a 'package' subfolder containing the package files such as PackageInfo.json
# and a subfolder containing the official python but patched so that they work in that folder structure
# regardless of where the folder is, instead of having absolute paths baked in.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $SCRIPT_DIR

echo ""
echo "------------------ PYTHON PACKAGE BUILD SCRIPT -------------------"
echo ""
echo "BASIC REQUIREMENTS:"
echo "   - git installed and in PATH"
echo "   - XCODE and xcode command line tools installed: xcode-select --install"
echo "   - python3 installed and in PATH."
echo ""

echo "--------------- Clearing any previous package folder -------------"
rm -rf package

echo "---------------- Clearing any previous temp folder ---------------"
rm -rf temp

mkdir temp
cd temp

mkdir $SCRIPT_DIR/package

echo "-------------- Cloning python from git --------------"
git clone https://github.com/python/cpython.git --branch "v3.7.10" --depth 1
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error cloning python!"
    exit $retVal
fi

echo "-------------- Cloning relocatable-python from git --------------"
git clone https://github.com/gregneagle/relocatable-python.git
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error cloning relocatable-python!"
    exit $retVal
fi

PYTHON_SRC_DIR=$SCRIPT_DIR/temp/cpython
RELOC_SRC_DIR=$SCRIPT_DIR/temp/relocatable-python

echo "------------- creating python virtual environment ----------"
cd $SCRIPT_DIR/temp
python3 -m venv py_venv
VENV_BIN_DIR=$SCRIPT_DIR/temp/py_venv/bin
PYTHONNOUSERSITE=1

echo "------ Installing spinx documentation tool into the v-env -----"
$VENV_BIN_DIR/python3 -m pip install sphinx

cd $RELOC_SRC_DIR
echo "----- Checking out specific commit hash of relocatable-python -----"
# the hash is a known good commit hash.  This also causes it to fail if someone
# tampers the repo!
git reset --hard 5e459c3ccea0daaf181f3b1ef2773dbefce1a563
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error resetting to specific change!"
    exit $retVal
fi

echo "------------------- patching the relocator -----------------------"
echo Currently in `pwd`
echo patch -p1 $SCRIPT_DIR/open3d_patch.patch
patch -p1 < $SCRIPT_DIR/open3d_patch.patch
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not patch the relocator!"
    exit $retVal
fi


cd $PYTHON_SRC_DIR
echo "------------------- patching the python Mac package-maker -----------------------"
patch -p1 < $SCRIPT_DIR/open3d_python.patch
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not patch the python package maker!"
    exit $retVal
fi

echo "-------------- Building a Mac python package from official sources ----------"
cd $PYTHON_SRC_DIR
cd Mac
cd BuildScript
# the following env vars get around a problem compiling tcl/tk
tcl_cv_strtod_buggy=1 ac_cv_func_strtod=yes SDK_TOOLS_BIN=$VENV_BIN_DIR $VENV_BIN_DIR/python3 ./build-installer.py --universal-archs=intel-64 --build-dir $SCRIPT_DIR/temp/python_build --third-party=$SCRIPT_DIR/temp/downloaded_packages --dep-target=10.9
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not build python!"
    exit $retVal
fi

# the output of the build $SCRIPT_DIR/temp/python_build/_root/Library/Frameworks and that folder will contain Python.framework
# we use the --use-existing-framework to point the script at that framework we just made:
FRAMEWORK_OUTPUT_FOLDER=$SCRIPT_DIR/temp/python_build/_root/Library/Frameworks
echo Framework output folder: $FRAMEWORK_OUTPUT_FOLDER
cd $RELOC_SRC_DIR
echo "---------- Altering the produced framework folder to be relocatable ---------"
echo $VENV_BIN_DIR/python3 ./make_relocatable_python_framework.py --install-wheel --upgrade-pip --python-version 3.7.10 --use-existing-framework $FRAMEWORK_OUTPUT_FOLDER/Python.framework
$VENV_BIN_DIR/python3 ./make_relocatable_python_framework.py --install-wheel --upgrade-pip --python-version 3.7.10 --use-existing-framework $FRAMEWORK_OUTPUT_FOLDER/Python.framework
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not make python relocatable!"
    exit $retVal
fi

echo "------------------ Final RPATH update --------------"
# The filename of the main python dylib is 'Python'.
# It is located at ./package/Python.framework/Versions/3.7
# This, despite just being called 'Python' with no extension is actually the main python 
# dylib that is required to load if you link your application to the import library for 
# Python.  The below change of its 'id' (which is what programs link to it will import it as)
# allows programs linked ot it to work as long the dylib is deployed to the executable,
# and as long as the executable adds the executable's path to its list of @rpath to search.
# (Instead of its original which is "@rpath/Versions/3.7/Python" which would require us to
# copy it to such a subfolder)
# Because all the python framework libraries already have 2 rpaths, the @loader_path
# as well as the root of the framework (ie, @loader_path/../../../.. etc), this makes
# the whole thing work regardless of whether Python is in the same folder as the binary or 
# whether a python native plugin is being located from the framework in some subfolder.
install_name_tool -id @rpath/Python $FRAMEWORK_OUTPUT_FOLDER/Python.framework/Versions/3.7/Python

echo "-------------- rsync package layout into $SCRIPT_DIR/package ------------"
mdkir $SCRIPT_DIR/package
rsync -avu --delete "$FRAMEWORK_OUTPUT_FOLDER/" "$SCRIPT_DIR/package"

echo "---------- Copying Open3DEngine package metadata and license file ------------"
# the tar contains a 'Python.framework' sub folder
cd $SCRIPT_DIR/package
cp $SCRIPT_DIR/package/Python.framework/Versions/3.7/lib/python3.7/LICENSE.txt ./LICENSE
cp $SCRIPT_DIR/PackageInfo.json .
cp $SCRIPT_DIR/*.cmake .

echo "--------------  Cleaning temp folder -----------------"
rm -rf $SCRIPT_DIR/temp

echo "DONE! Package layout folder has been created in $SCRIPT_DIR/package"
exit 0
