#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
set -o pipefail

echo "TARGET_INSTALL_ROOT=$TARGET_INSTALL_ROOT"
echo "PACKAGE_ROOT=$PACKAGE_ROOT"
echo "TEMP_FOLDER=$TEMP_FOLDER"

# Use the sse2neon header to provide a translation between sse to neon for arm processing
git clone https://github.com/DLTcollab/sse2neon.git $TEMP_FOLDER/sse2neon
git -C $TEMP_FOLDER/sse2neon checkout v1.6.0
cp $TEMP_FOLDER/sse2neon/sse2neon.h $TEMP_FOLDER/src/

# Configure the squish ccr code under $TEMP_FOLDER/src
cmake -S $TEMP_FOLDER/src \
      -B $TEMP_FOLDER/build \
      -G Xcode \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_CXX_FLAGS="-fPIC -O2 -Wno-shorten-64-to-32" \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$TARGET_INSTALL_ROOT

# Build the project 
cmake --build $TEMP_FOLDER/build --target install

# Copy the sse2neon LICENSE to the package as well
cp $TEMP_FOLDER/sse2neon/LICENSE $TARGET_INSTALL_ROOT/LICENSE.sse2neon

exit 0
