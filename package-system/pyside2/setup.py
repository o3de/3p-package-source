#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import platform
import pathlib
import sys

from setuptools import setup, find_packages
from setuptools.command.develop import develop
from setuptools.command.build_py import build_py

if sys.platform == 'win32':
    # The library folder structure of windows omits the extra 'python3.10' folder level for the site-packages, so we have to
    # adjust to where to read the project root based on this file
    PROJECT_ROOT = pathlib.Path(os.path.dirname(__file__)).parent.parent
else:
    PROJECT_ROOT = pathlib.Path(os.path.dirname(__file__)).parent.parent.parent



README_FILE = PROJECT_ROOT / 'README.md'

PYTHON_64 = platform.architecture()[0] == '64bit'


if __name__ == '__main__':
    if not PYTHON_64:
        raise RuntimeError("32-bit Python is not a supported platform.")

    with README_FILE.open() as f:
        long_description = f.read()

    setup(
        name="pyside2",
        version="5.15.2.1",
        description='Pyside2',
        long_description=long_description,
        packages=['PySide2', 'shiboken2'],
        install_requires=[
        ],
        tests_require=[
        ],
        entry_points={
        },
    )

