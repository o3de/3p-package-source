#!/bin/bash

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#


CURRENT_HOST_ARCH=$(uname -m)

if [ "${CURRENT_HOST_ARCH}" = "x86_64" ]
then

  	echo "Checking cross compiling aarch64 on an amd64 machine requirements."

	# If the current host architecture does not match the expected 'aarch64' architecture, then make sure we have 
	# necessary packages and configuration needed to run docker in an emulated aarch64 environment
	for package_check in docker-ce qemu binfmt-support qemu-user-static
    do
        echo "Checking package $package_check"
        dpkg -s $package_check > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
        	echo ""
        	echo "Missing package $package_check. Make sure to install it with your local package manager." 
        	echo ""
        	exit 1
        fi
    done
    # Make sure qemu-aarch64 is installed properly
    QEMU_AARCH_COUNT=$(update-binfmts --display | grep qemu-aarch65 | wc -l)
    if [ $QEMU_AARCH_COUNT -eq 1 ]
    then
		echo ""
    	echo "QEMU aarch64 binary format not registered."
    	echo "Run the following command to register"
    	echo ""
    	echo "sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
    	echo ""
    	exit 1
    fi
	echo ""
    echo "Cross compiling aarch64 on an amd64 machine validated."
    echo ""

fi

./build-linux.sh aarch64

exit $?
