# Copyright (c) Contributors to the Open 3D Engine Project. 
# For complete copyright and license terms please see the LICENSE at the root
# of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


import argparse
from pathlib import Path
import re
import shutil
from tempfile import TemporaryDirectory

import sys
sys.path.append(str(Path(__file__).parent.parent.parent / 'Scripts'))
from builders.vcpkgbuilder import VcpkgBuilder
import builders.monkeypatch_tempdir_cleanup


def regex_to_remove(platform_name: str):
    """
    Get the regular expression for files and sub-folders to remove.

    :param platform_name: Name of the platform.
    :return: Regular expression for files and sub-folders to remove.
    """
    regex_map = {
        'windows':
            '^(?:.*_|.*\\\\)?(?:ios|mac|android|linux|fuchsia|non|x86|test|testing|vcpkg|BUILD_INFO|CONTROL)(?:_.*)?(?:\\.h)?$'
    }
    return regex_map.get(platform_name, '.*')

def remove_files_by_regex(package_dir: Path, regex: str):
    """
    Remove files and sub-folders from the package by an regular expression.

    :param package_dir: Path to the package directory.
    :param regex: Regular expression for the files and sub-folders to remove.
    """
    pattern = re.compile(regex)
    for item in package_dir.glob('**/*'):
        if re.search(pattern, item.name) and item.exists():
            if item.is_file():
                item.unlink()
            else:
                shutil.rmtree(item)


def main():
    parser = argparse.ArgumentParser(description='Builds this package')
    parser.add_argument(
        '--platform-name',
        choices=['windows', 'android', 'mac', 'ios', 'linux'],
        default=VcpkgBuilder.defaultPackagePlatformName(),
    )
    args = parser.parse_args()

    package_system_dir = Path(__file__).resolve().parents[1]
    crashpad_package_source_dir = package_system_dir / 'Crashpad'
    output_dir = package_system_dir / f'Crashpad-{args.platform_name}'
    crashpad_patch = crashpad_package_source_dir / 'add_o3de_handler_extensions.patch'

    cmake_find_file = crashpad_package_source_dir / f'FindCrashpad_{args.platform_name}.cmake.template'
    if not cmake_find_file.exists():
        cmake_find_file = crashpad_package_source_dir / 'FindCrashpad.cmake.template'
    cmake_find_file_template = cmake_find_file.open().read()

    with TemporaryDirectory() as tempdir:
        tempdir = Path(tempdir)
        builder = VcpkgBuilder('Crashpad', 'crashpad', tempdir, args.platform_name, static=False)
        builder.cloneVcpkg('3639676313a3e8b6fe1e94b9e7917b71d32511e3')
        builder.bootstrap()
        builder.patch(crashpad_patch)
        builder.build()

        builder.copyBuildOutputTo(
            output_dir,
            extraFiles={
                Path(f'{builder.vcpkgDir}/buildtrees/{builder.portName}/{builder.triplet}-rel/gen/build/chromeos_buildflags.h'):
                    Path(f'{output_dir}/{builder.packageName}/include/{builder.portName}/mini_chromium/build/'),
                Path(f'{builder.vcpkgDir}/ports/{builder.portName}/o3de_handler_extensions.patch'):
                    Path(f'{output_dir}/{builder.packageName}/share/{builder.portName}/')
            })

        port_dir = output_dir / builder.packageName / 'include' / builder.portName
        package_info_list = [
            {
                'dir': output_dir,
                'settings': {
                    'PackageName': f'Crashpad-0.8.0-rev1-{args.platform_name}',
                    'URL': 'https://chromium.googlesource.com/crashpad/crashpad/+/master/README.md',
                    'License': 'Apache-2.0',
                    'LicenseFile': f'{builder.packageName}/share/{builder.portName}/copyright'
                }
            },
            {
                'dir': port_dir / 'getopt',
                'settings': {
                    'PackageName': 'getopt',
                    'URL': 'https://sourceware.org/legacy-ml/newlib/2005/msg00758.html',
                    'License': 'custom',
                    'LicenseFile': 'LICENSE'
                }
            },
            {
                'dir': port_dir / 'mini_chromium' / 'base' / 'third_party' / 'icu',
                'settings': {
                    'PackageName': 'ICU',
                    'URL': 'http://site.icu-project.org/',
                    'License': 'Unicode-DFS-2016',
                    'LicenseFile': 'LICENSE'
                }
            },
            {
                'dir': port_dir / 'mini_chromium',
                'settings': {
                    'PackageName': 'mini_chromium',
                    'URL': 'https://chromium.googlesource.com/chromium/mini_chromium/',
                    'License': 'BSD-3-Clause',
                    'LicenseFile': 'LICENSE'
                }
            },
            {
                'dir': port_dir / 'zlib',
                'settings': {
                    'PackageName': 'zlib',
                    'URL': 'https://zlib.net/',
                    'License': 'Zlib',
                    'LicenseFile': 'LICENSE'
                }
            }
        ]

        for package_info in package_info_list:
            builder.writePackageInfoFile(
                package_info.get('dir', ''),
                settings=package_info.get('settings', {})
            )

        builder.writeCMakeFindFile(
            output_dir,
            template=cmake_find_file_template
        )

        remove_files_by_regex(
            output_dir,
            regex_to_remove(args.platform_name)
        )


if __name__ == '__main__':
    main()
