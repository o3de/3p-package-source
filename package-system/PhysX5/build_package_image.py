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
import platform
import shutil
import subprocess
from tempfile import TemporaryDirectory

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
import builders.monkeypatch_tempdir_cleanup

class PhysXBuilder(object):
    def __init__(self, workingDir: pathlib.Path, basePackageSystemDir: pathlib.Path, targetPlatform: str, enable_GPU: bool = False):
        self._workingDir = workingDir
        self._packageSystemDir = basePackageSystemDir
        self._enable_GPU = enable_GPU
        self._platform = targetPlatform
        self._hostPlatformLower = platform.system().lower()
        self._env = dict(os.environ)
        self._env.update(
            GW_DEPS_ROOT=str(workingDir),
        )

        if self.enable_GPU:
            if self._env.get("PM_CUDA_PATH") is None:
                if self._env.get('CUDA_PATH') is None and self._env.get('CUDA_PATH_V12_8') is None:
                    print("Could not find CUDA_PATH or CUDA_PATH_V12_8 environment variable.  Cannot build PhysX with GPU support.")
                    print("CUDA_PATH should point to the root of a CUDA installation, recommend v12.8, for example on Windows, this would be something like")
                    print("   set CUDA_PATH=C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\v12.8")
                    raise Exception("CUDA_PATH or CUDA_PATH_V12_8 environment variable must be set to build PhysX with GPU support.  Recommend v12.8")
                self._env['PM_CUDA_PATH'] = self._env.get('CUDA_PATH_V12_8', self._env.get('CUDA_PATH'))

        self.check_call = functools.partial(subprocess.check_call,
            cwd=self.workingDir,
            env=self.env
        )
        
        # nVidia CMakeModules (downloaded while building PhysX) do not cover ios
        # bin folder names yet, so they appear as UNKNOWN.
        self.platform_params = { 
            # system-name   : (preset,      can use CUDA,     bin folder name,    install folder name, is multiconfig)
            'windows'       : ('vc16win64',         True,  'win.x86_64.vc142.md', 'vc16win64',          True),
            'linux'         : ('linux',             True,  'linux.clang',         'linux',              False),
            'linux-aarch64' : ('linux-aarch64',     True,  'linux.aarch64',       'linux-aarch64',      False),
            'mac'           : ('mac64',             False, 'mac.x86_64',          'mac64',              True),
            'ios'           : ('ios64',             False, 'UNKNOWN',             'ios64',              True),
            'android'       : ('android-arm64-v8a', False, "android.arm64-v8a",   'android-29',         False)
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
    
    @property
    def enable_GPU(self):
        return self._enable_GPU

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
                ['git', 'remote', 'add', 'origin', 'https://github.com/nick-l-o3de/o3de-physx.git',],
            )

        self.check_call(
            ['git', 'fetch', 'origin', '--update-head-ok', '--depth=1', lockToCommit,],
        )
        self.check_call(
            ['git', 'checkout', lockToCommit,],
        )

    def preparePreset(self, buildAsStaticLibs, config):
        
        preset_name = self.platform_params[self.platform][0]
        supports_gpu_builds = self.platform_params[self.platform][1]

        if (self.enable_GPU and not supports_gpu_builds):
            raise Exception(f"Platform {self.platform} does not support GPU builds, but --enable_GPU was specified.")
        
        # if we're turning GPU off, and we support GPU builds, use the cpu-only preset.  Otherwise such a preset will not exist:
        if not self.enable_GPU and supports_gpu_builds:
            preset_name += "-cpu-only"

        preset_file = self.workingDir / 'physx' / 'buildtools' / 'presets' / 'public' / f'{preset_name}.xml'
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
    
        # Remove dynamic libraries, but copy some missing static libs from
        # the shared builds into the static lib folder. Also freeglut is not
        # necessary for PhysX.
        if self.platform == 'windows':
            if not buildAsStaticLibs:

                for extra_static_lib_filename in ['LowLevel_static_64',
                                                  'LowLevelAABB_static_64',
                                                  'LowLevelDynamics_static_64',
                                                  'PhysXTask_static_64',
                                                  'SceneQuery_static_64',
                                                  'SimulationController_static_64']:

                    for extra_static_lib_ext in ['.lib', '.pdb']:

                        for config in ('release', 'profile', 'checked', 'debug'):

                            src_extra_static_lib = shared_bin_dir / config / f'{extra_static_lib_filename}{extra_static_lib_ext}'
                            dst_extra_static_lib = static_bin_dir / config / f'{extra_static_lib_filename}{extra_static_lib_ext}'
                            print(f"Copying {src_extra_static_lib} -> {dst_extra_static_lib}")
                            shutil.copy2(src=src_extra_static_lib, dst=dst_extra_static_lib)

                for config in ('release', 'profile', 'checked', 'debug'):
                    if config == 'debug':
                        os.remove(static_bin_dir / config / 'freeglutd.dll')
                    else:
                        os.remove(static_bin_dir / config / 'freeglut.dll')

                shutil.rmtree(shared_bin_dir)
            
    def build(self, buildAsStaticLibs):
        physx_dir = self.workingDir / 'physx'

        # Update the packman URLs
        packman_dir = physx_dir / 'buildtools' / 'packman'
        check_call_packman_update = functools.partial(subprocess.check_call,
            cwd=packman_dir, # generate_projects script will fail if not called from physx directory
            env=self.env
        )

        if self._hostPlatformLower == 'windows':
            update_pacman_call = [ str(packman_dir / 'packman.cmd'), 'update', '-y']
        else:
            update_pacman_call = [ str(packman_dir / 'packman'), 'update', '-y']

        check_call_packman_update(update_pacman_call)        
        preset, supports_gpu, bin_folder, install_folder, is_multiconfig = self.platform_params[self.platform]

        # if we are turning the GPU support off, and we are in a preset that supports GPU, we have to append wart to the end of the name
        if not self.enable_GPU and supports_gpu:
            preset += "-cpu-only"
            install_folder += "-cpu-only"
        
        if self._hostPlatformLower == 'windows':
            generate_projects_cmd =  str(physx_dir / 'generate_projects.bat')
        else:
            generate_projects_cmd = str(physx_dir / 'generate_projects.sh')
            
        check_call_physx_dir = functools.partial(subprocess.check_call,
            cwd=physx_dir, # generate_projects script will fail if not called from physx directory
            env=self.env
        )
        
        for config in ('release', 'profile', 'checked', 'debug'):
            self.preparePreset(buildAsStaticLibs, config);
            
            generate_call =[generate_projects_cmd, preset,]
            print(generate_call)
            check_call_physx_dir(generate_call)

            # Build
            if is_multiconfig:
                build_dir = os.path.join(physx_dir, 'compiler', preset)
                if config == 'release':
                    # Build install target on release to produce the install folder where all the headers will be generated
                    cmake_build_call =['cmake', '--build', build_dir, '--config', config, '--target', 'install', '--parallel']
                else:
                    cmake_build_call =['cmake', '--build', build_dir, '--config', config, '--parallel']
            else:
                build_dir = os.path.join(physx_dir, 'compiler', f'{preset}-{config}')
                if config == 'release':
                    # Build install target on release to produce the install folder where all the headers will be generated
                    cmake_build_call =['cmake', '--build', build_dir, '--target', 'install', '--parallel']
                else:
                    cmake_build_call =['cmake', '--build', build_dir, '--parallel']
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

    def build_all(self):

        self.build(buildAsStaticLibs=True)

        if self.platform == 'windows':
            self.build(buildAsStaticLibs=False)

    def copyBuildOutputTo(self, packageDir: pathlib.Path):
        if packageDir.exists():
            shutil.rmtree(packageDir)
            

        shutil.copytree(
            src=self.workingDir / 'physx' / 'install' / 'static' / 'PhysX',
            dst=packageDir / 'physx',
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
        dst = packageDir / 'FindPhysX5.cmake'
        shutil.copy2(
            src=cmakeFindFile,
            dst=dst
        )

        extraLibsPerPlatform = {
            'windows': [
                ['\\${EXTRA_SHARED_LIBS}',
                 ''.join(('\n',
                    '\t${PATH_TO_LIBS}/PhysXDevice64.dll\n',
                    '\t${PATH_TO_LIBS}/PhysXGpu_64.dll\n'
                ))],
                ['\\${EXTRA_STATIC_LIBS}',
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
                ['\\${EXTRA_SHARED_LIBS}', '${PATH_TO_LIBS}/libPhysXGpu_64.so'],
                ['\\${EXTRA_STATIC_LIBS}', ''],
            ],
            'linux-aarch64': [
                ['\\${EXTRA_SHARED_LIBS}', '${PATH_TO_LIBS}/libPhysXGpu_64.so'],
                ['\\${EXTRA_STATIC_LIBS}', ''],
            ],
            'mac': [
                ['\\${EXTRA_SHARED_LIBS}', ''],
                ['\\${EXTRA_STATIC_LIBS}', ''],
            ],
            # iOS has its own FindPhysX file where it doesn't need to do any adjustments.
            'ios': [
            ],
            'android': [
                ['\\${EXTRA_SHARED_LIBS}', ''],
                ['\\${EXTRA_STATIC_LIBS}', ''],
            ],
        }
        
        content = self.readFile(dst)
        for extraLibs in extraLibsPerPlatform[self.platform]:
            content = re.sub(extraLibs[0], extraLibs[1], content, flags = re.M)
        self.writeFile(dst, content)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--package-name',
        required=True
    )
    parser.add_argument(
        '--package-rev',
        required=True
    )
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'linux', 'linux-aarch64', 'android', 'mac', 'ios'],
    )

    parser.add_argument(
        '--enable-gpu',
        action='store_true'
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

    cmakeFindFile = packageSourceDir / f'FindPhysX5_{args.platformName}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'FindPhysX5.cmake'

    with TemporaryDirectory() as tempdir:
        # Package Name
        packageName = f'{args.package_name}-{args.package_rev}-{args.platformName}'
        
        # Version 5.6.1 commits
        if args.platformName == 'mac':
            commit = '47c79b2936b7cfd34abeedf685b70730884afc37'
        elif args.platformName == 'ios':
            commit = '47c79b2936b7cfd34abeedf685b70730884afc37'
        elif args.platformName == 'android':
            commit = '47c79b2936b7cfd34abeedf685b70730884afc37'
        else:
            commit = '47c79b2936b7cfd34abeedf685b70730884afc37'
            
        tempdir = Path(tempdir)
        builder = PhysXBuilder(workingDir=tempdir,
                               basePackageSystemDir=packageSystemDir,
                               targetPlatform=args.platformName,
                               enable_GPU =args.enable_gpu)
        builder.clone(lockToCommit=commit)
        
        builder.build_all()

        builder.copyBuildOutputTo(packageRoot/'PhysX')
        
        builder.writePackageInfoFile(
            packageRoot,
            settings={
                'PackageName': packageName,
                'URL': 'https://github.com/o3de/PhysX',
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
