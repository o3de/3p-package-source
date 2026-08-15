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
import subprocess

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--platform-name',
        dest='platformName',
        choices=['windows', 'android', 'mac', 'ios', 'wasm32'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()

    opensslVersion = '3.6.3'

    packageSystemDir = Path(__file__).resolve().parents[1]
    opensslPackageSourceDir = packageSystemDir / 'OpenSSL'
    outputDir = opensslPackageSourceDir / 'temp' / f'OpenSSL-{args.platformName}'

    cmakeFindFile = opensslPackageSourceDir / 'FindOpenSSL.cmake.template'
    cmakeFindFileTemplate = cmakeFindFile.open().read()

    useStaticLibsForPlatform = {
        'android': True,
        'mac': True,
        'ios': True,
        'windows': True,
        'wasm32': True,
    }

    revisionForPlatform = {
        'android': 'rev2',
        'mac': 'rev1',
        'ios': 'rev1',
        'windows': 'rev1',
        "wasm32": 'rev1',
    }

    testScriptForPlatform = {
        'android' : opensslPackageSourceDir / 'test_OpenSSL_android.cmd',
        'mac' : opensslPackageSourceDir / 'test_OpenSSL_mac.sh',
        'ios' : opensslPackageSourceDir / 'test_OpenSSL_ios.sh',
        'windows' : opensslPackageSourceDir / 'test_OpenSSL_windows.cmd',
        'wasm32' : opensslPackageSourceDir / 'test_OpenSSL_wasm32.cmd'
    }

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        builder = VcpkgBuilder(packageName='OpenSSL', portName='openssl', vcpkgDir=tempdir, targetPlatform=args.platformName, static=useStaticLibsForPlatform[args.platformName])
        builder.deleteFolder(outputDir)
        builder.cloneVcpkg('52c9e08cdf8580d2d9762f547d22b96fd81e82f2')  # vcpkg tag 2026.06.24, ships OpenSSL 3.6.3
        builder.bootstrap()
        builder.build()
        builder.copyBuildOutputTo(outputDir, extraFiles={})

        revisionName = revisionForPlatform[args.platformName]

        builder.writePackageInfoFile(
            outputDir,
            settings={
                'PackageName': f'OpenSSL-{opensslVersion}-{revisionName}-{args.platformName}',
                'URL': 'https://github.com/openssl/openssl',
                'License': 'Apache-2.0',
                'LicenseFile': 'OpenSSL/share/openssl/copyright'
            },
        )

        crypto_library_dependencies = ''
        if args.platformName == 'windows':
            crypto_library_dependencies = 'crypt32.lib ws2_32.lib'
        builder.writeCMakeFindFile(
            outputDir,
            template=cmakeFindFileTemplate,
            templateEnv={
                'CRYPTO_LIBRARY_DEPENDENCIES':crypto_library_dependencies,
                'OPENSSL_VERSION_STRING':opensslVersion
            },
            overwrite_find_file=None,
        )
    # now test the package, it will be in outputDir
    customEnviron = os.environ.copy()
    customEnviron["PACKAGE_ROOT"] = str(outputDir.resolve())
    scriptpath = testScriptForPlatform[args.platformName].resolve()
    cwdpath = opensslPackageSourceDir.resolve()
    print(f'Running test script "{scriptpath}" with package "{outputDir}" with cwd "{cwdpath}"')
    subprocess.check_call(
                [ str(scriptpath) ],
                cwd=str(cwdpath),
                env=customEnviron
            )
    

if __name__ == '__main__':
    main()

