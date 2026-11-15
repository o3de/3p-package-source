#!/bin/bash

# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT

set -euo pipefail

for binary in "$TARGET_INSTALL_ROOT/Python.framework/Versions/3.15/Python" \
    "$TARGET_INSTALL_ROOT/Python.framework/Versions/3.15/bin/python3.15" \
    "$TARGET_INSTALL_ROOT/Python.framework/Versions/3.15/Resources/Python.app/Contents/MacOS/Python" \
    "$TARGET_INSTALL_ROOT"/Python.framework/Versions/3.15/lib/python3.15/lib-dynload/*.so; do
    dsym="$TARGET_INSTALL_ROOT/symbols/${binary#"$TARGET_INSTALL_ROOT"/}.dSYM"
    dwarfdump --verify "$dsym"
    dwarfdump --debug-info --recurse-depth=0 "$dsym" | grep DW_TAG_compile_unit > /dev/null
    diff <(dwarfdump --uuid "$binary" | awk '{print $2, $3}' | sort) \
         <(dwarfdump --uuid "$dsym" | awk '{print $2, $3}' | sort)
done

"$TARGET_INSTALL_ROOT/Python.framework/Versions/3.15/bin/python3" "$(dirname "$0")/../quick_validate_python.py"
