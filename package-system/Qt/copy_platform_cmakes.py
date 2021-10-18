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


# There are some additional cmake files we need to copy per-platform to the install directory
platform_system = platform.system().lower()
platform_to_pal = {
    "windows": "Windows",
    "linux": "Linux",
    "darwin": "Mac"
}

if not platform_system in platform_to_pal:
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
