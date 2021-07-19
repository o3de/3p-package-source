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

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'android', 'mac', 'ios', 'linux'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()

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
            'EXTRA_SHARED_LIBS': '${CMAKE_CURRENT_LIST_DIR}/PhysX/pxshared/$<IF:$<CONFIG:debug>,debug/,$<$<CONFIG:profile>:profile/>>bin/libPhysXGpu_64.so',
            'EXTRA_STATIC_LIBS_NON_MONOLITHIC': '',
        },
        'windows': {
            'EXTRA_SHARED_LIBS': '\n'.join((
                '${CMAKE_CURRENT_LIST_DIR}/PhysX/pxshared/$<IF:$<CONFIG:debug>,debug/,$<$<CONFIG:profile>:profile/>>bin/PhysXDevice64.dll'
                '${CMAKE_CURRENT_LIST_DIR}/PhysX/pxshared/$<IF:$<CONFIG:debug>,debug/,$<$<CONFIG:profile>:profile/>>bin/PhysGpu_64.dll'
            )),
            'EXTRA_STATIC_LIBS_NON_MONOLITHIC': '\n'.join((
                '${PATH_TO_STATIC_LIBS}/LowLevel_static_64.lib',
                '${PATH_TO_STATIC_LIBS}/LowLevelAABB_static_64.lib',
                '${PATH_TO_STATIC_LIBS}/LowLevelDynamics_static_64.lib',
                '${PATH_TO_STATIC_LIBS}/PhysXTask_static_64.lib',
                '${PATH_TO_STATIC_LIBS}/SceneQuery_static_64.lib',
                '${PATH_TO_STATIC_LIBS}/SimulationController_static_64.lib',
            )),
        },
        'mac': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS_NON_MONOLITHIC': '',
        },
        'ios': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS_NON_MONOLITHIC': '',
        },
        'android': {
            'EXTRA_SHARED_LIBS': '',
            'EXTRA_STATIC_LIBS_NON_MONOLITHIC': '',
        },
    }
    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)

        firstTime = True

        # We package PhysX static and dynamic libraries for all supported platforms
        for maybeStatic in (True, False):
            builder = VcpkgBuilder(
                packageName='PhysX',
                portName='physx',
                vcpkgDir=tempdir,
                targetPlatform=args.platformName,
                static=maybeStatic
            )
            if firstTime:
                builder.cloneVcpkg('751fc199af8d33eb300af5edbd9e3b77c48f0bca')
                builder.patch(buildPhysXInProfileConfigPatch)
                builder.bootstrap()
            builder.build()

            if maybeStatic:
                subdir = 'physx'
            else:
                subdir = 'pxshared'
            builder.copyBuildOutputTo(
                outputDir,
                extraFiles={
                    next(builder.vcpkgDir.glob(f'buildtrees/physx/src/*/LICENSE.md')): outputDir / builder.packageName / 'LICENSE.md',
                    next(builder.vcpkgDir.glob(f'buildtrees/physx/src/*/README.md')): outputDir / builder.packageName / 'README.md',
                },
                subdir=subdir
            )

            if firstTime:
                builder.writePackageInfoFile(
                    outputDir,
                    settings={
                        'PackageName': f'PhysX-4.1.2.29882248-rev3-{args.platformName}',
                        'URL': 'https://github.com/NVIDIAGameWorks/PhysX',
                        'License': 'BSD-3-Clause',
                        'LicenseFile': 'PhysX/LICENSE.md'
                    },
                )

                builder.writeCMakeFindFile(
                    outputDir,
                    template=cmakeFindFileTemplate,
                    templateEnv=extraLibsPerPlatform[args.platformName],
                )

            firstTime = False

if __name__ == '__main__':
    main()
