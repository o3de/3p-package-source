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
import builders.monkeypatch_tempdir_cleanup

class PhysXBuilder(object):
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
        
        # nVidia CMakeModules (downloaded while building PhysX) do not cover ios or android
        # bin folder names yet, so they appear as UNKNOWN.
        self.platform_params = { 
            # system-name   : (build preset, bin folder name, install folder name, is multiconfig)
            'windows'       : ('vc16win64', 'win.x86_64.vc142.md', 'vc16win64', True),
            'linux'         : ('linux', 'linux.clang', 'linux', False),
            'linux-aarch64' : ('linux-aarch64', 'linux.aarch64', 'linux-aarch64', False),
            'mac'           : ('mac64', 'mac.x86_64', 'mac64', True),
            'ios'           : ('ios64', 'UNKNOWN', 'ios64', True),
            'android'       : ('android-arm64-v8a', 'UNKNOWN', "android-29", False)
        }

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

    def readFile(self, file):
        f = open(file, 'r')
        content = f.read()
        f.close()
        return content

    def writeFile(self, file, content):
        f = open(file, 'w')
        f.write(content)
        f.close()

    def clone(self, lockToCommit: str):
        if not (self.workingDir / '.git').exists():
            self.check_call(
                ['git', 'init',],
            )
            self.check_call(
                ['git', 'remote', 'add', 'origin', 'https://github.com/NVIDIA-Omniverse/PhysX',],
            )

        self.check_call(
            ['git', 'fetch', 'origin', '--update-head-ok', '--depth=1', lockToCommit,],
        )
        self.check_call(
            ['git', 'checkout', lockToCommit,],
        )
            
    def preparePreset(self, buildAsStaticLibs, config):
        preset_index = 0
        preset_file = self.workingDir / 'physx' / 'buildtools' / 'presets' / 'public' / f'{self.platform_params[self.platform][preset_index]}.xml'
        content = self.readFile(preset_file)
        content = re.sub('name="PX_GENERATE_STATIC_LIBRARIES" value="(True|False)"', f'name="PX_GENERATE_STATIC_LIBRARIES" value="{buildAsStaticLibs}"', content, flags = re.M)
        
        if self.platform == 'windows':
            content = re.sub('name="PX_BUILDSNIPPETS" value="(True|False)"', f'name="PX_BUILDSNIPPETS" value="False"', content, flags = re.M)
            content = re.sub('name="PX_BUILDPVDRUNTIME" value="(True|False)"', f'name="PX_BUILDPVDRUNTIME" value="False"', content, flags = re.M)
            if config == 'debug':
                content = re.sub('name="NV_USE_DEBUG_WINCRT" value="(True|False)"', f'name="NV_USE_DEBUG_WINCRT" value="True"', content, flags = re.M)
            else:
                content = re.sub('name="NV_USE_DEBUG_WINCRT" value="(True|False)"', f'name="NV_USE_DEBUG_WINCRT" value="False"', content, flags = re.M)
            content = re.sub('name="NV_USE_STATIC_WINCRT" value="(True|False)"', f'name="NV_USE_STATIC_WINCRT" value="False"', content, flags = re.M) # sets dynamic runtime usage
            
        elif self.platform == 'linux' or self.platform == 'linux-aarch64':
            content = re.sub('name="PX_BUILDSNIPPETS" value="(True|False)"', f'name="PX_BUILDSNIPPETS" value="False"', content, flags = re.M)
            content = re.sub('name="PX_BUILDPVDRUNTIME" value="(True|False)"', f'name="PX_BUILDPVDRUNTIME" value="False"', content, flags = re.M)
            
        self.writeFile(preset_file, content)

        # Ignore poison-system-directories warning when building mac/ios caused 
        # by running 'cmake --build' using python subprocess on Mac.
        if self.platform == 'mac' or self.platform == 'ios':
            cmake_file = self.workingDir / 'physx' / 'source' / 'compiler' / 'cmake' / self.platform / 'CMakeLists.txt'
            content = self.readFile(cmake_file)
            content = re.sub('-Werror', r'-Werror -Wno-poison-system-directories', content, flags = re.M)
            self.writeFile(cmake_file, content)
        
    def cleanUpLibs(self, buildAsStaticLibs):
        static_bin_dir = self.workingDir / 'physx' / 'bin' / 'static'
        shared_bin_dir = self.workingDir / 'physx' / 'bin' / 'shared'
    
        # Remove dynamic libraries repeated in static folders to save space.
        # Also freeglut is not necessary for PhysX.
        if self.platform == 'windows':
            if buildAsStaticLibs:
                for config in ('release', 'profile', 'checked', 'debug'):
                    os.remove(static_bin_dir / config / 'PhysXDevice64.dll')
                    os.remove(static_bin_dir / config / 'PhysXGpu_64.dll')
                    if config == 'debug':
                        os.remove(static_bin_dir / config / 'freeglutd.dll')
                    else:
                        os.remove(static_bin_dir / config / 'freeglut.dll')
            else:
                for config in ('release', 'profile', 'checked', 'debug'):
                    if config == 'debug':
                        os.remove(shared_bin_dir / config / 'freeglutd.dll')
                    else:
                        os.remove(shared_bin_dir / config / 'freeglut.dll')
            
        elif self.platform == 'linux' or self.platform == 'linux-aarch64':
            if buildAsStaticLibs:
                for config in ('release', 'profile', 'checked', 'debug'):
                    os.remove(static_bin_dir / config / 'libPhysXGpu_64.so')
            
    def build(self, buildAsStaticLibs):
        physx_dir = self.workingDir / 'physx'
        
        preset, bin_folder, install_folder, is_multiconfig = self.platform_params[self.platform]
        
        if self.platform == 'windows' or self.platform == 'android':
            generate_projects_cmd =  str(physx_dir / 'generate_projects.bat')
        else:
            generate_projects_cmd = str(physx_dir / 'generate_projects.sh')
            
        check_call_physx_dir = functools.partial(subprocess.check_call,
            cwd=physx_dir, # generate_projects script will fail if not called from physx directory
            env=self.env
        )
        
        for config in ('release', 'profile', 'checked', 'debug'):
            self.preparePreset(buildAsStaticLibs, config);
            
            # Generate
            generate_call =[generate_projects_cmd, preset,]
            print(generate_call)
            check_call_physx_dir(generate_call)

            # Build
            if is_multiconfig:
                build_dir = os.path.join(physx_dir, 'compiler', preset)
                if config == 'release':
                    # Build install target on release to produce the install folder where all the headers will be generated
                    cmake_build_call =['cmake', '--build', build_dir, '--config', config, '--target', 'install']
                else:
                    cmake_build_call =['cmake', '--build', build_dir, '--config', config]
            else:
                build_dir = os.path.join(physx_dir, 'compiler', f'{preset}-{config}')
                if config == 'release':
                    # Build install target on release to produce the install folder where all the headers will be generated
                    cmake_build_call =['cmake', '--build', build_dir, '--target', 'install']
                else:
                    cmake_build_call =['cmake', '--build', build_dir]
            print(cmake_build_call)
            self.check_call(cmake_build_call)
                
        # Delete bin inside install folder if exists (we'll copy them later in copyBuildOutputTo)
        bin_install_folder = physx_dir / 'install' / install_folder / 'PhysX' / 'bin'
        if bin_install_folder.exists():
            shutil.rmtree(bin_install_folder)
        
        # Rename bin output folder to static/shared, avoiding the platform name in bin folder makes the FindPhysX.cmake simpler.
        if buildAsStaticLibs:
            shutil.move(physx_dir / 'bin' / bin_folder, physx_dir / 'bin' / 'static')
            shutil.move(physx_dir / 'install' / install_folder, physx_dir / 'install' / 'static')
        else:
            shutil.move(physx_dir / 'bin' / bin_folder, physx_dir / 'bin' / 'shared')
            shutil.move(physx_dir / 'install' / install_folder, physx_dir / 'install' / 'shared')
             
        self.cleanUpLibs(buildAsStaticLibs)

    def copyBuildOutputTo(self, packageDir: pathlib.Path):
        if packageDir.exists():
            shutil.rmtree(packageDir)
            
        shutil.copytree(
            src=self.workingDir / 'physx' / 'install' / 'shared' / 'PhysX',
            dst=packageDir / 'physx',
            symlinks=True,
        )
        shutil.copytree(
            src=self.workingDir / 'physx' / 'bin' / 'shared',
            dst=packageDir / 'physx' / 'bin' / 'shared',
            symlinks=True,
        )
        shutil.copytree(
            src=self.workingDir / 'physx' / 'bin' / 'static',
            dst=packageDir / 'physx' / 'bin' / 'static',
            symlinks=True,
        )
        shutil.copy2(
            src=self.workingDir / 'README.md',
            dst=packageDir / 'README.md',
        )
        shutil.copy2(
            src=self.workingDir / 'LICENSE.md',
            dst=packageDir / 'LICENSE.md',
        )
        shutil.copy2(
            src=self.workingDir / 'physx' / 'README.md',
            dst=packageDir / 'physx' / 'README.md',
        )
        shutil.copy2(
            src=self.workingDir / 'physx' / 'version.txt',
            dst=packageDir / 'physx' / 'version.txt',
        )

    def writePackageInfoFile(self, packageDir: pathlib.Path, settings: dict):
        with (packageDir / 'PackageInfo.json').open('w') as fh:
            json.dump(settings, fh, indent=4)

    def writeCMakeFindFile(self, packageDir: pathlib.Path, cmakeFindFile):
        dst = packageDir / 'FindPhysX.cmake'
        shutil.copy2(
            src=cmakeFindFile,
            dst=dst
        )
        
        extraLibsPerPlatform = {
            'windows': [
                ['\${EXTRA_SHARED_LIBS}',
                 ''.join(('\n',
                    '\t${PATH_TO_SHARED_LIBS}/PhysXDevice64.dll\n',
                    '\t${PATH_TO_SHARED_LIBS}/PhysXGpu_64.dll\n'
                ))],
                ['\${EXTRA_STATIC_LIBS_NON_MONOLITHIC}',
                 ''.join(('\n',
                    '\t${PATH_TO_LIBS}/LowLevel_static_64.lib\n',
                    '\t${PATH_TO_LIBS}/LowLevelAABB_static_64.lib\n',
                    '\t${PATH_TO_LIBS}/LowLevelDynamics_static_64.lib\n',
                    '\t${PATH_TO_LIBS}/PhysXTask_static_64.lib\n',
                    '\t${PATH_TO_LIBS}/SceneQuery_static_64.lib\n',
                    '\t${PATH_TO_LIBS}/SimulationController_static_64.lib\n',
                ))],
            ],
            'linux': [
                ['\${EXTRA_SHARED_LIBS}', '${PATH_TO_SHARED_LIBS}/libPhysXGpu_64.so'],
                ['\${EXTRA_STATIC_LIBS_NON_MONOLITHIC}', ''],
            ],
            'linux-aarch64': [
                ['\${EXTRA_SHARED_LIBS}', '${PATH_TO_SHARED_LIBS}/libPhysXGpu_64.so'],
                ['\${EXTRA_STATIC_LIBS_NON_MONOLITHIC}', ''],
            ],
            'mac': [
                ['\${EXTRA_SHARED_LIBS}', ''],
                ['\${EXTRA_STATIC_LIBS_NON_MONOLITHIC}', ''],
            ],
            # iOS has its own FindPhysX file where it doesn't need to do any adjustments.
            'ios': [
            ],
            'android': [
                ['\${EXTRA_SHARED_LIBS}', ''],
                ['\${EXTRA_STATIC_LIBS_NON_MONOLITHIC}', ''],
            ],
        }
        
        content = self.readFile(dst)
        for extraLibs in extraLibsPerPlatform[self.platform]:
            content = re.sub(extraLibs[0], extraLibs[1], content, flags = re.M)
        self.writeFile(dst, content)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'linux', 'linux-aarch64', 'android', 'mac', 'ios'],
    )
    args = parser.parse_args()

    if args.platformName == 'mac' or args.platformName == 'ios':
        # Necessary to build PhysX SDK on arm-based Mac machines
        # since the build process will try to use an x86_64 python3
        # package that PhysX downloads itself. This environment variable
        # allows to use the system's python until nVidia updates its build
        # scripts to obtain an arm-based python package.
        os.environ['PM_PYTHON_EXT'] = 'python3'

    packageSystemDir = Path(__file__).resolve().parents[1]
    packageSourceDir = packageSystemDir / 'PhysX5'
    packageRoot = packageSourceDir / 'temp' / f'PhysX5-{args.platformName}'

    cmakeFindFile = packageSourceDir / f'FindPhysX_{args.platformName}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'FindPhysX.cmake'

    with TemporaryDirectory() as tempdir:
        # Package Name
        revision = 'rev2'
        if args.platformName == 'windows':
            revision = 'rev3'
        packageName = f'PhysX-5.1.1-{revision}-{args.platformName}'
        
        # Version 5.1.1 commits
        if args.platformName == 'mac':
            commit = 'bbf7c0de9738c99046c9d6daf57779b4decf95ef' # Commit of PR 51 on top of 5.1.1 version
        elif args.platformName == 'ios':
            commit = '5420931fd1e60aaa4df2688d07557722d021f034' # Commit of PR 49 on top of 5.1.1 version
        elif args.platformName == 'android':
            commit = '8ac3e3601d1333ae2a967995f49b338d4e188215' # Commit of PR 40 on top of 5.1.1 version
        else:
            commit = '0bbcff3d0c541325f4d14c36ee18f24e22e35e6e' # Commit for 5.1.1 version
            
        tempdir = Path(tempdir)
        builder = PhysXBuilder(workingDir=tempdir, basePackageSystemDir=packageSystemDir, targetPlatform=args.platformName)
        builder.clone(lockToCommit=commit)
        
        builder.build(buildAsStaticLibs=False)
        builder.build(buildAsStaticLibs=True)
        builder.copyBuildOutputTo(packageRoot/'PhysX')
        
        builder.writePackageInfoFile(
            packageRoot,
            settings={
                'PackageName': packageName,
                'URL': 'https://github.com/NVIDIA-Omniverse/PhysX',
                'License': 'BSD-3-Clause',
                'LicenseFile': 'PhysX/LICENSE.md'
            },
        )
        
        builder.writeCMakeFindFile(
            packageRoot,
            cmakeFindFile
        )

if __name__ == '__main__':
    main()
