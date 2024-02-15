#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

echo "Testing python.."

echo temp/build/python/bin/python3 --version 
temp/build/python/bin/python3 --version 2>&1
if [ $? -ne 0 ]
then
    echo "Error running validating python interpreter version"
    exit 1
fi

echo temp/build/python/bin/python3 quick_validate_python.py
temp/build/python/bin/python3 quick_validate_python.py 2>&1
if [ $? -ne 0 ]
then
    echo "Error running the python interpreter against quick_validate_python.py"
    exit 1
fi

exit 0
