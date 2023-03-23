#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

HOST_OS=$(cat /etc/os-release 2>/dev/null | grep "^NAME" | sed -E -e 's/NAME=(.+)/\1/')
# Remove any surrounding quotes from the OS
HOST_OS=$(sed -E 's/^"(.*)"$/\1/' <<< ${HOST_OS})

if [ "${HOST_OS}" = "Arch Linux" ]; then
    ./build-archlinux.sh x86_64
else
    ./build-linux.sh x86_64
fi

exit $?
