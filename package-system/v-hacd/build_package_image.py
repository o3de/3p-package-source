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
import shutil

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'mac', 'linux'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()

    packageSystemDir = Path(__file__).resolve().parents[1]
    packageSourceDir = packageSystemDir / 'v-hacd'
    outputDir = packageSystemDir / f'v-hacd-{args.platformName}'

    cmakeFindFile = packageSourceDir / f'Findv-hacd_{args.platformName}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'Findv-hacd.cmake'

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        
        builder = VcpkgBuilder(
            packageName='v-hacd',
            portName='v-hacd',
            vcpkgDir=tempdir,
            targetPlatform=args.platformName,
            static=True
        )
        
        builder.cloneVcpkg('751fc199af8d33eb300af5edbd9e3b77c48f0bca')
        builder.bootstrap()
        builder.build()
        
        builder.copyBuildOutputTo(
            outputDir,
            extraFiles={
                next(builder.vcpkgDir.glob(f'buildtrees/v-hacd/src/*/LICENSE')): outputDir / builder.packageName / 'LICENSE',
                next(builder.vcpkgDir.glob(f'buildtrees/v-hacd/src/*/README.md')): outputDir / builder.packageName / 'README.md',
            },
            subdir='v-hacd'
        )
        
        # vcpkg's commit 751fc19 uses v-hacd version 2.3 at commit 1a49edf
        builder.writePackageInfoFile(
            outputDir,
            settings={
                'PackageName': f'v-hacd-2.3-1a49edf-rev1-{args.platformName}',
                'URL': 'https://github.com/kmammou/v-hacd',
                'License': 'BSD-3-Clause',
                'LicenseFile': 'v-hacd/LICENSE'
            },
        )
        
        shutil.copy2(
            src=cmakeFindFile,
            dst=outputDir / 'Findv-hacd.cmake'
        )

if __name__ == '__main__':
    main()
