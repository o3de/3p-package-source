#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# The CMakeLists.txt included with zlib unconditionally makes all the dylibs AND also
# makes "appplication" executables.  This is not great for making a sdk for ios.
# this custom script just runs it building the static lib only:
cmake -S temp/src -B temp/build -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_CXX_STANDARD=17 -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_C_FLAGS="-fPIC" -DSKIP_INSTALL_FILES=YES
cmake --build temp/build --target zlibstatic --config Release -j 8
