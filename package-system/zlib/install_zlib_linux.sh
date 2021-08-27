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

mkdir -p $OUT_PATH

cp -f $SRC_PATH/LICENSE $OUT_PATH/
mkdir -p $OUT_PATH/lib
mkdir -p $OUT_PATH/include

cp $BLD_PATH/libz.a $OUT_PATH/lib/libz.a
cp $BLD_PATH/zconf.h $OUT_PATH/include/zconf.h
cp $SRC_PATH/zlib.h $OUT_PATH/include/zlib.h
cp FindZLIB_compat_unixlike.cmake $OUT_PATH/FindZLIB.cmake
exit 0
