#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


BUILD_FOLDER=$TEMP_FOLDER/build


# TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
echo Building source
pushd $TEMP_FOLDER/build

# Run configure 
../src/configure --enable-debug=no --disable-tcl --enable-shared=no --prefix=$TEMP_FOLDER/install --with-pic=yes
if [ $? -ne 0 ]
then
    echo "Unable to configure sqlite" >&2
    exit 1
fi

# Run the make and build
make
if [ $? -ne 0 ]
then
    echo "Unable to build sqlite" >&2
    exit 1
fi

# Install to a temp install folder
make install
if [ $? -ne 0 ]
then
    echo "Unable to install sqlite (release)" >&2
    exit 1
fi

popd

exit 0
