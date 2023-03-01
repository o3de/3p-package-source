#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# The tests leave behind temp files in the current working directory.
# Change to a temp subdirectory to keep the working directory clean.
cd temp
rm -rf test_out
mkdir test_out
cd test_out

../build/bin/unit || exit 1
exit 0

