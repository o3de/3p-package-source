#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
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
        self._customEnviron = os.environ.copy()

        if targetPlatform == 'android':
            if 'ANDROID_NDK_HOME' not in os.environ:
                raise RuntimeError('Unable to find the Android NDK. '
                    'Please set the ANDROID_NDK_HOME environment variable to the root of the Android NDK')
            ANDROID_NDK_HOME = os.environ["ANDROID_NDK_HOME"]
            print(f"ANDROID_NDK_HOME ='{ANDROID_NDK_HOME}'")

        if targetPlatform == 'mac':
            # set default env vars that control minos version.  Change this if you change the toolchain files.
            # ideally we'd put this in triplet files, but it turns out VCPKG triplets like the minos version
            # don't acutally work in the case where the target is built using existing makefiles instead of
            # CMake (ie, packages like OpenSSL1.1.1x)
            self._customEnviron["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
        elif targetPlatform == 'ios':
            self._customEnviron["IPHONEOS_DEPLOYMENT_TARGET"] = "14.0"

    @staticmethod
    def tripletForPlatform(platformName: str, static: bool):
        platformMap = {
            'mac': {
                True: 'x64-osx',
                False: 'x64-osx-dynamic',
            },
            'mac-arm64': {
                True: 'arm64-osx',
                False: 'arm64-osx-dynamic',
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
            },
            'wasm32': {
                True: 'wasm32-emscripten',
                False: 'wasm32-emscripten',
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

    @staticmethod
    def deleteFolder(folder):
        """
        Use the system's remove folder command instead of os.rmdir().
        This function does various checks before trying, to avoid having to do those
        checks over and over in code.
        """
        # wrap it up in a Path so that if a string is passed in, this still works.
        path_folder = pathlib.Path(folder).resolve(strict=False)
        if path_folder.is_file():
            raise Exception(f"deleteFolder: Expected a folder, but found a file: {path_folder}.  Continuing may be unsafe.")
        if not path_folder.is_dir():
            print(f'deleteFolder:  Folder is already not present: {path_folder}')
            return
        
        if platform.system() == 'Windows':
            call_result = subprocess.run(' '.join(['rmdir', '/Q', '/S', str(path_folder)]),
                                        shell=True,
                                        capture_output=True,
                                        cwd=str(path_folder.parent.resolve()))
        else:
            call_result = subprocess.run(' '.join(['rm', '-rf', str(path_folder)]),
                                        shell=True,
                                        capture_output=True,
                                        cwd=str(path_folder.parent.resolve()))
        if call_result.returncode != 0:
            raise Exception(f"deleteFolder: Unable to delete folder {str(path_folder)}: {str(call_result.stderr.decode())}")

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
                ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', 'scripts/bootstrap.ps1', '-disableMetrics'],
                cwd=self.vcpkgDir,
            )
        else:
            subprocess.check_call(
                [self.vcpkgDir / 'bootstrap-vcpkg.sh', '-disableMetrics'],
                cwd=self.vcpkgDir,
            )

    def patch(self, patchFile: pathlib.Path):
        subprocess.check_output(
            ['git', 'apply', '--whitespace=fix', '--verbose',  str(patchFile)],
            cwd=self.vcpkgDir,
        )

    def build(self, allow_unsupported=False):
        self.remove()

        command = [
            str(self.vcpkgDir / 'vcpkg'),
            'install',
            f'{self.portName}:{self.triplet}',
            '--no-binarycaching',
            f'--overlay-triplets={self.customTripletsDir}'
        ]

        if allow_unsupported:
            command.append('--allow-unsupported')

        subprocess.check_call(
            command,
            cwd=self.vcpkgDir, 
            env=self._customEnviron
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

    def writeCMakeFindFile(self, packageDir: pathlib.Path, template, templateEnv:dict, overwrite_find_file:str or None):
        cmakeFindFile = packageDir / f'Find{overwrite_find_file or self.packageName}.cmake'
        cmakeFindFile.write_text(string.Template(template).substitute(templateEnv))

