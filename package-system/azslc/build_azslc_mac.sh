#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

cd temp/src

./prepare_solution_darwin.sh
if [ $? -eq 0 ]
then
    echo "Built binaries for Mac successfully"
else
    echo "Failed to build binaries for Mac"
    exit $?
fi

cd tests

./launch_tests.sh

TEST_RESULT=$?

cd ..

if [ $TEST_RESULT -eq 0 ]
then
    echo "Mac Tests Passed"
else
    echo "Mac Tests Failed"
fi

exit $TEST_RESULT
