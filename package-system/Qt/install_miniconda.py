#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import platform
import shutil
import subprocess
import sys
import urllib.request


# To build WebEngine for Qt, we need Python 2.7, so we need to do a temporary, local
# installation of miniconda (https://conda.io/projects/conda/en/latest/index.html) which
# will provide us a python 2.7 executable just for the Qt build process
miniconda_installer_links = {
    "windows": "https://repo.anaconda.com/miniconda/Miniconda2-py27_4.8.3-Windows-x86_64.exe",
    "linux": "https://repo.anaconda.com/miniconda/Miniconda2-py27_4.8.3-Linux-x86_64.sh",
    "darwin": "https://repo.anaconda.com/miniconda/Miniconda2-py27_4.8.3-MacOSX-x86_64.sh"
}

platform_system = platform.system().lower()

print("Attempting to install Miniconda (for Python 2.7)")

if not platform_system in miniconda_installer_links:
    print(f"Unknown platform: {platform_system}") 
    sys.exit(1)

installer_link = miniconda_installer_links[platform_system]
installer_file_name = os.path.basename(installer_link)

# Download the installer (if we haven't already, so that this script can be run iteratively)
if not os.path.exists(installer_file_name):
    print(f"Downloading Miniconda from {installer_link}")

    urllib.request.urlretrieve(installer_link, installer_file_name)

    print(f"Download of Miniconda complete => {os.path.abspath(installer_file_name)}")

# We will install miniconda into the local temp directory for our package
miniconda_install_dir = os.path.abspath(os.path.join('temp', 'miniconda'))
print(f"Installing Miniconda to {miniconda_install_dir}")

# Execute the installer in silent mode so it doesn't require any user
# interaction, and so that it doesn't modify any system PATH
exe_suffix = ""
if platform_system == "windows":
    exe_suffix = ".exe"
    result = subprocess.run(
        ["start",
         "/wait",
         installer_file_name,
         "/InstallationType=JustMe",
         "/RegisterPython=0",
         "/S",
         "/D=" + miniconda_install_dir
    ], shell=True)
else:
    result = subprocess.run(
        ["bash",
         installer_file_name,
         "-b",
         "-p",
         miniconda_install_dir
    ])

# Copy the python binary (python.exe/python) to python2 so that the Qt configure for WebEngine
# can find it easier
python_binary = os.path.join(miniconda_install_dir, 'python' + exe_suffix)
shutil.copyfile(python_binary, os.path.join(miniconda_install_dir, 'python2' + exe_suffix))

if result.returncode == 0:
    print("Miniconda successfully installed!")
else:
    print("Error installing Miniconda")
sys.exit(result.returncode)
