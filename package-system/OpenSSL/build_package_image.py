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
        choices=['windows', 'android', 'mac', 'ios'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()

    packageSystemDir = Path(__file__).resolve().parents[1]
    opensslPackageSourceDir = packageSystemDir / 'OpenSSL'
    outputDir = opensslPackageSourceDir / 'temp' / f'OpenSSL-{args.platformName}'

    opensslPatch = opensslPackageSourceDir / 'set_openssl_port_to_1_1_1_x.patch'

    enableStdioOnIOS = opensslPackageSourceDir / 'enable-stdio-on-iOS.patch'

    cmakeFindFile = opensslPackageSourceDir / 'FindOpenSSL.cmake.template'
    cmakeFindFileTemplate = cmakeFindFile.open().read()

    useStaticLibsForPlatform = {
        'android': True,
        'mac': True,
        'ios': True,
        'windows': True,
    }

    testScriptForPlatform = {
        'android' : opensslPackageSourceDir / 'test_OpenSSL_android.cmd',
        'mac' : opensslPackageSourceDir / 'test_OpenSSL_mac.sh',
        'ios' : opensslPackageSourceDir / 'test_OpenSSL_ios.sh',
        'windows' : opensslPackageSourceDir / 'test_OpenSSL_windows.cmd'
    }

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        builder = VcpkgBuilder(packageName='OpenSSL', portName='openssl', vcpkgDir=tempdir, targetPlatform=args.platformName, static=useStaticLibsForPlatform[args.platformName])
        builder.deleteFolder(outputDir)
        builder.cloneVcpkg('b86c0c35b88e2bf3557ff49dc831689c2f085090')
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
                'PackageName': f'OpenSSL-1.1.1o-rev1-{args.platformName}',
                'URL': 'https://github.com/openssl/openssl',
                'License': 'OpenSSL',
                'LicenseFile': 'OpenSSL/LICENSE'
            },
        )

        crypto_library_dependencies = ''
        if args.platformName == 'windows':
            crypto_library_dependencies = 'crypt32.lib ws2_32.lib'
        builder.writeCMakeFindFile(
            outputDir,
            template=cmakeFindFileTemplate,
            templateEnv={
                'CRYPTO_LIBRARY_DEPENDENCIES':crypto_library_dependencies
            },
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

