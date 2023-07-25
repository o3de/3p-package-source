#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# Query the Host OS from the the os-release file
HOST_OS=$(cat /etc/os-release 2>/dev/null | grep "^NAME" | sed -E -e 's/NAME=(.+)/\1/')
# Remove any surrounding quotes from the OS
HOST_OS=$(sed -E 's/^"(.*)"$/\1/' <<< ${HOST_OS})

if [ "${HOST_OS}" = "Arch Linux" ]; then
    bash ./build-archlinux.sh "$@"
elif [ "${HOST_OS}" = "Ubuntu" ]; then
    bash ./build-ubuntu.sh "$@"
else
    echo "Build script for Host Platform \"${HOST_OS}\" is not available"
    exit 1
fi

exit $?
