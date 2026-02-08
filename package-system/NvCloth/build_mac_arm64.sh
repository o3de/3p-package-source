#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

set -euo pipefail

# Prepare and generate the mac-arm64 project scripts

export GW_DEPS_ROOT=$TEMP_FOLDER/src

pushd $TEMP_FOLDER/src

cmake NvCloth/compiler/cmake/mac -B NvCloth/build/mac -G \
         Xcode -DTARGET_BUILD_PLATFORM=mac \
         -DNV_CLOTH_ENABLE_CUDA=0 \
         -DUSE_CUDA=0 \
         -DPX_GENERATE_GPU_PROJECTS=0 \
         -DPX_STATIC_LIBRARIES=1 \
         -DPX_OUTPUT_DLL_DIR=NvCloth/bin/osx64-cmake \
         -DPX_OUTPUT_LIB_DIR=NvCloth/lib/osx64-cmake \
         -DPX_OUTPUT_EXE_DIR=NvCloth/bin/osx64-cmake

cmake --build NvCloth/build/mac --config debug

cmake --build NvCloth/build/mac --config profile

cmake --build NvCloth/build/mac --config release

exit 0

