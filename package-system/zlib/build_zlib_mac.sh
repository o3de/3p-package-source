#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# note that toolchain path is relative to the source path (-S) not to the folder this script lives in.
cmake -S temp/src -B temp/build -G Xcode \
    -DSKIP_INSTALL_FILES=YES \
    -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/Mac/Toolchain_mac.cmake || exit 1

cmake --build temp/build --target zlibstatic --parallel --config Release -j 8 || exit 1


