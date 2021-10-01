#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake -S temp/src -B temp/build \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_C_FLAGS=-fPIC \
     -DSKIP_INSTALL_FILES=YES || exit 1

cmake --build temp/build --target zlibstatic --parallel || exit 1

