#!/bin/bash
#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

LIB_NAME=sdformat
# Validate the build directory
BUILD_FOLDER=${DOCKER_BUILD_PATH}
if [ "${BUILD_FOLDER}" == "" ]
then
    echo "Missing required build target folder environment"
    exit 1
elif [ "${BUILD_FOLDER}" == "temp" ]
then
    echo "Build target folder environment cannot be 'temp'"
    exit 1
fi

# Set the install path from the DOCKER_INSTALL_PATH argument
INSTALL_FOLDER=${DOCKER_INSTALL_PATH}

# Stores array of each installed dependency after building locally
DEP_INSTALL_PATHS=()

# Get the base directory where the source file for dependencies will be fetched to
GIT_DEPS_BASE=/data/workspace/deps
GIT_DEPS_BUILD_ROOT=${GIT_DEPS_BASE}/build

# Build the dependent tinyxml2 library
DEP_NAME=tinyxml2
GZ_TINYXML2_SRC_FOLDER=${GIT_DEPS_BASE}/$DEP_NAME
GZ_TINYXML2_BUILD_FOLDER=${GIT_DEPS_BUILD_ROOT}/$DEP_NAME
# Install the tinyxml2 library files to the local filesystem
GZ_TINYXML2_INSTALL_FOLDER=${LOCAL_FILESYSTEM}/deps/install

if [ -d ${GIT_DEPS_BUILD_ROOT} ]; then
    rm -rf ${GIT_DEPS_BUILD_ROOT}
fi

# Append the tinyxml2 install folder
DEP_INSTALL_PATHS+=( $GZ_TINYXML2_INSTALL_FOLDER )
pushd $GZ_TINYXML2_SRC_FOLDER

echo "Configuring $DEP_NAME"
CMD="cmake -B ${GZ_TINYXML2_BUILD_FOLDER} -S. -DCMAKE_INSTALL_PREFIX=${GZ_TINYXML2_INSTALL_FOLDER} -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring $DEP_NAME"
    exit 1
fi

echo "Building and installing $DEP_NAME"
CMD="cmake --build $GZ_TINYXML2_BUILD_FOLDER --target install --config Release"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building $DEP_NAME"
    exit 1
fi

popd

# Build the dependent gz-cmake library
DEP_NAME=gz-cmake
GZ_CMAKE_SRC_FOLDER=${GIT_DEPS_BASE}/$DEP_NAME
GZ_CMAKE_BUILD_FOLDER=${GIT_DEPS_BUILD_ROOT}/$DEP_NAME
# Install gz-cmake to the mounted local filesystem
GZ_CMAKE_INSTALL_FOLDER=${LOCAL_FILESYSTEM}/deps/install

# Append the gz-cmake install folder
DEP_INSTALL_PATHS+=( $GZ_CMAKE_INSTALL_FOLDER )

pushd $GZ_CMAKE_SRC_FOLDER

echo "Configuring $DEP_NAME"
CMD="cmake -B ${GZ_CMAKE_BUILD_FOLDER} -S. -DCMAKE_INSTALL_PREFIX=${GZ_CMAKE_INSTALL_FOLDER} -DBUILD_TESTING=OFF"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring $DEP_NAME"
    exit 1
fi

echo "Building and installing $DEP_NAME"
CMD="cmake --build $GZ_CMAKE_BUILD_FOLDER --target install --config Release"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building $DEP_NAME"
    exit 1
fi

popd

# Build the dependent gz-utils library
# NOTE: This must be done after gz-cmake it depends on that library
DEP_NAME=gz-utils
GZ_UTILS_SRC_FOLDER=${GIT_DEPS_BASE}/$DEP_NAME
GZ_UTILS_BUILD_FOLDER=${GIT_DEPS_BUILD_ROOT}/$DEP_NAME
# install gz-utils to the local filesystem
GZ_UTILS_INSTALL_FOLDER=${LOCAL_FILESYSTEM}/deps/install

# Append the gz-utils install folder
DEP_INSTALL_PATHS+=( $GZ_UTILS_INSTALL_FOLDER )
pushd $GZ_UTILS_SRC_FOLDER

echo "Configuring $DEP_NAME"
CMD="cmake -B ${GZ_UTILS_BUILD_FOLDER} -S. -DCMAKE_INSTALL_PREFIX=${GZ_UTILS_INSTALL_FOLDER} -DBUILD_TESTING=OFF"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring $DEP_NAME"
    exit 1
fi

echo "Building and installing $DEP_NAME"
CMD="cmake --build $GZ_UTILS_BUILD_FOLDER --target install --config Release"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building $DEP_NAME"
    exit 1
fi

popd

# Build the dependent gz-math library
# NOTE: This must be done after gz-cmake and gz-utils as it depends on those libraries
DEP_NAME=gz-math
GZ_MATH_SRC_FOLDER=${GIT_DEPS_BASE}/$DEP_NAME
GZ_MATH_BUILD_FOLDER=${GIT_DEPS_BUILD_ROOT}/$DEP_NAME
GZ_MATH_INSTALL_FOLDER=${LOCAL_FILESYSTEM}/deps/install

# Append the gz-math install folder
DEP_INSTALL_PATHS+=( $GZ_MATH_INSTALL_FOLDER )
pushd $GZ_MATH_SRC_FOLDER

echo "Configuring $DEP_NAME"
CMD="cmake -B ${GZ_MATH_BUILD_FOLDER} -S. -DCMAKE_INSTALL_PREFIX=${GZ_MATH_INSTALL_FOLDER} -DSKIP_SWIG=ON -DSKIP_PYBIND11=ON -DBUILD_TESTING=OFF"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring $DEP_NAME"
    exit 1
fi

echo "Building and installing $DEP_NAME"
CMD="cmake --build $GZ_MATH_BUILD_FOLDER --target install --config Release"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building $DEP_NAME"
    exit 1
fi

popd

# Now build the SDF library
pushd ${LOCAL_FILESYSTEM}/src

# Convert the dependent install path array in bash to a cmake list
CMAKE_PREFIX_PATH=${DEP_INSTALL_PATHS[0]}
# splace the first element of the array and then join with the semicolon CMake delimiter
SPLICED_INSTALL_PATHS=(${DEP_INSTALL_PATHS[@]:1})
CMAKE_PREFIX_PATH+=$(printf ";%s" "${SPLICED_INSTALL_PATHS[@]}")
# Supply the CMAKE_PREFIX_PATH to allow the dependent libraries of gz-cmake to be located

# Remove the build folder if it exist
if [ -d ${BUILD_FOLDER} ]; then
    rm -rf ${BUILD_FOLDER}
fi

echo "Configuring ${LIB_NAME}"
CMD="cmake -B ${BUILD_FOLDER} -S. -DUSE_INTERNAL_URDF=ON -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=${INSTALL_FOLDER} -DCMAKE_PREFIX_PATH=\"${CMAKE_PREFIX_PATH}\""
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error configuring ${LIB_NAME}"
    exit 1
fi

if [ -d ${INSTALL_FOLDER} ]; then
    echo "Removing artifacts from existing ${INSTALL_FOLDER}"
    rm -rf ${INSTALL_FOLDER}
fi
echo "Building and installing ${LIB_NAME} to ${INSTALL_FOLDER}"
CMD="cmake --build ${BUILD_FOLDER} --target install --config Release"
echo $CMD
eval $CMD
if [ $? -ne 0 ]
then
    echo "Error building ${LIB_NAME}"
    exit 1
fi

popd

exit 0
