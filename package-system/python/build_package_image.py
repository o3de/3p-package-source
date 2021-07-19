#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this script builds python for linux and darwin_x64
# and places the result in linux_x64/package or darwin_x64/package 
import subprocess
import sys
import os
import platform

folder_names = { #   subfolder     interpreter     build script 
    'darwin'     : ('darwin_x64' , 'Python.framework/Versions/3.7/bin/python3', 'make-python.sh'),
    'linux'      : ('linux_x64'  , 'python/bin/python', 'make-python.sh'),
    'windows'    : ('win_x64'    , 'python/python.exe', 'build_python.bat')
}

platformsys = platform.system().lower()

# intentionally generate a keyerror if its not a good platform:
subfolder_name, binary_relpath, build_script = folder_names[platformsys]

script_dir = os.path.dirname(os.path.realpath(__file__))
build_script_dir = os.path.join(script_dir, subfolder_name)
test_script_name = os.path.join(script_dir, 'quick_validate_python.py')
build_script_name = os.path.join(build_script_dir, build_script)

# the built python is expected to be in build script dir/package/...
python_dir = os.path.join(build_script_dir, 'package' )
python_executable = os.path.join(python_dir, binary_relpath)

# build python using the build script
result_value = subprocess.run([build_script_name], shell=True, cwd=build_script_dir)

if result_value.returncode != 0:
    sys.exit(result_value.returncode)

# test out the freshly created python executable:
result_value = subprocess.run([python_executable, test_script_name], cwd=python_dir)
sys.exit(result_value.returncode)
