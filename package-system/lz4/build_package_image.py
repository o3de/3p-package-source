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
        'linux-aarch64': 'linux' 
    }

    vcpkg_platform = vcpkg_platform_map[args.platformName]
    if args.platformName == 'linux-aarch64':
        os.environ['VCPKG_FORCE_SYSTEM_BINARIES'] = '1'

    packageSystemDir = Path(__file__).resolve().parents[1]
    packageSourceDir = packageSystemDir / 'lz4'
    outputDir = packageSystemDir / f'lz4-{args.platformName}'

    cmakeFindFile = packageSourceDir / f'Findlz4_{args.platformName}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'Findlz4.cmake'

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        
        builder = VcpkgBuilder(
            packageName='lz4',
            portName='lz4',
            vcpkgDir=tempdir,
            targetPlatform=vcpkg_platform,
            static=True
        )
        
        builder.cloneVcpkg('09019cbc9abcb728217c4c99625932defe1b781c')
        builder.bootstrap()
        builder.build()
        
        builder.copyBuildOutputTo(
            outputDir,
            extraFiles={
                next(builder.vcpkgDir.glob(f'buildtrees/lz4/src/*/LICENSE')): outputDir / builder.packageName / 'LICENSE',
                next(builder.vcpkgDir.glob(f'buildtrees/lz4/src/*/README.md')): outputDir / builder.packageName / 'README.md',
            },
            subdir='lz4'
        )
        
        # vcpkg's commit 751fc19 uses lz4 version 2.3 at commit 1a49edf
        builder.writePackageInfoFile(
            outputDir,
            settings={
                'PackageName': f'lz4-1.9.3-vcpkg-rev4-{args.platformName}',
                'URL': 'https://github.com/lz4/lz4',
                'License': 'BSD-2-Clause',
                'LicenseFile': 'lz4/LICENSE'
            },
        )
        
        shutil.copy2(
            src=cmakeFindFile,
            dst=outputDir / 'Findlz4.cmake'
        )

if __name__ == '__main__':
    main()
