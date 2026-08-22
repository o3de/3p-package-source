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

if [ -n "${TEMP_FOLDER:-}" ] && [ -n "${TARGET_INSTALL_ROOT:-}" ] && [ -n "${PACKAGE_ROOT:-}" ]; then
    USING_PACKAGE_BUILDER=1
    WORK_DIR="$TEMP_FOLDER/darwin-arm64-build"
    PYTHON_SRC_DIR="$TEMP_FOLDER/src"
    PACKAGE_OUTPUT_DIR="$TARGET_INSTALL_ROOT"
    PACKAGE_LAYOUT_DIR="$PACKAGE_ROOT"
    DOWNLOADED_OPENSSL_PACKAGE="${DOWNLOADED_PACKAGE_FOLDERS:-}"
    DOWNLOADED_OPENSSL_PACKAGE="${DOWNLOADED_OPENSSL_PACKAGE%%;*}"
    DEFAULT_OPENSSL_ROOT="$DOWNLOADED_OPENSSL_PACKAGE/OpenSSL"
else
    USING_PACKAGE_BUILDER=0
    WORK_DIR="$SCRIPT_DIR/temp"
    PYTHON_SRC_DIR="$WORK_DIR/cpython"
    PACKAGE_LAYOUT_DIR="$SCRIPT_DIR/package"
    PACKAGE_OUTPUT_DIR="$PACKAGE_LAYOUT_DIR/python"
    DEFAULT_OPENSSL_ROOT="$SCRIPT_DIR/../../OpenSSL/temp/OpenSSL-mac-arm64/OpenSSL"
fi

O3DE_OPENSSL_ROOT="${O3DE_OPENSSL_ROOT:-$DEFAULT_OPENSSL_ROOT}"
for REQUIRED_OPENSSL_FILE in \
    "$O3DE_OPENSSL_ROOT/include/openssl/ssl.h" \
    "$O3DE_OPENSSL_ROOT/lib/libcrypto.a" \
    "$O3DE_OPENSSL_ROOT/lib/libssl.a" \
    "$O3DE_OPENSSL_ROOT/LICENSE.txt"; do
    if [ ! -f "$REQUIRED_OPENSSL_FILE" ]; then
        echo "Missing prebuilt O3DE OpenSSL file: $REQUIRED_OPENSSL_FILE"
        echo "Build the macOS ARM OpenSSL package first or set O3DE_OPENSSL_ROOT."
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
if [ "$USING_PACKAGE_BUILDER" -eq 0 ]; then
    rm -rf "$PACKAGE_LAYOUT_DIR"
fi
rm -rf "$PACKAGE_OUTPUT_DIR"
mkdir -p "$PACKAGE_OUTPUT_DIR"

echo ""
echo "--------------- Clearing any previous temp folder ----------------"
echo ""
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

if [ "$USING_PACKAGE_BUILDER" -eq 0 ]; then
    echo ""
    echo "---------------- Cloning python from git ----------------"
    echo ""
    git clone https://github.com/python/cpython.git --branch "v3.14.7" --depth 1 "$PYTHON_SRC_DIR"
    retVal=$?
    if [ $retVal -ne 0 ]; then
        echo "Error cloning python from https://github.com/python/cpython.git"
        exit $retVal
    fi
fi

echo ""
echo ""
echo "---------------- Cloning relocatable-python from git ----------------"
echo ""
git clone https://github.com/gregneagle/relocatable-python.git "$WORK_DIR/relocatable-python"
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error cloning relocatable-python!"
    exit $retVal
fi

RELOC_SRC_DIR="$WORK_DIR/relocatable-python"

echo ""
echo "---------------- creating python virtual environment ----------------"
echo ""
cd "$WORK_DIR"
python3 -m venv py_venv
VENV_BIN_DIR="$WORK_DIR/py_venv/bin"
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
ac_cv_header_libintl_h=no ac_cv_lib_intl_textdomain=no tcl_cv_strtod_buggy=1 ac_cv_func_strtod=yes SDK_TOOLS_BIN="$VENV_BIN_DIR" "$VENV_BIN_DIR/python3" ./build-installer.py --universal-archs=arm64 --build-dir "$WORK_DIR/python_build" --third-party="$WORK_DIR/downloaded_packages" --dep-target=13.0
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Could not build python!"
    exit $retVal
fi

# the output of the build $WORK_DIR/python_build/_root/Library/Frameworks and that folder will contain Python.framework
# we use the --use-existing-framework to point the script at that framework we just made:
FRAMEWORK_OUTPUT_FOLDER="$WORK_DIR/python_build/_root/Library/Frameworks"
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
echo "---------------- rsync package layout into $PACKAGE_OUTPUT_DIR ----------------"
echo ""
mkdir -p "$PACKAGE_OUTPUT_DIR"
rsync -avu --delete "$FRAMEWORK_OUTPUT_FOLDER/" "$PACKAGE_OUTPUT_DIR"

echo ""
echo "---------------- Copying Open3DEngine package metadata and license file ----------------"
echo ""
# the tar contains a 'Python.framework' sub folder
cd "$PACKAGE_OUTPUT_DIR"
cp "$PACKAGE_OUTPUT_DIR/Python.framework/Versions/3.14/lib/python3.14/LICENSE.txt" ./LICENSE
cp "$O3DE_OPENSSL_ROOT/LICENSE.txt" ./LICENSE.OPENSSL
tar -xOf "$WORK_DIR/downloaded_packages/zstd-1.5.7.tar.gz" zstd-1.5.7/LICENSE > ./LICENSE.ZSTD
if [ "$USING_PACKAGE_BUILDER" -eq 0 ]; then
    cp "$SCRIPT_DIR/PackageInfo.json" "$PACKAGE_LAYOUT_DIR"
    cp "$SCRIPT_DIR"/*.cmake "$PACKAGE_LAYOUT_DIR"
fi

echo ""
echo "---------------- Precompiling Python sources before sealing the framework ----------------"
echo ""
# Relocation invalidates and removes the linker signatures.
# Apple silicon will not execute that unsigned interpreter,
# so first apply a disposable ad-hoc signature.
# The final signing pass below replaces it after bytecode generation.
"$VENV_BIN_DIR/python3" "$SCRIPT_DIR/../../../Scripts/packaging/sign_macos_binaries.py" \
    "$PACKAGE_OUTPUT_DIR/Python.framework" \
    --identity -

# A signed framework is a sealed bundle.
# If Python creates __pycache__ files on first launch,
# strict bundle verification fails because resources were added after signing.
# Precompile every optimization level in its own process with checked hashes so normal,
# -O, and -OO launches leave the framework unchanged.
for OPTIMIZATION_LEVEL in 0 1 2; do
    "$PACKAGE_OUTPUT_DIR/Python.framework/Versions/3.14/bin/python3.14" -m compileall \
        -q -f \
        --invalidation-mode checked-hash \
        -o "$OPTIMIZATION_LEVEL" \
        -x 'bad_coding|badsyntax' \
        -s "$PACKAGE_OUTPUT_DIR" -p "" \
        "$PACKAGE_OUTPUT_DIR/Python.framework/Versions/3.14/lib/python3.14"
done

echo ""
echo "---------------- Signing binaries ----------------"
echo ""
"$VENV_BIN_DIR/python3" "$SCRIPT_DIR/../../../Scripts/packaging/sign_macos_binaries.py" \
    "$PACKAGE_OUTPUT_DIR/Python.framework" \
    --entitlements "$SCRIPT_DIR/../../../Scripts/packaging/macos_python_runtime.entitlements"

echo ""
echo "----------------  Cleaning temp folder ----------------"
echo ""
rm -rf "$WORK_DIR"

echo ""
echo "DONE! Package layout folder has been created in $PACKAGE_LAYOUT_DIR"
exit 0
