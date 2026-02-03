#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

set -euo pipefail

# Prepare and generate the mac-arm64 project scripts
pushd $TEMP_FOLDER/src

cd $TEMP_FOLDER/src/physx/buildtools/packman
./packman update -y

cd $TEMP_FOLDER/src/physx
./generate_projects.sh mac-arm64

# Newer versions of apple clang are stricter and require certain include paths to exist.
# Hack to populate these missing includes folders even though they are not needed for the build
mkdir -p $TEMP_FOLDER/src/physx/source/Common/src/mac
mkdir -p $TEMP_FOLDER/src/physx/source/LowLevel/mac/include
mkdir -p $TEMP_FOLDER/src/physx/source/foundation/include
mkdir -p $TEMP_FOLDER/src/physx/source/pvdsdk/src
mkdir -p $TEMP_FOLDER/src/physx/source/cudamanager/include
mkdir -p $TEMP_FOLDER/src/physx/include/foundation/linux
mkdir -p $TEMP_FOLDER/src/physx/source/LowLevelAABB/mac/include
mkdir -p $TEMP_FOLDER/src/physx/source/GpuBroadPhase/include
mkdir -p $TEMP_FOLDER/src/physx/source/GpuBroadPhase/src
mkdir -p $TEMP_FOLDER/src/physx/source/immediatemode/include
mkdir -p $TEMP_FOLDER/src/physx/source/omnipvd
mkdir -p $TEMP_FOLDER/src/physx/source/lowlevel/software/include/mac
mkdir -p $TEMP_FOLDER/src/physx/source/lowleveldynamics/include/mac
mkdir -p $TEMP_FOLDER/src/physx/source/lowlevel/common/include/pipeline/mac

modules=("SimulationController" "SceneQuery" "PhysXVehicle2" "PhysXVehicle" "PhysXTask" "PhysXPvdSDK" "PhysXFoundation" "PhysXExtensions" "PhysXCooking" "PhysXCommon" "LowLevelAABB" "PhysXCharacterKinematic" "PhysX" "LowLevelDynamics" "LowLevel" "FastXml")
configs=("release" "profile" "checked" "debug")

for module in "${modules[@]}"; do
  echo "Making paths for $module"
  for config in "${configs[@]}"; do
    mkdir -p $TEMP_FOLDER/src/physx/compiler/mac-arm64/build/$module.build/$config/include
    mkdir -p $TEMP_FOLDER/src/physx/compiler/mac-arm64/build/$module.build/$config/DerivedSources-normal/arm64
    mkdir -p $TEMP_FOLDER/src/physx/compiler/mac-arm64/build/$module.build/$config/DerivedSources/arm64
    mkdir -p $TEMP_FOLDER/src/physx/compiler/mac-arm64/build/$module.build/$config/DerivedSources
  done
done

# Build each of the flavors of the static libraries
for config in "${configs[@]}"; do
  mkdir -p $TEMP_FOLDER/src/physx/bin/mac.x86_64/$config/include
  if [ "$config" = "release" ]; then
    cmake --build $TEMP_FOLDER/src/physx/compiler/mac-arm64 --config $config --target install
  else
    cmake --build $TEMP_FOLDER/src/physx/compiler/mac-arm64 --config $config
  fi
done

echo "PhysX5 build complete"

exit 0
