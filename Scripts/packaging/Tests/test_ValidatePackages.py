#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

from common import CommonUtils
import tempfile
import os
import tarfile
import pytest

def test_FullyValidatePackage_nonexistent_returns_false():
    assert not CommonUtils.FullyValidatePackage("nonexistent", "none")

def test_commonutils_ComputeHashOfFile_nonexistent_file_errors():
    with pytest.raises(FileNotFoundError):
        CommonUtils.ComputeHashOfFile("nothing")

def test_FullyValidatePackage_foldereExists_no_package_returns_false():
    with tempfile.TemporaryDirectory() as dir:
        assert not CommonUtils.FullyValidatePackage(dir, "emptypackage")

def test_FullyValidatePackage_package_empty_returns_false():
    with tempfile.TemporaryDirectory() as dir:
        with tarfile.open(os.path.join(dir, 'emptypackage' + CommonUtils.package_extension), mode="w:xz"):
            pass
        assert not CommonUtils.FullyValidatePackage(dir, "emptypackage") 
    
def test_FullyValidatePackage_package_corrupt_returns_false():
    with tempfile.TemporaryDirectory() as dir:
        with open(os.path.join(dir, 'mypackage' + CommonUtils.package_extension), mode="wt", encoding='utf-8'):
            pass
        assert not CommonUtils.FullyValidatePackage(dir, "mypackage") 
    
package_descriptor_template = '''
{
    "PackageName" : "zlib-1.2.8-linux",
    "URL"         : "https://zlib.net",
    "License"     : "zlib",
    "LicenseFile" : "zlib/LICENSE" 
}
'''

def test_FullyValidatePackage_package_descriptor_only_returns_false():
    with tempfile.TemporaryDirectory() as dir:
        with open(os.path.join(dir, CommonUtils.package_descriptor_name), 'w', encoding='utf-8') as pd:
            pd.write(package_descriptor_template)
        with tarfile.open(os.path.join(dir, 'mypackage' + CommonUtils.package_extension), mode='w:xz') as tf:
            tf.add(os.path.join(dir, CommonUtils.package_descriptor_name))
        assert not CommonUtils.FullyValidatePackage(dir, "mypackage")

def test_FullyValidatePackage_bogus_required_parts_returns_false():
    with tempfile.TemporaryDirectory() as dir:
        bogus_files = [
            (os.path.join(dir, CommonUtils.package_descriptor_name), "Bogus content"),
            (os.path.join(dir, CommonUtils.package_root_hash_file_name), "Bogus content")
        ]
        
        with tarfile.open(os.path.join(dir, 'mypackage' + CommonUtils.package_extension), mode='w:xz') as tf:
            for element in bogus_files:
                with open(element[0], 'w', encoding='utf-8') as pd:
                    pd.write(element[1])
                tf.add(element[0])
        assert not CommonUtils.FullyValidatePackage(dir, "mypackage")

@pytest.mark.parametrize("folderName,expectedResult", [
        # the tuple is (folder name, expected outcome of FullyValidatePackage)
        ("extra_content_file", False), # package contains an unexpected file
        ("missing_content_file", False), # descriptor is missing a required field
        ("missing_content_hash", False), # a file inside the package does not match
        ("missing_license_file", False), # package has a bad path to license file
        ("minimal_good", True), # package is good and has absolute bare minimum
        ("normal_package", True), # package is completely normal
        ("package_symlink", True), # package has symlinks in it
        ("invalid_spdx_license", False), # package is correct in every way but invalid license name
        ("custom_license", True), # package is correct in every way but has 'custom' as license
    ])
def test_package_contents(folderName, expectedResult):
    script_dir = os.path.dirname(os.path.realpath(__file__))

    package_folder = os.path.join(script_dir, 'test_packages', folderName)
    assert CommonUtils.FullyValidatePackage(package_folder, 'package') == expectedResult
