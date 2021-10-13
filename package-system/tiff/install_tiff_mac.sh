#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

OUT_PATH=$TARGET_INSTALL_ROOT
SRC_PATH=temp/src
BLD_PATH=temp/build

# these can fail if they are already there and we're working incrementally, this is okay
# if they fail completely, the below checks will error anyway
mkdir -p $OUT_PATH
mkdir -p $OUT_PATH/lib
mkdir -p $OUT_PATH/include

cp -f $SRC_PATH/COPYRIGHT $OUT_PATH/ || exit 1
cp $BLD_PATH/libtiff/Release/libtiff.a $OUT_PATH/lib/libtiff.a || exit 1
cp $BLD_PATH/libtiff/tiffconf.h $OUT_PATH/include/tiffconf.h || exit 1
cp $SRC_PATH/libtiff/tiff.h $OUT_PATH/include/tiff.h || exit 1
cp $SRC_PATH/libtiff/tiffvers.h $OUT_PATH/include/tiffvers.h || exit 1
cp $SRC_PATH/libtiff/tiffio.h $OUT_PATH/include/tiffio.h || exit 1


exit 0
