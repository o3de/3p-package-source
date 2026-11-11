#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT


# ELF symbol checks also work when packaging for another architecture.
for binary in "$TARGET_INSTALL_ROOT/bin/python3" \
    "$TARGET_INSTALL_ROOT/lib/libpython3.15.so.1.0" \
    "$TARGET_INSTALL_ROOT"/lib/python3.15/lib-dynload/*.so; do
    if ! readelf --wide --sections "$binary" | grep -E '[.](zdebug_info|debug_info)[[:space:]]' > /dev/null; then
        echo "Missing debug information: $binary"
        exit 1
    fi
done

# Only run tests for packages on the same architecture
TARGET_ARCH=$1
CURRENT_HOST_ARCH=$(uname -m)

if [ "${CURRENT_HOST_ARCH}" != "${TARGET_ARCH}" ]
then
    echo Cannot run the test for a ${TARGET_ARCH} on the current ${CURRENT_HOST_ARCH} architecture. Skipping test.
    exit 0
fi

echo "Testing python"


echo "$TARGET_INSTALL_ROOT/bin/python3 --version"
"$TARGET_INSTALL_ROOT/bin/python3" --version 2>&1
if [ $? -ne 0 ]
then
    echo "Error running validating python interpreter version"
    exit 1
fi

echo "$TARGET_INSTALL_ROOT/bin/python3 quick_validate_python.py"
"$TARGET_INSTALL_ROOT/bin/python3" quick_validate_python.py 2>&1
if [ $? -ne 0 ]
then
    echo "Error running the python interpreter against quick_validate_python.py"
    exit 1
fi

PIP_OUTPUT=$("$TARGET_INSTALL_ROOT/bin/pip3" --version 2>&1)
if [ $? -ne 0 ] || [[ "$PIP_OUTPUT" != *"from $TARGET_INSTALL_ROOT/"* ]]
then
    echo "Packaged pip did not use the installed Python: $PIP_OUTPUT"
    exit 1
fi

exit 0
