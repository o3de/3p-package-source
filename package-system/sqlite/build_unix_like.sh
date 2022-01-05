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

# Run configure for debug
../src/configure --enable-debug=yes --disable-tcl --enable-shared=no --prefix=$TEMP_FOLDER/install-debug
if [ $? -eq 0 ]
then
    echo "Configure complete (debug)"
else
    echo "Unable to configure sqlite (debug)" >&2
    exit 1
fi

# Run the make and build for debug
make
if [ $? -eq 0 ]
then
    echo "Build complete (debug)"
else
    echo "Unable to build sqlite (debug)" >&2
    exit 1
fi

# Install the debug build to a temp install for debug
make install
if [ $? -eq 0 ]
then
    echo "Temp install complete (debug)"
else
    echo "Unable to install sqlite (debug)" >&2
    exit 1
fi

# Clean and prepare for the release build
make distclean

# Run configure for release
../src/configure --enable-debug=no --disable-tcl --enable-shared=no --prefix=$TEMP_FOLDER/install-release
if [ $? -eq 0 ]
then
    echo "Configure complete (release)"
else
    echo "Unable to configure sqlite (release)" >&2
    exit 1
fi

# Run the make and build for release
make
if [ $? -eq 0 ]
then
    echo "Build complete (release)"
else
    echo "Unable to build sqlite (release)" >&2
    exit 1
fi

# Install the debug build to a temp install for debug
make install
if [ $? -eq 0 ]
then
    echo "Temp install complete (release)"
else
    echo "Unable to install sqlite (release)" >&2
    exit 1
fi

popd

exit 0
