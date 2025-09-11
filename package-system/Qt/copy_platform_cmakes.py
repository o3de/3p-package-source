#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import glob
import os
import pathlib
import platform
import shutil
import sys

print("Running copy_platform_cmakes.py")

# There are some additional cmake files we need to copy per-platform to the install directory
platform_system = platform.system().lower()
platform_to_pal = {
    "windows": "Windows",
    "linux": "Linux",
    "darwin": "Mac"
}

if platform_system not in platform_to_pal:
    print(f"Unknown platform: {platform_system}") 
    sys.exit(1)

platform_folder = pathlib.Path("Platform") / platform_to_pal[platform_system]
package_root = os.environ['PACKAGE_ROOT']
platform_install_folder = pathlib.Path(package_root) / platform_folder

# Make sure the install folder for the platform exists
platform_install_folder.mkdir(parents=True, exist_ok=True)

files = glob.iglob(os.path.join(platform_folder, "*.cmake"))
for file in files:
    print(f"Copying {file} => {platform_install_folder}")
    shutil.copy2(file, platform_install_folder)

# Install additional copyright notices to the package/qt root
package_qt_root = os.path.join(package_root, "qt")
additional_copyright_notices = ["QT-NOTICE.TXT",
                                "LICENSE"]
for file in additional_copyright_notices:
    if not os.path.isfile(file):
        print(f"Error: Cannot locate copyright notice file: {file}")
        sys.exit(1)
    print(f"Copying {file} => {package_qt_root}")
    shutil.copy2(file, package_qt_root)
