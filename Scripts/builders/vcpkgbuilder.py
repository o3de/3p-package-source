#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project
# 
#  SPDX-License-Identifier: Apache-2.0 OR MIT
#

"""
Package builder for vcpkg-based packages
"""

from pathlib import Path
import errno
import json
import os
import pathlib
import shutil
import string
import subprocess
import platform

class VcpkgBuilder(object):
    def __init__(self, packageName: str, portName: str, vcpkgDir: pathlib.Path, targetPlatform: str, static: bool):
        self._packageName = packageName
        self._portName = portName
        self._vcpkgDir = vcpkgDir
        self._triplet = VcpkgBuilder.tripletForPlatform(targetPlatform, static)
        self._customTripletsDir = Path(__file__).resolve().parents[1] / 'vcpkg/triplets'

        if targetPlatform == 'android' and 'ANDROID_NDK_HOME' not in os.environ:
            # Copy some of the logic from vcpkg's android ndk detection, and see if we can print a warning early
            if 'ProgramData' in os.environ:
                androidNdkFound = (pathlib.Path(os.environ['ProgramData']) / 'Microsoft/AndroidNDK64/android-ndk-r13b/').exists()
            else:
                androidNdkFound = False
            if not androidNdkFound and 'ProgramFiles(x86)' in os.environ:
                # Use Xamarin default installation folder
                androidNdkFound = (pathlib.Path(os.environ['ProgramFiles(x86)']) / 'Android/android-sdk/ndk-bundle').exists()

            if not androidNdkFound:
                raise RuntimeError('Unable to find the Android NDK. '
                    'Please set the ANDROID_NDK_HOME environment variable to the root of the Android NDK')

    @staticmethod
    def tripletForPlatform(platformName: str, static: bool):
        platformMap = {
            'mac': {
                True: 'x64-osx',
                False: 'x64-osx-dynamic',
            },
            'windows': {
                True: 'x64-windows-static',
                False: 'x64-windows',
            },
            'linux': {
                True: 'x64-linux',
                False: 'x64-linux-shared',
            },
            'android': {
                True: 'arm64-android-static', # arm64-v8a
                False: 'arm64-android', # arm64-v8a
            },
            'ios': {
                True: 'arm64-ios',
                False: 'arm64-ios-dynamic',
            }
        }
        try:
            useStaticLibsMap = platformMap[platformName]
        except KeyError:
            raise RuntimeError(f'Platform {platformName} not supported')

        try:
            return useStaticLibsMap[static]
        except KeyError:
            raise RuntimeError('Platform {platformName} does not support building {linkageType} libraries'.format(
                platformName=platformName,
                linkageType='static' if static else 'dynamic',
            ))

    @staticmethod
    def defaultPackagePlatformName():
        platformMap = {
            'Darwin': 'mac',
            'Windows': 'windows',
            'Linux': 'linux',
        }
        return platformMap[platform.system()]

    @property
    def customTripletsDir(self):
        return self._customTripletsDir

    @property
    def packageName(self):
        """The name of the package that this builder will build"""
        return self._packageName

    @property
    def portName(self):
        """The name of the vcpkg port that this builder will build"""
        return self._portName

    @property
    def vcpkgDir(self):
        """The directory where vcpkg will be cloned to"""
        return self._vcpkgDir

    @property
    def triplet(self):
        """The vcpkg triplet to build"""
        return self._triplet

    def cloneVcpkg(self, lockToCommit: str):
        if not (self.vcpkgDir / '.git').exists():
            subprocess.check_call(
                ['git', 'init',],
                cwd=self.vcpkgDir,
            )
            subprocess.check_call(
                ['git', 'remote', 'add', 'origin', 'https://github.com/microsoft/vcpkg.git',],
                cwd=self.vcpkgDir,
            )

        subprocess.check_call(
            ['git', 'fetch', 'origin', '--depth=1', lockToCommit,],
            cwd=self.vcpkgDir,
        )
        subprocess.check_call(
            ['git', 'checkout', lockToCommit,],
            cwd=self.vcpkgDir,
        )

    def bootstrap(self):
        if platform.system() == 'Windows':
            subprocess.check_call(
                ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', 'scripts/bootstrap.ps1',],
                cwd=self.vcpkgDir,
            )
        else:
            subprocess.check_call(
                [self.vcpkgDir / 'bootstrap-vcpkg.sh'],
                cwd=self.vcpkgDir,
            )

    def patch(self, patchFile: pathlib.Path):
        subprocess.check_output(
            ['git', 'apply', '--whitespace=fix', str(patchFile)],
            cwd=self.vcpkgDir,
        )

    def build(self):
        self.remove()

        subprocess.check_call(
            [str(self.vcpkgDir / 'vcpkg'), 'install', f'{self.portName}:{self.triplet}', '--no-binarycaching', f'--overlay-triplets={self.customTripletsDir}'],
            cwd=self.vcpkgDir,
        )

    def remove(self):
        subprocess.check_call(
            [str(self.vcpkgDir / 'vcpkg'), 'remove', f'{self.portName}:{self.triplet}', f'--overlay-triplets={self.customTripletsDir}'],
            cwd=self.vcpkgDir,
        )


    def copyBuildOutputTo(self, packageDir: pathlib.Path, extraFiles: dict, subdir:pathlib.Path=None):
        destdir = packageDir / self.packageName
        if subdir is not None:
            destdir /= subdir
        if destdir.exists():
            shutil.rmtree(destdir)
        shutil.copytree(
            src=self.vcpkgDir / 'packages' / f'{self.portName}_{self.triplet}',
            dst=destdir,
            symlinks=True,
        )

        for (src, dst) in extraFiles.items():
            try:
                shutil.copy2(src, dst)
            except IOError as e:
                # ENOENT(2): file does not exist, raised also on missing dest parent dir
                if e.errno != errno.ENOENT:
                    raise
                # try creating parent directories
                Path(dst).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)

    def writePackageInfoFile(self, packageDir: pathlib.Path, settings: dict):
        with (packageDir / 'PackageInfo.json').open('w') as fh:
            json.dump(settings, fh, indent=4)

    def writeCMakeFindFile(self, packageDir: pathlib.Path, template, templateEnv:dict):
        cmakeFindFile = packageDir / f'Find{self.packageName}.cmake'
        cmakeFindFile.write_text(string.Template(template).substitute(templateEnv))

