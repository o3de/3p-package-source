#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake -S temp/src -B temp/build -G Xcode -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 \
                                         -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
                                         -DCMAKE_C_FLAGS="-fPIC" \
                                         -DBUILD_SHARED_LIBS=OFF \
                                         -Djpeg=OFF -Dold-jpeg=OFF -Dpixarlog=OFF \
                                         -Dlzma=OFF \
                                         -Dzlib=ON -DZLIB_ROOT=../zlib-mac/zlib

if [ $? -ne 0 ]; then
    echo "Error generating build"
    exit 1
fi

cmake --build temp/build --target tiff --config Release -j 8
if [ $? -ne 0 ]; then
    echo "Error building"
    exit 1
fi

