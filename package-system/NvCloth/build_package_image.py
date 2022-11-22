#!/usr/bin/env python3
#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import functools
import json
import os
import re
import pathlib
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup

class NvClothBuilder(object):
    def __init__(self, workingDir: pathlib.Path, basePackageSystemDir: pathlib.Path, targetPlatform: str):
        self._workingDir = workingDir
        self._packageSystemDir = basePackageSystemDir
        self._platform = targetPlatform
        self._env = dict(os.environ)
        self._env.update(
            GW_DEPS_ROOT=str(workingDir),
        )

        self.check_call = functools.partial(subprocess.check_call,
            cwd=self.workingDir,
            env=self.env
        )

    @property
    def workingDir(self):
        return self._workingDir

    @property
    def packageSystemDir(self):
        return self._packageSystemDir

    @property
    def platform(self):
        return self._platform

    @property
    def env(self):
        return self._env

    def clone(self, lockToCommit: str):
        if not (self.workingDir / '.git').exists():
            self.check_call(
                ['git', 'init',],
            )
            self.check_call(
                ['git', 'remote', 'add', 'origin', 'https://github.com/NVIDIAGameWorks/NvCloth.git',],
            )

        self.check_call(
            ['git', 'fetch', 'origin', '--depth=1', 'pull/58/head:pr-58',],
        )
        self.check_call(
            ['git', 'checkout', 'pr-58',],
        )
        
        # Remove /LTCG and /GL flags as it's causing compile warnings
        if self.platform == 'windows':
            windows_cmake_file = self.workingDir / 'NvCloth/compiler/cmake/windows/CMakeLists.txt'
            f = open(windows_cmake_file, 'r')
            content = f.read()
            f.close()
            content = re.sub('/LTCG', r'', content, flags = re.M)
            content = re.sub('/GL', r'', content, flags = re.M)
            f = open(windows_cmake_file, 'w')
            f.write(content)
            f.close()
        
        # Remove warnings as errors for iOS
        if self.platform == 'ios':
            ios_cmake_file = self.workingDir / 'NvCloth/compiler/cmake/ios/CMakeLists.txt'
            f = open(ios_cmake_file, 'r')
            content = f.read()
            f.close()
            content = re.sub('-Werror', r'', content, flags = re.M)
            f = open(ios_cmake_file, 'w')
            f.write(content)
            f.close()

    def build(self):
        cmake_scripts_path = os.path.abspath(os.path.join(self.packageSystemDir, '../Scripts/cmake'))
        nvcloth_dir = self.workingDir / 'NvCloth'
        
        ly_3rdparty_path = os.getenv('LY_3RDPARTY_PATH')

        folder_names = { 
            #system-name  cmake generation, cmake build
            'mac'       : ([
                '-G', 'Xcode',
                '-DTARGET_BUILD_PLATFORM=mac',
                '-DNV_CLOTH_ENABLE_CUDA=0', '-DUSE_CUDA=0',
                '-DPX_GENERATE_GPU_PROJECTS=0',
                '-DPX_STATIC_LIBRARIES=1',
                f'-DPX_OUTPUT_DLL_DIR={nvcloth_dir}/bin/osx64-cmake',
                f'-DPX_OUTPUT_LIB_DIR={nvcloth_dir}/lib/osx64-cmake',
                f'-DPX_OUTPUT_EXE_DIR={nvcloth_dir}/bin/osx64-cmake'
            ], []),
            'ios'       : ([
                '-G', 'Xcode',
                f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/iOS/Toolchain_ios.cmake',
                '-DPACKAGE_PLATFORM=ios',
                '-DTARGET_BUILD_PLATFORM=ios',
                '-DCMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET="10.0"',
                '-DNV_CLOTH_ENABLE_CUDA=0', '-DUSE_CUDA=0',
                '-DPX_GENERATE_GPU_PROJECTS=0',
                '-DPX_STATIC_LIBRARIES=1',
                f'-DPX_OUTPUT_DLL_DIR={nvcloth_dir}/bin/ios-cmake',
                f'-DPX_OUTPUT_LIB_DIR={nvcloth_dir}/lib/ios-cmake',
                f'-DPX_OUTPUT_EXE_DIR={nvcloth_dir}/bin/ios-cmake'
            ], [
                '--',
                '-destination generic/platform=iOS'
            ]),
            'linux'     : ([
                '-G', 'Ninja Multi-Config',
                '-DCMAKE_C_COMPILER=clang-6.0', 
                '-DCMAKE_CXX_COMPILER=clang++-6.0',
                '-DTARGET_BUILD_PLATFORM=linux',
                '-DNV_CLOTH_ENABLE_CUDA=0',
                '-DPX_GENERATE_GPU_PROJECTS=0',
                '-DPX_STATIC_LIBRARIES=1',
                f'-DPX_OUTPUT_DLL_DIR={nvcloth_dir}/bin/linux64-cmake',
                f'-DPX_OUTPUT_LIB_DIR={nvcloth_dir}/lib/linux64-cmake',
                f'-DPX_OUTPUT_EXE_DIR={nvcloth_dir}/bin/linux64-cmake'
            ], []),
            'windows'   : ([
                '-G', 'Visual Studio 15 2017',
                '-Ax64',
                '-DTARGET_BUILD_PLATFORM=windows',
                '-DNV_CLOTH_ENABLE_DX11=0',
                '-DNV_CLOTH_ENABLE_CUDA=0',
                '-DPX_GENERATE_GPU_PROJECTS=0',
                '-DSTATIC_WINCRT=0',
                '-DPX_STATIC_LIBRARIES=1',
                f'-DPX_OUTPUT_DLL_DIR={nvcloth_dir}/bin/vc141win64-cmake',
                f'-DPX_OUTPUT_LIB_DIR={nvcloth_dir}/lib/vc141win64-cmake',
                f'-DPX_OUTPUT_EXE_DIR={nvcloth_dir}/bin/vc141win64-cmake'
            ], []),
            'android'   : ([
                '-G', 'Ninja Multi-Config',
                f'-DCMAKE_TOOLCHAIN_FILE={cmake_scripts_path}/Platform/Android/Toolchain_android.cmake',
                '-DANDROID_ABI=arm64-v8a',
                '-DANDROID_ARM_MODE=arm',
                '-DANDROID_ARM_NEON=TRUE',
                '-DANDROID_NATIVE_API_LEVEL=21',
                f'-DLY_NDK_DIR={ly_3rdparty_path}/android-ndk/r21d',
                '-DPACKAGE_PLATFORM=android',
                '-DPX_STATIC_LIBRARIES=1',
                f'-DPX_OUTPUT_DLL_DIR={nvcloth_dir}/bin/android-arm64-v8a-cmake',
                f'-DPX_OUTPUT_LIB_DIR={nvcloth_dir}/lib/android-arm64-v8a-cmake',
                f'-DPX_OUTPUT_EXE_DIR={nvcloth_dir}/bin/android-arm64-v8a-cmake'
            ], []) # Android needs to have ninja in the path
        }
        
        # intentionally generate a keyerror if its not a good platform:
        cmake_generation, cmake_build = folder_names[self.platform]
        
        build_dir = os.path.join(nvcloth_dir, 'build', self.platform)
        os.makedirs(build_dir, exist_ok=True)
        
        # Generate
        cmake_generate_call =['cmake', f'{nvcloth_dir}/compiler/cmake/{self.platform}', f'-B{build_dir}']
        if cmake_generation:
            cmake_generate_call += cmake_generation
        print(cmake_generate_call)
        self.check_call(cmake_generate_call)

        # Build
        for config in ('debug', 'profile', 'release'):
            cmake_build_call =['cmake', '--build', build_dir, '--config', config]
            if cmake_build:
                cmake_build_call += cmake_build
            print(cmake_build_call)
            self.check_call(cmake_build_call)

    def copyBuildOutputTo(self, packageDir: pathlib.Path):
        if packageDir.exists():
            shutil.rmtree(packageDir)
    
        for dirname in ('NvCloth/lib', 'NvCloth/include', 'NvCloth/extensions/include', 'PxShared/include'):
            shutil.copytree(
                src=self.workingDir / dirname,
                dst=packageDir / dirname,
                symlinks=True,
            )
        shutil.copy2(
            src=self.workingDir / 'README.md',
            dst=packageDir / 'README.md',
        )
        shutil.copy2(
            src=self.workingDir / 'NvCloth/license.txt',
            dst=packageDir / 'NvCloth/license.txt',
        )
        shutil.copy2(
            src=self.workingDir / 'PxShared/license.txt',
            dst=packageDir / 'PxShared/license.txt',
        )

    def writePackageInfoFile(self, packageDir: pathlib.Path, settings: dict):
        with (packageDir / 'PackageInfo.json').open('w') as fh:
            json.dump(settings, fh, indent=4)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'linux', 'linux-aarch64', 'android', 'mac', 'ios'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()
    vcpkg_platform_map = {
            'windows': 'windows',
            'android': 'android',
            'mac': 'mac',
            'ios': 'ios',
            'linux': 'linux',
            'linux-aarch64': 'linux' }

    vcpkg_platform = vcpkg_platform_map[args.platformName]
    if args.platformName == 'linux-aarch64':
        os.environ['VCPKG_FORCE_SYSTEM_BINARIES'] = '1'

    packageSystemDir = Path(__file__).resolve().parents[1]
    packageSourceDir = packageSystemDir / 'NvCloth'
    packageRoot = packageSystemDir / f'NvCloth-{args.platformName}'

    cmakeFindFile = packageSourceDir / f'FindNvCloth_{vcpkg_platform}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'FindNvCloth.cmake'

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        builder = NvClothBuilder(workingDir=tempdir, basePackageSystemDir=packageSystemDir, targetPlatform=vcpkg_platform)
        builder.clone('8e100cca5888d09f40f4721cc433f284b1841e65')
        builder.build()
        builder.copyBuildOutputTo(packageRoot/'NvCloth')
        
        # Version v1.1.6-4-gd243404-pr58 describes commit 8e100cc,
        # which is 4 commits above 1.1.6 release (commit d243404),
        # plus pull request 58 applied on top.
        builder.writePackageInfoFile(
            packageRoot,
            settings={
                'PackageName': f'NvCloth-v1.1.6-4-gd243404-pr58-rev1-{args.platformName}',
                'URL': 'https://github.com/NVIDIAGameWorks/NvCloth.git',
                'License': 'custom',
                'LicenseFile': 'NvCloth/NvCloth/license.txt',
            },
        )
        
        shutil.copy2(
            src=cmakeFindFile,
            dst=packageRoot / 'FindNvCloth.cmake'
        )

if __name__ == '__main__':
    main()
