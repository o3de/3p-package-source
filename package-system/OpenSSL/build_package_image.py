#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
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
    opensslPackageSourceDir = packageSystemDir / 'OpenSSL'
    outputDir = packageSystemDir / f'OpenSSL-{args.platformName}'
    opensslPatch = opensslPackageSourceDir / 'set_openssl_port_to_1_1_1_b.patch'

    enableStdioOnIOS = opensslPackageSourceDir / 'enable-stdio-on-iOS.patch'

    cmakeFindFile = opensslPackageSourceDir / f'FindOpenSSL_{args.platformName}.cmake.template'
    if not cmakeFindFile.exists():
        cmakeFindFile = opensslPackageSourceDir / 'FindOpenSSL.cmake.template'
    cmakeFindFileTemplate = cmakeFindFile.open().read()

    useStaticLibsForPlatform = {
        'linux': False,
        'android': True,
        'mac': True,
        'ios': True,
        'windows': True,
    }

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        builder = VcpkgBuilder(packageName='OpenSSL', portName='openssl', vcpkgDir=tempdir, targetPlatform=args.platformName, static=useStaticLibsForPlatform[args.platformName])
        builder.cloneVcpkg('f44fb85b341b8f58815b95c84d8488126b251570')
        builder.bootstrap()
        builder.patch(opensslPatch)
        builder.patch(enableStdioOnIOS)
        builder.build()
        builder.copyBuildOutputTo(
            outputDir,
            extraFiles={
                next(builder.vcpkgDir.glob(f'buildtrees/openssl/{builder.triplet}-rel/**/LICENSE')): outputDir / builder.packageName / 'LICENSE',
            })

        builder.writePackageInfoFile(
            outputDir,
            settings={
                'PackageName': f'OpenSSL-1.1.1b-rev2-{args.platformName}',
                'URL': 'https://github.com/openssl/openssl',
                'License': 'OpenSSL',
                'LicenseFile': 'OpenSSL/LICENSE'
            },
        )

        extraLibs = []
        compileDefs = []
        if args.platformName == 'windows':
            extraLibs.append('crypt32.lib')
        builder.writeCMakeFindFile(
            outputDir,
            template=cmakeFindFileTemplate,
            templateEnv={
                'CUSTOM_ADDITIONAL_LIBRARIES':extraLibs,
                'CUSTOM_ADDITIONAL_COMPILE_DEFINITIONS':compileDefs,
            },
        )

if __name__ == '__main__':
    main()
