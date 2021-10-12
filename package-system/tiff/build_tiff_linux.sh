#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# note that we explicitly turn off the compilation of all features that rely on 3rd Party Libraries
# except the ones we want.  This prevents the cmake build system from automatically finding things
# if they happen to be installed locally, which we don't want.
cmake -S temp/src -B temp/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DCMAKE_C_FLAGS="-fPIC" \
    -DBUILD_SHARED_LIBS=OFF \
    -Djpeg=OFF \
    -Dold-jpeg=OFF \
    -Dpixarlog=OFF \
    -Dlzma=OFF \
    -Dwebp=OFF \
    -Djbig=OFF \
    -Dzstd=OFF \
    -Djpeg12=OFF \
    -Dzlib=ON \
    -Dlibdeflate=OFF \
    -Dcxx=OFF \
    -DCMAKE_MODULE_PATH="$DOWNLOADED_PACKAGE_FOLDERS" || exit 1

cmake --build temp/build --target tiff --parallel || exit 1
