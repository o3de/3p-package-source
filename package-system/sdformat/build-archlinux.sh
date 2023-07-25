#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# The function below is used to check if the docker application
# is installed via checking the ArchLinux package manager
function check_docker_requirements()
{
    echo "Checking cross compiling requirements."
    pkg_list=(docker docker-buildx docker-compose qemu qemu-user-static-binfmt)
    for package_check in "${pkg_list[@]}"
    do
        echo "Checking package $package_check"
        pacman -Qi $package_check > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            echo ""
            echo "Missing package $package_check. Make sure to install it with your local package manager."
            echo ""
            return 1
        fi
    done

    # Only cross compilation of an ARM64 image on an x86_64 host is supported
    if [ "${TARGET_ARCH}" = "aarch64" ]
    then
        # Make sure qemu-system-aarch64 is installed properly
        pacman -Qi qemu-system-aarch64 > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            echo ""
            echo "qemu-system-aarch64 package needs to be installed."
            echo "Use pacman to install it"
            exit 1
        fi

        echo ""
        echo "Cross compiling aarch64 on an amd64 machine validated."
        echo ""
    fi
}

source ./build-linux.sh "$@" "check_docker_requirements"
