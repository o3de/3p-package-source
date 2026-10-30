#!/usr/bin/env python3
# Copyright (c) Contributors to the Open 3D Engine Project.
# SPDX-License-Identifier: Apache-2.0 OR MIT

import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import struct
import subprocess
from urllib.parse import urlparse


PRESETS = {
    'android-arm': 'android-arm64-v8a',
    'ios-arm': 'ios64',
    'windows-x64': 'vc17win64',
    'mac-arm': 'mac-arm64',
    'linux-arm': 'linux-aarch64-crosscompile',
    'linux-x64': 'linux-clang',
}
CONFIGS = ('debug', 'checked', 'profile', 'release')
GPU_PLATFORMS = ('windows-x64', 'linux-arm', 'linux-x64')


def platform_args(target, source):
    if target == 'android-arm':
        ndk = Path(os.environ.get('ANDROID_NDK_LATEST_HOME') or os.environ['ANDROID_NDK_HOME'])
        return ['-DCMAKE_TOOLCHAIN_FILE=' + (ndk / 'build/cmake/android.toolchain.cmake').as_posix(),
                '-DANDROID_ABI=arm64-v8a', '-DANDROID_PLATFORM=29']
    if target == 'linux-arm':
        return ['-DCMAKE_TOOLCHAIN_FILE=' + (source / 'buildtools/cmake/linux-aarch64-cross.cmake').as_posix(),
                '-DCMAKE_C_COMPILER=clang-14', '-DCMAKE_CXX_COMPILER=clang++-14']
    if target == 'linux-x64':
        return ['-DCMAKE_C_COMPILER=clang-14', '-DCMAKE_CXX_COMPILER=clang++-14']
    if target in ('mac-arm', 'ios-arm'):
        arguments = ['-DCMAKE_OSX_ARCHITECTURES=arm64', '-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO']
        if target == 'ios-arm':
            arguments += ['-DCMAKE_SYSTEM_NAME=iOS', '-DCMAKE_OSX_SYSROOT=iphoneos', '-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0']
        else:
            arguments += ['-DCMAKE_OSX_SYSROOT=macosx', '-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0']
        return arguments
    return []


def prepare_cuda(temporary, target, packages):
    root = temporary / 'cuda'
    cross = target == 'linux-arm'
    target_root = root / 'targets/sbsa-linux' if cross else root
    for url, _, _ in packages:
        archive_name = Path(urlparse(url).path).name
        extracted = temporary / Path(archive_name).stem
        directories = list(extracted.iterdir())
        if len(directories) != 1 or not directories[0].is_dir():
            raise RuntimeError('Unexpected CUDA archive layout: ' + str(extracted))
        package = directories[0]
        destination = target_root
        if package.name.startswith('cuda_nvcc-linux-x86_64-'):
            destination = root
        if package.name.startswith('cuda_nvcc-linux-sbsa-'):
            shutil.copytree(package / 'include', target_root / 'include', dirs_exist_ok=True, symlinks=True)
        else:
            shutil.copytree(package, destination, dirs_exist_ok=True, symlinks=True)
        notices = root / 'licenses' / package.name
        notices.mkdir(parents=True, exist_ok=True)
        shutil.copy2(package / 'LICENSE', notices / 'LICENSE')
    if target == 'linux-x64' and not (root / 'lib64').exists():
        (root / 'lib64').symlink_to('lib', target_is_directory=True)
    nvcc = root / ('bin/nvcc.exe' if target == 'windows-x64' else 'bin/nvcc')
    if not nvcc.is_file():
        raise RuntimeError('CUDA compiler missing: ' + str(nvcc))
    os.environ.update(PM_CUDA_PATH=root.as_posix(), CUDA_PATH=root.as_posix(), CUDACXX=nvcc.as_posix())


def copy_symbols(build_dir, sdk, config):
    for pdb in (build_dir / 'sdk_source_bin').glob('*.pdb'):
        shutil.copy2(pdb, sdk / 'lib' / pdb.name)
    for library in (sdk / 'lib').glob('*_static_64.lib'):
        symbols = list((build_dir / 'bin').glob('*/' + config + '/' + library.stem + '.pdb'))
        if len(symbols) != 1:
            raise RuntimeError('Missing or ambiguous compiler PDB for ' + str(library))
        shutil.copy2(symbols[0], library.with_suffix('.pdb'))


def build(target, temporary, destination):
    if target == 'linux-arm' and not shutil.which('aarch64-linux-gnu-g++'):
        subprocess.run(['sudo', 'apt-get', 'update'], check=True)
        subprocess.run(['sudo', 'apt-get', 'install', '-y', 'g++-aarch64-linux-gnu'], check=True)
    source = (temporary / 'src/physx').resolve()
    if target in GPU_PLATFORMS:
        config = json.loads(Path(__file__).with_name('build_config.json').read_text())
        host = platform.system()
        packages = config['Platforms'][host][target]['additional_download_packages']
        prepare_cuda(temporary, target, packages)
    generator = 'Xcode' if target in ('mac-arm', 'ios-arm') else 'Ninja'
    gpu = 'ON' if target in GPU_PLATFORMS else 'OFF'
    for config in CONFIGS:
        build_dir = (temporary / 'build' / config).resolve()
        sdk = destination / 'physx' / config
        arguments = ['cmake', '-S', str(source), '-B', str(build_dir), '-G', generator,
                     '-DPHYSX_PRESET=' + PRESETS[target], '-DCMAKE_BUILD_TYPE=' + config,
                     '-DCMAKE_INSTALL_PREFIX=' + sdk.as_posix(), '-DPX_GENERATE_STATIC_LIBRARIES=ON',
                     '-DPX_GENERATE_GPU_PROJECTS=' + gpu, '-DPX_GENERATE_GPU_PROJECTS_ONLY=OFF',
                     '-DPX_GENERATE_GPU_STATIC_LIBRARIES=OFF', '-DPX_BUILDSNIPPETS=OFF',
                     '-DPX_BUILDPVDRUNTIME=' + gpu, '-DNV_USE_STATIC_WINCRT=OFF', '-DNV_USE_DEBUG_WINCRT=ON']
        arguments += ['-D' + key + '=' + build_dir.as_posix()
                      for key in ('PX_OUTPUT_LIB_DIR', 'PX_OUTPUT_BIN_DIR', 'PX_OUTPUT_DLL_DIR')]
        arguments += platform_args(target, source)
        subprocess.run(arguments, check=True)
        subprocess.run(['cmake', '--build', str(build_dir), '--config', config, '--parallel', '4'], check=True)
        subprocess.run(['cmake', '--install', str(build_dir), '--config', config], check=True)
        if target == 'windows-x64':
            copy_symbols(build_dir, sdk, config)


def test(target, temporary, package):
    source = (temporary / 'src/physx').resolve()
    generator = 'Xcode' if target in ('mac-arm', 'ios-arm') else 'Ninja'
    machine = platform.machine().lower()
    native = ((target == 'windows-x64' and platform.system() == 'Windows' and machine in ('amd64', 'x86_64'))
              or (target == 'linux-x64' and platform.system() == 'Linux' and machine in ('amd64', 'x86_64'))
              or (target == 'mac-arm' and platform.system() == 'Darwin' and machine in ('arm64', 'aarch64')))
    for config, checked in [(config, False) for config in CONFIGS] + [('profile', True)]:
        name = config + ('-checked' if checked else '')
        build_dir = (temporary / 'test' / target / name).resolve()
        arguments = ['cmake', '-S', str(Path(__file__).with_name('test')), '-B', str(build_dir), '-G', generator,
                     '-DCMAKE_BUILD_TYPE=' + config, '-DCMAKE_MODULE_PATH=' + package.as_posix(),
                     '-DCMAKE_DISABLE_FIND_PACKAGE_CUDAToolkit=ON',
                     '-DLY_PHYSX_PROFILE_USE_CHECKED_LIBS=' + ('ON' if checked else 'OFF'),
                     '-DEXPECT_GPU=' + ('ON' if target in GPU_PLATFORMS else 'OFF')]
        arguments += platform_args(target, source)
        subprocess.run(arguments, check=True)
        subprocess.run(['cmake', '--build', str(build_dir), '--config', config, '--parallel', '2'], check=True)
        executable = Path((build_dir / (config + '-consumer.txt')).read_text())
        inspect_binary(executable, target)
        library = Path((build_dir / (config + '-library.txt')).read_text())
        expected = 'checked' if checked else config
        if not library.is_relative_to(package / 'PhysX/physx' / expected):
            raise RuntimeError('Incorrect SDK configuration selected: ' + str(library))
        runtime = build_dir / (config + '-gpu.txt')
        if runtime.exists():
            inspect_binary(Path(runtime.read_text()), target)
        if native:
            deployed = None
            if runtime.exists():
                gpu = Path(runtime.read_text())
                deployed = executable.parent / gpu.name
                shutil.copy2(gpu, deployed)
            subprocess.run([str(executable)], cwd=executable.parent, check=True, timeout=120)
            if deployed:
                deployed.unlink()
                subprocess.run([str(executable)], cwd=executable.parent, check=True, timeout=120)


def inspect_binary(binary, target):
    data = binary.read_bytes()
    if target == 'windows-x64':
        if data[:2] != b'MZ':
            raise RuntimeError('Expected PE binary: ' + str(binary))
        offset = struct.unpack_from('<I', data, 60)[0]
        valid = data[offset:offset + 4] == b'PE\0\0' and struct.unpack_from('<H', data, offset + 4)[0] == 0x8664
    elif target.startswith(('linux-', 'android-')):
        machine = 62 if target == 'linux-x64' else 183
        valid = data[:6] == b'\x7fELF\x02\x01' and struct.unpack_from('<H', data, 18)[0] == machine
    else:
        valid = data[:4] == b'\xcf\xfa\xed\xfe' and struct.unpack_from('<I', data, 4)[0] == 0x100000C
        found_platform = False
        offset = 32
        for _ in range(struct.unpack_from('<I', data, 16)[0]):
            command, size = struct.unpack_from('<II', data, offset)
            if command == 0x32:
                found_platform = struct.unpack_from('<I', data, offset + 8)[0] == (2 if target == 'ios-arm' else 1)
            offset += size
        valid = valid and found_platform
    if not valid:
        raise RuntimeError('Incorrect target architecture or Apple platform: ' + str(binary))
    print('Verified target binary: ' + str(binary))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--platform-name', choices=PRESETS, required=True)
    parser.add_argument('--test', action='store_true')
    args = parser.parse_args()
    temporary = Path(os.environ['TEMP_FOLDER']).resolve()
    if args.test:
        test(args.platform_name, temporary, Path(os.environ['PACKAGE_ROOT']).resolve())
    else:
        build(args.platform_name, temporary, Path(os.environ['TARGET_INSTALL_ROOT']).resolve())


if __name__ == '__main__':
    main()
