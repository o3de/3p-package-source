#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this script is run on built python executables to make sure they function.

import sys

try:
    import tkinter
    import ssl
    import sqlite3
    import encodings
    import tarfile
    import lzma
except Exception as e:
    print("Failed: " + e)
    sys.exit(1)

print("Validated OK")
sys.exit(0)