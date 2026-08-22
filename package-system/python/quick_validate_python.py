#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this script is run on built python executables to make sure they function.

print("Python validation started")

import sys
import sysconfig

try:
    import tkinter
    import ssl
    import sqlite3
    import encodings
    import tarfile
    import lzma
    import bz2
    import compression.zstd
    import ensurepip
    import pip
    import venv
except Exception as e:
    print("Failed: " + str(e))
    sys.exit(1)

if sys.version_info[:3] != (3, 14, 7):
    print(f"Failed: expected Python 3.14.7, got {sys.version}")
    sys.exit(1)

if sysconfig.get_config_var("Py_GIL_DISABLED"):
    print("Failed: O3DE requires the standard GIL-enabled CPython build")
    sys.exit(1)

print(f"Validated {sys.version}")
print(f"SOABI: {sysconfig.get_config_var('SOABI')}")

print("Validated OK")
sys.exit(0)
