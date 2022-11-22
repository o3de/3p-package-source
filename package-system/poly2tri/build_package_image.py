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
        choices=['windows', 'mac', 'linux', 'linux-aarch64'],
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
    packageSourceDir = packageSystemDir / 'poly2tri'
    outputDir = packageSystemDir / f'poly2tri-{args.platformName}'

    cmakeFindFile = packageSourceDir / f'Findpoly2tri_{args.platformName}.cmake'
    if not cmakeFindFile.exists():
        cmakeFindFile = packageSourceDir / 'Findpoly2tri.cmake'

    # vcpkg uses https://github.com/greenm01/poly2tri repo (88de490), but we need
    # the more recent version from https://github.com/jhasse/poly2tri repo (7f0487a),
    # patching vcpkg to build jhasse version.
    buildJhasseRepoPatch = (packageSourceDir / 'build-poly2tri-jhasse-repo.patch')
        
    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        
        builder = VcpkgBuilder(
            packageName='poly2tri',
            portName='poly2tri',
            vcpkgDir=tempdir,
            targetPlatform=vcpkg_platform,
            static=True
        )
        
        builder.cloneVcpkg('751fc199af8d33eb300af5edbd9e3b77c48f0bca')
        builder.patch(buildJhasseRepoPatch)
        builder.bootstrap()
        builder.build()
        
        builder.copyBuildOutputTo(
            outputDir,
            extraFiles={
                next(builder.vcpkgDir.glob(f'buildtrees/poly2tri/src/*/LICENSE')): outputDir / builder.packageName / 'LICENSE',
                next(builder.vcpkgDir.glob(f'buildtrees/poly2tri/src/*/README.md')): outputDir / builder.packageName / 'README.md',
            },
            subdir='poly2tri'
        )
        
        # vcpkg's commit 751fc19 uses poly2tri's commit 7f0487a (after patch)
        builder.writePackageInfoFile(
            outputDir,
            settings={
                'PackageName': f'poly2tri-7f0487a-rev1-{args.platformName}',
                'URL': 'https://github.com/jhasse/poly2tri',
                'License': 'BSD-3-Clause',
                'LicenseFile': 'poly2tri/LICENSE'
            },
        )
        
        shutil.copy2(
            src=cmakeFindFile,
            dst=outputDir / 'Findpoly2tri.cmake'
        )

if __name__ == '__main__':
    main()
