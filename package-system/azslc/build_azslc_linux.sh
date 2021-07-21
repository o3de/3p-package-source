#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

cd temp/src

./prepare_solution_linux.sh
if [ $? -eq 0 ]
then
    echo "Built binaries for Linux successfully"
else
    echo "Failed to build binaries for Linux"
    exit $?
fi

cd tests

./launch_tests_linux.sh

TEST_RESULT=$?

cd ..

if [ $TEST_RESULT -eq 0 ]
then
    echo "Linux Tests Passed"
else
    echo "Linux Tests Failed"
fi

exit $TEST_RESULT
