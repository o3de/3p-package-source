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
# * Creates an isolated virtual environment for the build helpers.
# * builds python using python.org official mac package builder we've patched.
# * Uses the relocatable-python script to generate a 'package' folder containing real python but
#    with rpaths patched to be relocatable.
# * Replaces the 'identifier' of the main python dylib to be relative to current dir.
# * Deploys the finished framework to a the package layout folder using rsync.
# * Copies the license files inside python to the package layout folder
# * Copies the other package system file (json and cmake) to the pacakge layout folder.
# * Signs every Mach-O file, using ad-hoc signing by default or a configured Developer ID.
#
# The result is a 'package' subfolder containing the package files such as PackageInfo.json
# and a subfolder containing the official python but patched so that they work in that folder structure
# regardless of where the folder is, instead of having absolute paths baked in.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

O3DE_OPENSSL_ROOT="${O3DE_OPENSSL_ROOT:-$SCRIPT_DIR/../../OpenSSL/temp/OpenSSL-mac-arm64/OpenSSL}"
for REQUIRED_OPENSSL_FILE in \
    "$O3DE_OPENSSL_ROOT/include/openssl/ssl.h" \
    "$O3DE_OPENSSL_ROOT/lib/libcrypto.a" \
    "$O3DE_OPENSSL_ROOT/lib/libssl.a" \
    "$O3DE_OPENSSL_ROOT/LICENSE.txt"; do
    if [ ! -f "$REQUIRED_OPENSSL_FILE" ]; then
        echo "Missing prebuilt O3DE OpenSSL file: $REQUIRED_OPENSSL_FILE"
        echo "Build OpenSSL-3.6.3-rev2-mac-arm64 first or set O3DE_OPENSSL_ROOT."
        exit 1
    fi
done
export O3DE_OPENSSL_ROOT

echo ""
echo "--------------- PYTHON PACKAGE BUILD SCRIPT ----------------"
echo ""
echo "BASIC REQUIREMENTS:"
echo "   - git installed and in PATH"
echo "   - XCODE and xcode command line tools installed: xcode-select --install"
echo "   - python3 installed and in PATH."
echo ""

echo "--------------- Clearing any previous package folder ----------------"
echo ""
rm -rf package

echo ""
echo "--------------- Clearing any previous temp folder ----------------"
echo ""
rm -rf temp
mkdir temp
cd temp

mkdir "$SCRIPT_DIR/package"

echo ""
echo "---------------- Cloning python from git ----------------"
echo ""
git clone https://github.com/python/cpython.git --branch "v3.14.7" --depth 1
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error cloning python from https://github.com/python/cpython.git"
    exit $retVal
fi

echo ""
echo ""
echo "---------------- Cloning relocatable-python from git ----------------"
echo ""
git clone https://github.com/gregneagle/relocatable-python.git
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error cloning relocatable-python!"
    exit $retVal
fi

PYTHON_SRC_DIR="$SCRIPT_DIR/temp/cpython"
RELOC_SRC_DIR="$SCRIPT_DIR/temp/relocatable-python"

echo ""
echo "---------------- creating python virtual environment ----------------"
echo ""
cd "$SCRIPT_DIR/temp"
python3 -m venv py_venv
VENV_BIN_DIR="$SCRIPT_DIR/temp/py_venv/bin"
export PYTHONNOUSERSITE=1

echo ""
cd "$RELOC_SRC_DIR"

echo ""
echo "---------------- Checking out specific commit hash of relocatable-python ----------------"
echo ""
# the hash is a known good commit hash.  This also causes it to fail if someone
# tampers the repo!
git reset --hard 5e459c3ccea0daaf181f3b1ef2773dbefce1a563
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error resetting to specific change!"
    exit $retVal
fi

echo ""
echo "---------------- patching the relocator ----------------"
echo ""
patch -p1 < "$SCRIPT_DIR/open3d_patch.patch"
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not patch the relocator!"
    exit $retVal
fi


cd "$PYTHON_SRC_DIR"
echo ""
echo "---------------- patching the python source ----------------"
echo ""
patch -p1 < "$SCRIPT_DIR/open3d_python.patch"
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not patch the python package maker!"
    exit $retVal
fi

echo ""
echo "---------------- Building a Mac python package from official source ----------------"
echo ""
cd "$PYTHON_SRC_DIR"
cd Mac
cd BuildScript

# the following env vars get around a problem compiling tcl/tk
ac_cv_header_libintl_h=no ac_cv_lib_intl_textdomain=no tcl_cv_strtod_buggy=1 ac_cv_func_strtod=yes SDK_TOOLS_BIN="$VENV_BIN_DIR" "$VENV_BIN_DIR/python3" ./build-installer.py --universal-archs=arm64 --build-dir "$SCRIPT_DIR/temp/python_build" --third-party="$SCRIPT_DIR/temp/downloaded_packages" --dep-target=13.0
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not build python!"
    exit $retVal
fi

# the output of the build $SCRIPT_DIR/temp/python_build/_root/Library/Frameworks and that folder will contain Python.framework
# we use the --use-existing-framework to point the script at that framework we just made:
FRAMEWORK_OUTPUT_FOLDER="$SCRIPT_DIR/temp/python_build/_root/Library/Frameworks"
echo "Framework output folder: $FRAMEWORK_OUTPUT_FOLDER"

cd "$RELOC_SRC_DIR"
echo ""
echo "---------------- Altering the produced framework folder to be relocatable ----------------"
echo ""
echo "$VENV_BIN_DIR/python3 ./make_relocatable_python_framework.py --python-version 3.14.7 --use-existing-framework $FRAMEWORK_OUTPUT_FOLDER/Python.framework"
"$VENV_BIN_DIR/python3" ./make_relocatable_python_framework.py --python-version 3.14.7 --use-existing-framework "$FRAMEWORK_OUTPUT_FOLDER/Python.framework"
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not make python relocatable!"
    exit $retVal
fi

echo ""
echo "---------------- Final RPATH update ----------------"
echo ""
# The filename of the main python dylib is 'Python'.
# It is located at ./package/Python.framework/Versions/3.14 (symlinked to Current).
# The original rpath "@rpath/Versions/3.14/Python" is incorrect. When the Python.framework
# is embedded in an app bundle, any executable/shared library linking to it will need to
# find it in "@rpath/Python.framework/Versions/Current/Python". The executable will have
# its rpath set to "<bundle_name>.app/Contents/Frameworks".
# Because all the python framework libraries already have 2 rpaths, the @loader_path
# as well as the root of the framework (ie, @loader_path/../../../.. etc), this makes
# the whole thing work regardless of whether Python is in the same folder as the binary or 
# whether a python native plugin is being located from the framework in some subfolder.
install_name_tool -id @rpath/Python.framework/Versions/Current/Python "$FRAMEWORK_OUTPUT_FOLDER/Python.framework/Versions/3.14/Python"

echo ""
echo "---------------- rsync package layout into $SCRIPT_DIR/package ----------------"
echo ""
mkdir -p "$SCRIPT_DIR/package"
rsync -avu --delete "$FRAMEWORK_OUTPUT_FOLDER/" "$SCRIPT_DIR/package"

echo ""
echo "---------------- Copying Open3DEngine package metadata and license file ----------------"
echo ""
# the tar contains a 'Python.framework' sub folder
cd "$SCRIPT_DIR/package"
cp "$SCRIPT_DIR/package/Python.framework/Versions/3.14/lib/python3.14/LICENSE.txt" ./LICENSE
cp "$O3DE_OPENSSL_ROOT/LICENSE.txt" ./LICENSE.OPENSSL
tar -xOf "$SCRIPT_DIR/temp/downloaded_packages/zstd-1.5.7.tar.gz" zstd-1.5.7/LICENSE > ./LICENSE.ZSTD
cp "$SCRIPT_DIR/PackageInfo.json" .
cp "$SCRIPT_DIR"/*.cmake .

echo ""
echo "---------------- Precompiling Python sources before sealing the framework ----------------"
echo ""
# Relocation invalidates and removes the linker signatures.
# Apple silicon will not execute that unsigned interpreter,
# so first apply a disposable ad-hoc signature.
# The final signing pass below replaces it after bytecode generation.
"$VENV_BIN_DIR/python3" "$SCRIPT_DIR/../../../Scripts/packaging/sign_macos_binaries.py" \
    "$SCRIPT_DIR/package/Python.framework" \
    --identity -

# A signed framework is a sealed bundle.
# If Python creates __pycache__ files on first launch,
# strict bundle verification fails because resources were added after signing.
# Precompile every optimization level in its own process with checked hashes so normal,
# -O, and -OO launches leave the framework unchanged.
for OPTIMIZATION_LEVEL in 0 1 2; do
    "$SCRIPT_DIR/package/Python.framework/Versions/3.14/bin/python3.14" -m compileall \
        -q -f \
        --invalidation-mode checked-hash \
        -o "$OPTIMIZATION_LEVEL" \
        -x 'bad_coding|badsyntax' \
        -s "$SCRIPT_DIR/package" -p "" \
        "$SCRIPT_DIR/package/Python.framework/Versions/3.14/lib/python3.14"
done

echo ""
echo "---------------- Signing binaries ----------------"
echo ""
"$VENV_BIN_DIR/python3" "$SCRIPT_DIR/../../../Scripts/packaging/sign_macos_binaries.py" \
    "$SCRIPT_DIR/package/Python.framework" \
    --entitlements "$SCRIPT_DIR/../../../Scripts/packaging/macos_python_runtime.entitlements"

echo ""
echo "----------------  Cleaning temp folder ----------------"
echo ""
rm -rf "$SCRIPT_DIR/temp"

echo ""
echo "DONE! Package layout folder has been created in $SCRIPT_DIR/package"
exit 0
