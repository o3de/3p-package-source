#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import platform

from setuptools import setup, find_packages
from setuptools.command.develop import develop
from setuptools.command.build_py import build_py

PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

PYTHON_64 = platform.architecture()[0] == '64bit'


if __name__ == '__main__':
    if not PYTHON_64:
        raise RuntimeError("32-bit Python is not a supported platform.")

    with open(os.path.join(PROJECT_ROOT, 'README.md')) as f:
        long_description = f.read()

    setup(
        name="pyside2",
        version="5.12.4.2.3",
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

