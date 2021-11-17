#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

set -euo pipefail

# Limit Ninja jobs lower to avoid out of memory issues build qtwebengine
export NINJAJOBS=-j12
MAKE_FLAGS=-j32

# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
# We use Miniconda to get a Python 2.7 executable, which is needed for WebEngine to build
MINICONDA_PATH=$TEMP_FOLDER/miniconda

export PATH=$MINICONDA_PATH:$PATH

# Replace PYTHONPATH with our Miniconda Python paths so that only the Python 2.7 from Miniconda
# will be found. Otherwise, there will be an invalid syntax error in site.py because the build
# machine will likely have a different version of Python (most likely Python 3) on the PATH,
# and since the build_package script will be launched from the Python 3 that is pulled down
# for O3DE, its paths will be in the PATH as well.
export PYTHONPATH=$MINICONDA_PATH:$MINICONDA_PATH/lib

BUILD_PATH=$TEMP_FOLDER/build
if [[ "$OSTYPE" == "darwin"* ]]; then
    EXTRA_CONFIG_OPTIONS=""
else
    EXTRA_CONFIG_OPTIONS="-c++std c++1z \
    -openssl \
    -reduce-relocations \
    -fontconfig"
fi

[[ -d $BUILD_PATH ]] || mkdir $BUILD_PATH
cd $BUILD_PATH

echo Configuring Qt...
../src/configure \
-prefix ${TARGET_INSTALL_ROOT} \
-opensource \
-nomake examples \
-nomake tests \
-confirm-license \
-no-icu \
-dbus \
-no-separate-debug-info \
-release \
-force-debug-info \
-qt-libpng \
-qt-libjpeg \
-no-feature-vnc \
-no-feature-linuxfb \
-qt-zlib \
-v \
-no-cups \
-no-glib \
-no-feature-renameat2 \
-no-feature-getentropy \
-no-feature-statx \
-no-egl \
$EXTRA_CONFIG_OPTIONS

echo Qt configured, building modules...
qtarray=(qtbase qtgraphicaleffects qtimageformats qtsvg qttools qtwebengine)
if [[ "$OSTYPE" == "darwin"* ]]; then
    qtarray+=(qtmacextras qttranslations)
fi

for qtlib in "${qtarray[@]}"; do
    echo Building $qtlib...
    make module-$qtlib $MAKE_FLAGS
    echo Built $qtlib.
done

echo Finished building modules, installing...
for qtlib in "${qtarray[@]}"; do
    echo Installing $qtlib...
    make module-$qtlib-install_subtargets
    echo $qtlib installed.
done
echo Qt installed successfully!
