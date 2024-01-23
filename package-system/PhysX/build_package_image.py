#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

from pathlib import Path
from tempfile import TemporaryDirectory
import argparse
import os
import sys

sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup

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
        choices=['windows', 'android', 'mac', 'ios', 'linux', 'linux-aarch64'],
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
    physxPackageSourceDir = packageSystemDir / 'PhysX'
    outputDir = packageSystemDir / f'PhysX-{args.platformName}'

    cmakeFindFile = physxPackageSourceDir / f'FindPhysX_{args.platformName}.cmake.template'
    if not cmakeFindFile.exists():
        cmakeFindFile = physxPackageSourceDir / 'FindPhysX.cmake.template'
    cmakeFindFileTemplate = cmakeFindFile.open().read()

    buildPhysXInProfileConfigPatch = (physxPackageSourceDir / 'Build-physx-profile-config.patch')

    extraLibsPerPlatform = {
        'linux': {
            'EXTRA_SHARED_LIBS': '${PATH_TO_SHARED_LIBS}/libPhysXGpu_64.so',
            'EXTRA_STATIC_LIBS': '',
            'KEEP_LIBS': ['libPhysXGpu_64.so'],
        },
        'windows': {
            'EXTRA_SHARED_LIBS': '\n'.join((
                '${PATH_TO_SHARED_LIBS}/PhysXDevice64.dll',
                '${PATH_TO_SHARED_LIBS}/PhysXGpu_64.dll'
            )),
            'EXTRA_STATIC_LIBS': '\n'.join((
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/LowLevel_static_64.lib',
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/LowLevelAABB_static_64.lib',
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/LowLevelDynamics_static_64.lib',
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/PhysXTask_static_64.lib',
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/SceneQuery_static_64.lib',
                '${PATH_TO_ADDITIONAL_STATIC_LIBS}/SimulationController_static_64.lib',
            )),
            'KEEP_LIBS': ['PhysXDevice64.dll', 
                          'PhysXGpu_64.dll',
                          'LowLevel_static_64.lib',
                          'LowLevelAABB_static_64.lib',
                          'LowLevelDynamics_static_64.lib',
                          'PhysXTask_static_64.lib',
                          'SceneQuery_static_64.lib',
                          'SimulationController_static_64.lib'],
        },
        'mac': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS': '',
            'KEEP_LIBS': [],
        },
        'ios': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS': '',
            'KEEP_LIBS': [],
        },
        'android': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS': '',
            'KEEP_LIBS': [],
        },
    }
    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)

        firstTime = True

        # We package PhysX static and dynamic libraries for all supported platforms
        for maybeStatic in (True, False):
            if not maybeStatic and vcpkg_platform != 'windows':
                continue
            builder = VcpkgBuilder(
                packageName='PhysX',
                portName='physx',
                vcpkgDir=tempdir,
                targetPlatform=vcpkg_platform,
                static=maybeStatic
            )
            if firstTime:
                builder.cloneVcpkg('751fc199af8d33eb300af5edbd9e3b77c48f0bca')
                builder.patch(buildPhysXInProfileConfigPatch)
                builder.bootstrap()
            builder.build()

            if maybeStatic:
                subdir = 'static'
            else:
                subdir = 'shared'
            builder.copyBuildOutputTo(
                outputDir,
                extraFiles={
                    next(builder.vcpkgDir.glob(f'buildtrees/physx/src/*/LICENSE.md')): outputDir / builder.packageName / 'LICENSE.md',
                    next(builder.vcpkgDir.glob(f'buildtrees/physx/src/*/README.md')): outputDir / builder.packageName / 'README.md',
                },
                subdir=subdir
            )
            if not maybeStatic:
                # Delete everything in the shared folder except for ones that are marked for keeping (static libraries)
                # to reduce the size of the package.
                output_shared_folder = outputDir / builder.packageName / 'shared'
                for clear_root, clear_dirs, clear_files in os.walk(str(output_shared_folder)):
                    keep_shared_files = extraLibsPerPlatform[vcpkg_platform]['KEEP_LIBS']
                    for clear_filename in clear_files:
                        if clear_filename in keep_shared_files:
                            continue
                        os.remove(os.path.join(clear_root, clear_filename))

            if firstTime:
                builder.writePackageInfoFile(
                    outputDir,
                    settings={
                        'PackageName': f'{args.package_name}-{args.package_rev}-{args.platformName}',
                        'URL': 'https://github.com/NVIDIAGameWorks/PhysX',
                        'License': 'BSD-3-Clause',
                        'LicenseFile': 'PhysX/LICENSE.md'
                    },
                )

                builder.writeCMakeFindFile(
                    outputDir,
                    template=cmakeFindFileTemplate,
                    templateEnv=extraLibsPerPlatform[vcpkg_platform],
                    overwrite_find_file='PhysX4'
                )

            firstTime = False

if __name__ == '__main__':
    main()
