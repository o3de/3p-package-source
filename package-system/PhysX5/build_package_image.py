#!/usr/bin/env python3
# Copyright (c) Contributors to the Open 3D Engine Project.
# SPDX-License-Identifier: Apache-2.0 OR MIT

import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
from urllib.parse import urlparse


# SDK, deployment target, and LC_BUILD_VERSION platform.
APPLE_TARGETS = {
    'ios-arm': ('iphoneos', '14.0', 2),
    'mac-arm': ('macosx', '11.0', 1),
}
TARGETS = ('android-aarch64', *APPLE_TARGETS, 'windows-x64', 'linux-aarch64', 'linux-x64')
CONFIGS = ('debug', 'checked', 'profile', 'release')
GPU_PLATFORMS = ('windows-x64', 'linux-aarch64', 'linux-x64')


def platform_args(target):
    if target == 'android-aarch64':
        ndk = Path(os.environ.get('ANDROID_NDK_LATEST_HOME') or os.environ['ANDROID_NDK_HOME'])
        return ['-DCMAKE_TOOLCHAIN_FILE=' + (ndk / 'build/cmake/android.toolchain.cmake').as_posix(),
                '-DANDROID_ABI=arm64-v8a', '-DANDROID_PLATFORM=29']
    if target in ('linux-aarch64', 'linux-x64'):
        return ['-DCMAKE_C_COMPILER=clang-14', '-DCMAKE_CXX_COMPILER=clang++-14']
    if target in APPLE_TARGETS:
        sdk, deployment_target, _ = APPLE_TARGETS[target]
        arguments = ['-DCMAKE_OSX_ARCHITECTURES=arm64', '-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO',
                     '-DCMAKE_OSX_SYSROOT=' + sdk, '-DCMAKE_OSX_DEPLOYMENT_TARGET=' + deployment_target]
        if sdk != 'macosx':
            arguments.append('-DCMAKE_SYSTEM_NAME=iOS')
        return arguments
    return []


def prepare_cuda(temporary, target, packages):
    root = temporary / 'cuda'
    for url, _, _ in packages:
        archive_name = Path(urlparse(url).path).name
        extracted = temporary / Path(archive_name).stem
        directories = list(extracted.iterdir())
        if len(directories) != 1 or not directories[0].is_dir():
            raise RuntimeError('Unexpected CUDA archive layout: ' + str(extracted))
        package = directories[0]
        shutil.copytree(package, root, dirs_exist_ok=True, symlinks=True)
        notices = root / 'licenses' / package.name
        notices.mkdir(parents=True, exist_ok=True)
        shutil.copy2(package / 'LICENSE', notices / 'LICENSE')
    if target.startswith('linux-') and not (root / 'lib64').exists():
        (root / 'lib64').symlink_to('lib', target_is_directory=True)
    nvcc = root / ('bin/nvcc.exe' if target == 'windows-x64' else 'bin/nvcc')
    if not nvcc.is_file():
        raise RuntimeError('CUDA compiler missing: ' + str(nvcc))
    os.environ.update(PM_CUDA_PATH=root.as_posix(), CUDA_PATH=root.as_posix(), CUDACXX=nvcc.as_posix())


def copy_symbols(build_dir, sdk, config):
    for pdb in (build_dir / 'sdk_source_bin').glob('*.pdb'):
        shutil.copy2(pdb, sdk / 'lib' / pdb.name)
    for library in (sdk / 'lib').glob('*.lib'):
        if (sdk / 'bin' / library.with_suffix('.dll').name).is_file():
            continue
        symbols = list((build_dir / 'bin').glob('*/' + config + '/' + library.stem + '.pdb'))
        if len(symbols) != 1:
            raise RuntimeError('Missing or ambiguous compiler PDB for ' + str(library))
        shutil.copy2(symbols[0], library.with_suffix('.pdb'))


def build(target, temporary, destination):
    source = (temporary / 'src/physx').resolve()
    if target in GPU_PLATFORMS:
        config = json.loads(Path(__file__).with_name('build_config.json').read_text())
        host = platform.system()
        packages = config['Platforms'][host][target]['additional_download_packages']
        prepare_cuda(temporary, target, packages)
    generator = 'Xcode' if target in APPLE_TARGETS else 'Ninja'
    gpu = 'ON' if target in GPU_PLATFORMS else 'OFF'
    for config in CONFIGS:
        build_dir = (temporary / 'build' / config).resolve()
        sdk = destination / 'physx' / config
        arguments = ['cmake', '-S', str(source), '-B', str(build_dir), '-G', generator,
                     '-DCMAKE_BUILD_TYPE=' + config,
                     '-DCMAKE_INSTALL_PREFIX=' + sdk.as_posix(), '-DPX_GENERATE_STATIC_LIBRARIES=ON',
                     '-DPX_GENERATE_GPU_PROJECTS=' + gpu, '-DPX_GENERATE_GPU_PROJECTS_ONLY=OFF',
                     '-DPX_GENERATE_GPU_STATIC_LIBRARIES=OFF', '-DPX_BUILDSNIPPETS=OFF',
                     '-DPX_BUILDPVDRUNTIME=' + gpu, '-DNV_USE_STATIC_WINCRT=OFF', '-DNV_USE_DEBUG_WINCRT=ON']
        arguments += ['-D' + key + '=' + build_dir.as_posix()
                      for key in ('PX_OUTPUT_LIB_DIR', 'PX_OUTPUT_BIN_DIR', 'PX_OUTPUT_DLL_DIR')]
        arguments += platform_args(target)
        subprocess.run(arguments, check=True)
        subprocess.run(['cmake', '--build', str(build_dir), '--config', config, '--parallel', '4'], check=True)
        subprocess.run(['cmake', '--install', str(build_dir), '--config', config], check=True)
        if target == 'windows-x64':
            copy_symbols(build_dir, sdk, config)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--platform-name', choices=TARGETS, required=True)
    args = parser.parse_args()
    temporary = Path(os.environ['TEMP_FOLDER']).resolve()
    build(args.platform_name, temporary, Path(os.environ['TARGET_INSTALL_ROOT']).resolve())


if __name__ == '__main__':
    main()
