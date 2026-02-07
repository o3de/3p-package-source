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

cd $TEMP_FOLDER/src/physx

# Generate the project

mkdir -p $TEMP_FOLDER/install
export CMAKE_INSTALL_PREFIX=$TEMP_FOLDER/install

./generate_projects.sh mac64

# Hack: The Xcode project generator generates duplicate "-framework OpenGL" when it is suppose to generate 
# "-framework OpenGL" and "-framework GLUT", causing a linker error.  After project generation, we will
# replace the duplicate 
#      "-framework OpenGL", "-framework OpenGL"
# with the correct
#      "-framework OpenGL", "-framework GLUT"
# to the pbx project files for both the main project and the snippets project.

echo "Patching PhysX Xcode project files to fix duplicate -framework OpenGL linker flags"
sed -i '' -e 's/\"\-framework OpenGL\"\,\"\-framework OpenGL\"\,/\"\-framework OpenGL\"\,\"\-framework GLUT\"\,/g' $TEMP_FOLDER/src/physx/compiler/mac64/PhysXSDK.xcodeproj/project.pbxproj

echo "Patching PhysX Snippets Xcode project files to fix duplicate -framework OpenGL linker flags"
sed -i '' -e 's/\"\-framework OpenGL\"\,\"\-framework OpenGL\"\,/\"\-framework OpenGL\"\,\"\-framework GLUT\"\,/g' $TEMP_FOLDER/src/physx/compiler/mac64/sdk_snippets_bin/Snippets.xcodeproj/project.pbxproj

echo "Building PhysX / release"

configs=("release", "debug", "profile")

cmake --build $TEMP_FOLDER/src/physx/compiler/mac64 --config release --target install

cmake --build $TEMP_FOLDER/src/physx/compiler/mac64 --config profile

cmake --build $TEMP_FOLDER/src/physx/compiler/mac64 --config debug

echo "PhysX build complete"

exit 0
