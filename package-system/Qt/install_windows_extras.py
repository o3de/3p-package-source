#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import urllib.request
import zipfile


# On Windows, we also need to install jom and ICU, so we will download them
# and install them locally just for this build
dependencies = {
    "jom": "http://download.qt.io/official_releases/jom/jom.zip",
    "icu": "https://github.com/unicode-org/icu/releases/download/release-65-1/icu4c-65_1-Win64-MSVC2017.zip"
}

for name in dependencies:
    print(f"Attempting to install {name}")

    installer_link = dependencies[name]
    file_name = os.path.basename(installer_link)

    # Download the zip (if we haven't already, so that this script can be run iteratively)
    if not os.path.exists(file_name):
        print(f"Downloading {name} from {installer_link}")

        urllib.request.urlretrieve(installer_link, file_name)

        print(f"Download of {name} complete => {os.path.abspath(file_name)}")

    # We will unzip the package into the local temp directory
    install_dir = os.path.abspath(os.path.join('temp', name))
    print(f"Installing {name} to {install_dir}")

    with zipfile.ZipFile(file_name, 'r') as dep_zip:
        dep_zip.extractall(install_dir)

    print(f"Successfully installed {name}") 
