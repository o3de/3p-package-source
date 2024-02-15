#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

echo "Testing python.."

echo LD_LIBRARY_PATH=temp/build/python/lib
export LD_LIBRARY_PATH=temp/build/python/lib

echo temp/build/python/bin/python3 quick_validate_python.py
temp/build/python/bin/python3 quick_validate_python.py

exit $?
