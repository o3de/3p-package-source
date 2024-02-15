#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this script is run on built python executables to make sure they function.

print("Simple import validation started")

import sys

try:
    print("import tkinter")
    import tkinter
    print("import ssl")
    import ssl
    print("import sqlite3")
    import sqlite3
    print("import encodings")
    import encodings
    print("import tarfile")
    import tarfile
    print("import lzma")
    import lzma
    print("import bz2")
    import bz2
except Exception as e:
    print("Failed: " + e)
    sys.exit(1)

print("Validated OK")
sys.exit(0)