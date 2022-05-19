#!/usr/bin/env python3

#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

'''
Builds a version of OpenImageIO and OpenColorIO that include python bindings.
The two libraries (OpenImageIO and OpenColorIO, aka oiio and ocio) are inter-dependent on each other
so need to be built in a special sequence, some modules from each first, then some more modules from
each after that.

Notably, this script will build and fetch dependencies as needed, but is stricly limited to the
supported set that works for Open 3D Engine.  

Notably, the following features are DISABLED and will n ot be present:
 - Camera RAW support
 - The image viewer application 'iv'
 - Jpeg2000 support
 - ffmpeg and any other potentially troublesome patent-laden components
 - OpenCV
 - WebP
 - OpenVDB
 - GIF
 - HEIV/AVIF
 - DICOM / DCMTK
 - Ptex
 - Field3D

All of the above could get added support if necessary - it would involve updating the build
script here to handle the dependent libs and also ensuring that their licenses are compatible and
that there is no patent danger.
'''

import argparse
import json
import os
import platform
import subprocess
import sys
import pathlib
import shutil


openimageio_repository_url = 'https://github.com/OpenImageIO/oiio.git'
openimageio_repository_tag = 'v2.3.12.0'

opencolorio_repository_url='https://github.com/AcademySoftwareFoundation/OpenColorIO.git'
opencolorio_repository_tag='v2.1.1'

boost_repository_url = 'https://github.com/boostorg/boost.git'
boost_repository_tag = 'boost-1.76.0' 

libjpegturbo_repository_url ='https://github.com/libjpeg-turbo/libjpeg-turbo.git'
libjpegturbo_repository_tag = '2.1.2'

temp_folder_name = 'temp'
source_folder_name = 'src'
build_folder_name = 'bld'

# the following are used for debugging and skip steps.
# do not approve a pull request if they are not set to FALSE / None.
SKIP_OPENCOLORIO = False
SKIP_BOOST = False
SKIP_LIBJPEGTURBO = False
SKIP_OPENIMAGEIO = False
SKIP_OPENCOLORIO_WITH_OPENIMAGEIO = False

dependencies = {
    # dependencies format:
    # platformname : 
    #          package_short_name : (packagename,  hashe)
    'darwin' :
        {
            'zlib' :     ('zlib-1.2.11-rev5-mac',              'b6fea9c79b8bf106d4703b67fecaa133f832ad28696c2ceef45fb5f20013c096'),
            'openexr' :  ('OpenEXR-3.1.3-rev4-mac',            '927b8ca6cc5815fa8ee4efe6ea2845487cba2540f7958d537692e7c9481a68fc'),
            'python' :   ('python-3.7.12-rev2-darwin',         'ee4b77a907e08e3f3e6a08ea6418e8c083c78c20d264b4bc055e50d0db512001'),
            'tiff' :     ('tiff-4.2.0.15-rev3-mac',            'c2615ccdadcc0e1d6c5ed61e5965c4d3a82193d206591b79b805c3b3ff35a4bf'),
            'libpng' :   ('png-1.6.37-rev2-mac',               '515252226a6958c459f53d8598d80ec4f90df33d2f1637104fd1a636f4962f07'),
            'expat' :    ('expat-2.4.2-rev2-mac',              '70f195977a17b08a4dc8687400fd7f2589e3b414d4961b562129166965b6f658'),
            'freetype' : ('freetype-2.11.1-rev1-mac',          'b66107d3499f2e9c072bd88db26e0e5c1b8013128699393c6a8495afca3d2548')
        },
    'windows' :
        {
            'zlib' :     ('zlib-1.2.11-rev5-windows',          '8847112429744eb11d92c44026fc5fc53caa4a06709382b5f13978f3c26c4cbd'),
            'openexr' :  ('OpenEXR-3.1.3-rev4-windows',        'c850268e849171751cdaefdab1952333ac38afbb771b999e99d67f9761706d98'),
            'python' :   ('python-3.7.12-rev2-windows',        '1173d886f6192f57b9cafb225fe679e2781f4a40a89f4bb31ee81d2b7fcad632'),
            'tiff' :     ('tiff-4.2.0.15-rev3-windows',        'c6000a906e6d2a0816b652e93dfbeab41c9ed73cdd5a613acd53e553d0510b60'),
            'libpng' :   ('png-1.6.37-rev2-windows',           'e16539a0fff26ac9ef80dd11ef0103eca91745519eacd41d41d96911c173589f'),
            'expat' :    ('expat-2.4.2-rev2-windows',          '748d08f21f5339757059a7887e72b52d15e954c549245c638b0b05bd5961e307'),
            'freetype' : ('freetype-2.11.1-rev1-windows',      '861d059a5542cb8f58a5157f411eee2e78f69ac72e45117227ebe400efe49f61')
        },
    'linux' :
        {
            'zlib' :     ('zlib-1.2.11-rev5-linux',            '9be5ea85722fc27a8645a9c8a812669d107c68e6baa2ca0740872eaeb6a8b0fc'),
            'openexr' :  ('OpenEXR-3.1.3-rev4-linux',          'fcbac68cfb4e3b694580bc3741443e111aced5f08fde21a92e0c768e8803c7af'),
            'python' :   ('python-3.7.12-rev2-linux',          '04ae255f22a6f0529cf07108aef68f8aee8c76cd551dde70f1c90731ebf0b7b4'),
            'tiff' :     ('tiff-4.2.0.15-rev3-linux',          '2377f48b2ebc2d1628d9f65186c881544c92891312abe478a20d10b85877409a'),
            'libpng' :   ('png-1.6.37-rev2-linux',             '5c82945a1648905a5c4c5cee30dfb53a01618da1bf58d489610636c7ade5adf5'),
            'expat' :    ('expat-2.4.2-rev2-linux',            '755369a919e744b9b3f835d1acc684f02e43987832ad4a1c0b6bbf884e6cd45b'),
            'freetype' : ('freetype-2.11.1-rev1-linux',        '28bbb850590507eff85154604787881ead6780e6eeee9e71ed09cd1d48d85983')
        }
}

script_folder = pathlib.Path(__file__).parent.absolute()
temp_folder_path = script_folder / temp_folder_name
build_folder_path = temp_folder_path / build_folder_name
source_folder_path = temp_folder_path / source_folder_name
repo_root_path = script_folder.parent.parent
general_scripts_path = repo_root_path / 'Scripts' / 'extras'
dependencies_folder_path = (temp_folder_path / 'dependencies').absolute().resolve()
ocio_install_path = temp_folder_path / 'ocio_install'
yamlcpp_install_path =  temp_folder_path / 'yaml-cpp_install'
boost_install_path = temp_folder_path / 'boost_install'
oiio_install_path = temp_folder_path / 'oiio_install'
libjpegturbo_install_path = temp_folder_path / 'libjpegturbo_install'
test_script_folder = script_folder / 'test'

sys.path.insert(1, str(general_scripts_path.absolute().resolve()) )

from package_downloader import PackageDownloader

def exec_and_exit_if_failed(invoke_params, cwd=script_folder, shell=False):
    # thin wrapper around subprocess.run, 
    # includes output tracing and also allows non-str params to be entered (such as pathlib)
    # without issue.  Otherwise things like str.join may fail
    invoke_params = [str(x) for x in invoke_params] 
    cwd = str(cwd)
    friendly_args = ' '.join(invoke_params)
    print('Exec:')
    print(f'   CMDLINE: {friendly_args}')
    print(f'       CWD: {cwd}')
    print(f'     SHELL: {shell}')
    print('Output:')
    if shell and args.platform != "windows": # for shell invocations on non-windows, join it all
        invoke_params = [friendly_args]
    result_value = subprocess.run(invoke_params, shell=shell, cwd=cwd)
    if result_value.returncode != 0:
        print(f"Exec: Failed with return code {result_value}")
        sys.exit(0)
    return result_value.returncode

# only clones the repo if it doesn't exist.  Otherwise cleans it.
def clone_repo(url, tag, dest_folder):
    if pathlib.Path(dest_folder).exists():
        print(f"Not re-cloning {url} to {dest_folder} becuase it already exists (use --clean to clean fully)")
        exec_and_exit_if_failed(['git', 'clean', '-f'], cwd=dest_folder)
        exec_and_exit_if_failed(['git', 'restore', '.'], cwd=dest_folder)
    else:
        exec_and_exit_if_failed(['git', 'clone', '--depth=1', '--single-branch', '--depth=1', '--recursive',
              '-b', tag,   
              url,
              dest_folder
              ])

    exec_and_exit_if_failed(['git', 'submodule', 'update', '--init', '--recursive'], cwd=dest_folder)

def get_dependencies(deps):
    for dependency in deps:
        packagename, hash = deps[dependency]
        if not (dependencies_folder_path / packagename).exists():
            if not PackageDownloader.DownloadAndUnpackPackage(packagename, hash, str(dependencies_folder_path)):
                raise Exception("Failed to build!")
        else:
            print(f'{packagename} already in dependencies folder, skipping. Use --clean to refresh')

def get_dependency_path(platform, depname):
    dependencies_package_name = dependencies[platform][depname][0]
    return (dependencies_folder_path / dependencies_package_name).absolute().resolve()

# ------------------------------------ MAIN SCRIPT STARTS HERE ----------------------------------------------

parser = argparse.ArgumentParser(description='Builds this package')
parser.add_argument('--platform', default=platform.system().lower(), required=False, help=f'Platform to build (defaults to \"{platform.system().lower()}\")')
parser.add_argument('--clean',    action='store_true',               required=False, help=f'Complete clean build, if true, will delete entire temp and refetch dependencies')

args = parser.parse_args()
if args.platform not in dependencies.keys():
    print(f"Platform {args.platform} not in the list of supported dependency platforms {dependencies.keys()}")
    sys.exit(1)

# We build the python bindings for OpenImageIO and OpenColorIO against our
# python-3.7.12 dependency, so if a different version of python runs this build
# script, the test at the end which attempts to import the built python bindings
# will fail, so we need to make sure the same version of python is running
# this build script.
expected_python_version = '3.7.12'
if not sys.version.startswith(expected_python_version):
    print(f"Error: Build script needs to be run with python version {expected_python_version}, current version is {sys.version}")
    sys.exit(1)

# Make sure the system has the nasm library installed before proceeding (linux/darwin only)
if args.platform != "windows":
    result = exec_and_exit_if_failed(['nasm', '-v'])
    if result != 0:
        print("Missing nasm install on system")
        if args.platform == "darwin":
            print("Please run: 'brew install nasm' and then try build again")
        else:
            print("Please run: 'apt install nasm' and then try build again")

# similar to CMAKE, we define these as blank or filled depending on platform.
lib_prefix = ''
if args.platform.lower() == 'windows':
    lib_suffix = '.lib'
else:
    lib_suffix = '.a'
    lib_prefix = 'lib'

# Determine our final package output path now since we
# use the platform as a suffix
final_package_image_root = temp_folder_path / f'package-{args.platform}'

print(f"OpenImageIO / OpenColorIO Build Script")
print(f"Script folder : {script_folder.relative_to(repo_root_path)}")
print(f"Temp folder   : {temp_folder_path.relative_to(repo_root_path)}")
print(f"Build folder  : {build_folder_path.relative_to(repo_root_path)}")
print(f"Source folder : {source_folder_path.relative_to(repo_root_path)}")
print(f"Dependencies  : {dependencies_folder_path.relative_to(repo_root_path)}")
print(f"Platform      : {args.platform}")
print(f"ocio install  : {ocio_install_path}")
print(f"boost install : {boost_install_path}")
print(f"oiio install  : {oiio_install_path}")
print(f"jpg install   : {libjpegturbo_install_path}")
print(f"final package : {final_package_image_root}")

print("\n---------------------------------- CLEANING ----------------------------------")

if args.clean:
    if temp_folder_path.exists():
        print(f'\n--clean specified on command line - removing entire temp folder: {temp_folder_path}...')
        shutil.rmtree(str(temp_folder_path.resolve()), ignore_errors=True)
else:
    print('\n--clean not specified on the command line.\nWill only clean build folders, not source or installs')

os.makedirs(str(temp_folder_path), exist_ok=True)
os.makedirs(str(build_folder_path), exist_ok=True)
os.makedirs(str(source_folder_path), exist_ok=True)

print("\n----------------------------- FETCH Dependencies -----------------------------")
get_dependencies(dependencies[args.platform])

# we can re-use this path string (semicolon seperated list of folders) for all finds.
# use posix paths here so that the cmake configure doesn't get confused by different
# path separators on windows
module_path_string = ';'.join( [ 
        f'{get_dependency_path(args.platform, "openexr").as_posix()}',
        f'{get_dependency_path(args.platform, "expat").as_posix()}',
        f'{get_dependency_path(args.platform, "zlib").as_posix()}',
        f'{get_dependency_path(args.platform, "tiff").as_posix()}',
        f'{get_dependency_path(args.platform, "libpng").as_posix()}',
        f'{get_dependency_path(args.platform, "freetype").as_posix()}',
        # add a custom path for our custom find modules:
])

# Our python dependency needs to be on the PATH on Windows,
# or else one of the sub-dependencies (pystring) will fail
# to find python even with the python build arguments
# that we setup further down
python_root = get_dependency_path(args.platform, "python")
if args.platform == "windows":
    python_root /= "python"
    os.environ["PATH"] = f"{str(python_root.absolute().resolve())};{os.environ['PATH']}"

# building opencolorIO is a function becuase we call it twice
# once before we have OpenImageIO built, and once again with that dependency ready
def BuildOpenColorIO(module_paths_to_use):
    clone_repo(opencolorio_repository_url, opencolorio_repository_tag, source_folder_path / 'opencolorio')
    opencolorio_build_folder = build_folder_path / 'opencolorio_build'

    if opencolorio_build_folder.exists():
        shutil.rmtree(str(opencolorio_build_folder.resolve()), ignore_errors=True)

    opencolorio_configure_command = [ 
                'cmake',
                f'-S',
                f'{source_folder_path / "opencolorio"}',
                f'-B',
                f'{opencolorio_build_folder}',
                f'-Dexpat_STATIC_LIBRARY=ON',
                f'-DCMAKE_INSTALL_PREFIX={ocio_install_path}',
                f'-DCMAKE_BUILD_TYPE=Release',
                f'-DBUILD_SHARED_LIBS=OFF',
                f'-DCMAKE_CXX_STANDARD=17',
                f'-DOCIO_BUILD_APPS=ON',
                f'-DOCIO_BUILD_OPENFX=OFF',
                f'-DOCIO_BUILD_TESTS=OFF',
                f'-DOCIO_BUILD_GPU_TESTS=OFF',
                f'-DOCIO_BUILD_PYTHON=ON',
                f'-DCMAKE_CXX_VISIBILITY_PRESET=hidden',
                f'-DOCIO_BUILD_DOCS=OFF',   # <---- TODO: we have to fix this maybe
                f'-DCMAKE_MODULE_PATH={module_paths_to_use}',
                
    ]

    # We want to use ninja on both darwin and linux
    if args.platform != "windows":
        opencolorio_configure_command += [
            '-G', 'Ninja'
        ]

    if args.platform == "darwin":
        opencolorio_configure_command += [
            f'-DCMAKE_TOOLCHAIN_FILE={repo_root_path / "Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"}'
        ]
    elif args.platform == "windows":
        # Without this on windows we get a linker error: png_LIBRARY-NOTFOUND
        opencolorio_configure_command += [
            f'-Dpng_LIBRARY={get_dependency_path(args.platform, "libpng") / "png" / "lib" / "libpng16_static.lib"}'
        ]

    # Add python-specific configure args
    python_root = get_dependency_path(args.platform, "python")
    if args.platform == "windows":
        python_root /= "python"
        python_lib = python_root / "libs" / "python37.lib"
        python_include = python_root / "include"
        python_exe = python_root / "python.exe"

        opencolorio_configure_command += [
            f'-DPython_LIBRARY={python_lib}',
            f'-DPython_INCLUDE_DIR={python_include}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]
    elif args.platform == "darwin":
        python_root /= "Python.framework/Versions/3.7"
        python_exe = python_root / "bin/Python3"

        opencolorio_configure_command += [
            f'-DPython_ROOT={python_root}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]
    else: # linux
        python_root /= "python"
        python_exe = python_root / "bin/python3"

        opencolorio_configure_command += [
            f'-DPython_ROOT={python_root}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]

    exec_and_exit_if_failed(opencolorio_configure_command)

    opencolorio_build_command = [
        f'cmake',
        f'--build',
        f'{opencolorio_build_folder}',
        f'--parallel',
        f'--config',
        f'Release',
        f'--target',
        f'install'
    ]
    exec_and_exit_if_failed(opencolorio_build_command)

    # opencolorio built statically only installs its own files, none of its dependencies
    # we need to actually also deploy its dependencies, namely
    # pystring::pystring
    # yaml-cpp (note, no namespace!)

    yaml_lib = "yaml-cpp"
    if args.platform == "windows":
        yaml_lib = "libyaml-cppmd"

    ocio_private_library_build_path = build_folder_path / 'opencolorio_build' / 'ext' / 'dist' / 'lib'
    ocio_private_libary_source_path = build_folder_path / 'opencolorio_build' / 'ext' / 'build'
    pystring_source_path =  ocio_private_libary_source_path / 'pystring' / 'src' / 'pystring_install'
    yamlcpp_source_path =   ocio_private_libary_source_path / 'yaml-cpp' / 'src' / 'yaml-cpp_install'
    pystring_install_path = temp_folder_path / 'pystring_install'
    os.makedirs(pystring_install_path / 'lib', exist_ok=True)
    os.makedirs(yamlcpp_install_path  / 'lib', exist_ok=True)
    shutil.copy2(ocio_private_library_build_path / f'{lib_prefix}pystring{lib_suffix}', pystring_install_path / 'lib' / f'{lib_prefix}pystring{lib_suffix}', follow_symlinks=False)
    shutil.copy2(ocio_private_library_build_path / f'{lib_prefix}{yaml_lib}{lib_suffix}', yamlcpp_install_path /  'lib' / f'{lib_prefix}{yaml_lib}{lib_suffix}', follow_symlinks=False)
    shutil.copy2(pystring_source_path / 'LICENSE', pystring_install_path / 'LICENSE', follow_symlinks=False)
    shutil.copy2(yamlcpp_source_path  / 'LICENSE', yamlcpp_install_path  / 'LICENSE', follow_symlinks=False)

if not SKIP_OPENCOLORIO:
    print("\n----------------------------- BUILD OpenColorIO ------------------------------")

    BuildOpenColorIO(module_path_string)
# the final install of OpenColorIO looks like this
# (install folder)
#       - bin
#          (various programs)
#       - lib
#           - cmake
#               (the cmake files that define the target)
#           - pkgconfig
#           - python3.7/site-packages
#                 - PyOpenColorIO.so
#           libOpenColorIO.a
#           libOpenColorIOoglapphelpers.a
#           libpystring.a
#           libyaml-cpp.a

# now that we have openColorIO we can make openImageIO which uses it
# then we can circle back into openColorIO and make any apps it was missing.
if not SKIP_BOOST:
    print("\n-------------------------------- BUILD BOOST ---------------------------------")

    boost_build_folder = build_folder_path / 'boost'
    if boost_build_folder.exists():
        shutil.rmtree(str(boost_build_folder.resolve()), ignore_errors=True)

    clone_repo(boost_repository_url, boost_repository_tag, source_folder_path / 'boost')

    # Use the right bootstrap script for windows/*nix
    if args.platform == "windows":
        bootstrap_script = "bootstrap.bat"
        build_b2 = "b2.exe"
    else:
        bootstrap_script = "./bootstrap.sh"
        build_b2 = "./b2"

    exec_and_exit_if_failed([bootstrap_script, '--with-libraries=filesystem,atomic,thread,system,headers,date_time,chrono'],
                            cwd=source_folder_path / 'boost', shell=True)

    boost_build_command = [build_b2,
                            f'--build-dir={boost_build_folder}',
                            f'link=static', 
                            f'threading=multi', 
                            f'--prefix={boost_install_path}', 
                            f'release',
                            f'install',
                            f'visibility=hidden',
                            f'-j', '12']

    # on non-windows, make sure that the same visibility is set for building the library
    # as will be likely set for applications where it is used as a dependency.
    if args.platform.lower() != 'windows':
        print("(Using hidden visibility by default)")
        boost_build_command += ['cflags=-fPIC',
            'cxxflags=-fvisibility=hidden',
            'cxxflags=-fvisibility-inlines-hidden',
            'cxxflags=-fPIC'
        ]

    exec_and_exit_if_failed(boost_build_command, cwd=source_folder_path / 'boost', shell=True)

    # boost is now built, and lives in temp/bld/boost/output (which contains the usual lib, include, etc)

if not SKIP_LIBJPEGTURBO:
    print("\n---------------------------- BUILD libJPEGTurbo ------------------------------")
    clone_repo(libjpegturbo_repository_url, libjpegturbo_repository_tag, source_folder_path / 'libjpegturbo')

    libjpegturbo_build_path = build_folder_path / 'libjpegturbo_build'
    if libjpegturbo_build_path.exists():
        shutil.rmtree(str(libjpegturbo_build_path.resolve()), ignore_errors=True)

    libjpegturbo_configure_command = [ 
        'cmake',
        f'-S',
        f'{source_folder_path / "libjpegturbo"}',
        f'-B',
        libjpegturbo_build_path,
        f'-DCMAKE_INSTALL_PREFIX={libjpegturbo_install_path}',
        f'-DCMAKE_BUILD_TYPE=Release',
        f'-DBUILD_SHARED_LIBS=OFF',
        f'-DENABLE_SHARED=OFF',
        f'-DWITH_JAVA=0',
        f'-DCMAKE_POSITION_INDEPENDENT_CODE=ON',
        f'-DCMAKE_CXX_STANDARD=17',
        f'-DPYTHON_VERSION=3.7.12',
        f'-DCMAKE_CXX_VISIBILITY_PRESET=hidden',
        f'-DCMAKE_MODULE_PATH={module_path_string}'
    ]

    # We want to use ninja on both darwin and linux
    if args.platform != "windows":
        libjpegturbo_configure_command += [
            '-G', 'Ninja'
        ]

    if args.platform == "darwin":
        libjpegturbo_configure_command += [
            f'-DCMAKE_TOOLCHAIN_FILE={repo_root_path / "Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"}'
        ]

    exec_and_exit_if_failed(libjpegturbo_configure_command)

    libjpegturbo_build_command = [
        f'cmake',
        f'--build',
        libjpegturbo_build_path,
        f'--parallel',
        f'--config',
        f'Release',
        f'--target',
        f'install'
    ]

    exec_and_exit_if_failed(libjpegturbo_build_command)

# add our custom find files here, not earlier - we only want to use these custom find files
# in compiling OpenImageIO and etc.
module_path_string_with_custom_find_files = module_path_string + f';{(script_folder / "custom_find_files").as_posix()}'

if not SKIP_OPENIMAGEIO:
    print("\n----------------------------- BUILD OpenImageIO ------------------------------")

    clone_repo(openimageio_repository_url, openimageio_repository_tag, source_folder_path / 'openimageio')

    openimageio_build_folder = build_folder_path / 'openimageio_build'
    if openimageio_build_folder.exists():
        shutil.rmtree(str(openimageio_build_folder.resolve()), ignore_errors=True)

    # openimageio looks for OpenColorIO in a way that is not compatible with generated configs.
    # remove its find file, allow it to just use the OpenColorIO_ROOT:
    os.remove(source_folder_path / 'openimageio' / 'src' / 'cmake' / 'modules' / 'FindOpenColorIO.cmake' )
 
    # note that we have to clear the install folder for this to actually work as 
    # otherwise it might try to add RPATHS to existing files.
    shutil.rmtree(oiio_install_path, ignore_errors=True)

    openimageio_configure_command = [ 
        'cmake',
        f'-S',
        f'{source_folder_path / "openimageio"}',
        f'-B',
        openimageio_build_folder,
        f'-DUSE_PYTHON=ON',
        f'-DBoost_ROOT={boost_install_path}',
        f'-Dpybind11_ROOT={temp_folder_path / "bld/opencolorio_build/ext/dist"}',  #use pybind from the opencolorio build
        f'-DJPEG_ROOT={libjpegturbo_install_path}',
        f'-DJPEGTurbo_ROOT={libjpegturbo_install_path}',
        f'-DCMAKE_INSTALL_PREFIX={oiio_install_path}',
        f'-DPNG_ROOT={get_dependency_path(args.platform, "libpng") / "libpng"}',
        f'-DCMAKE_BUILD_TYPE=Release',
        f'-DBUILD_SHARED_LIBS=OFF',
        f'-DCMAKE_CXX_STANDARD=17',
        f'-DPYTHON_VERSION=3.7.12',
        f'-DOIIO_BUILD_TESTS=OFF',
        f'-DLINKSTATIC=ON',
        f'-DCMAKE_CXX_VISIBILITY_PRESET=hidden',
        f'-DUSE_OpenGL=OFF',
        f'-DUSE_Qt5=OFF',
        f'-DUSE_BZip2=OFF',
        f'-DCMAKE_MODULE_PATH={module_path_string_with_custom_find_files}',
        f'-DVERBOSE=ON' # reveals problems with library inclusion
    ]

    # We want to use ninja on both darwin and linux
    if args.platform != "windows":
        openimageio_configure_command += [
            '-G', 'Ninja'
        ]

    if args.platform == "darwin":
        openimageio_configure_command += [
            f'-DCMAKE_TOOLCHAIN_FILE={repo_root_path / "Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"}'
        ]
    elif args.platform == "windows":
        # Without this on windows we get a linker error: yaml_cpp_LIBRARY-NOTFOUND
        openimageio_configure_command += [
            f'-Dyaml_cpp_LIBRARY={yamlcpp_install_path / "lib" / "libyaml-cppmd.lib"}'
        ]

    # Add python-specific configure args
    python_root = get_dependency_path(args.platform, "python")
    if args.platform == "windows":
        python_root /= "python"
        python_lib = python_root / "libs" / "python37.lib"
        python_include = python_root / "include"
        python_exe = python_root / "python.exe"

        openimageio_configure_command += [
            f'-DPython_LIBRARY={python_lib}',
            f'-DPython_INCLUDE_DIR={python_include}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]
    elif args.platform == "darwin":
        python_root /= "Python.framework/Versions/3.7"
        python_exe = python_root / "bin/Python3"

        openimageio_configure_command += [
            f'-DPython_ROOT={python_root}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]
    else: # linux
        python_root /= "python"
        python_exe = python_root / "bin/python3"

        openimageio_configure_command += [
            f'-DPython_ROOT={python_root}',
            f'-DPython_EXECUTABLE={python_exe}'
        ]

    exec_and_exit_if_failed(openimageio_configure_command)

    openimageio_build_command = [
            f'cmake',
            f'--build',
            openimageio_build_folder,
            f'--parallel',
            f'--config',
            f'Release',
            f'--target',
            f'install'
        ]

    exec_and_exit_if_failed(openimageio_build_command)

# ----------------- BUILD OpenColorIO again but this time with OpenImageIO support ----------------
if not SKIP_OPENCOLORIO_WITH_OPENIMAGEIO:
    print("\n------------------ BUILD OpenColorIO with OpenImageIO support ----------------")
    BuildOpenColorIO(module_path_string_with_custom_find_files)
# -------------------------------- Make final installation image --------------------------------------
# note that we will have to include static libs for things like boost, other deps.
# and make a FIND FILE that declares openimageio depending on opencolorio
# as well as on the various 3p libs that it requires.

print("\n------------------------- Create final package image -------------------------")

private_deps_folder = final_package_image_root / 'privatedeps'
print("Cleaning previous package folder...")
shutil.rmtree(final_package_image_root, ignore_errors=True)
os.makedirs(final_package_image_root, exist_ok=True)
os.makedirs(private_deps_folder, exist_ok=True)

print("Copying OpenImageIO")
shutil.copytree(src=oiio_install_path, dst=final_package_image_root / 'OpenImageIO')
shutil.copy2(src=script_folder / 'distribution' / 'FindOpenImageIO.cmake', dst=final_package_image_root / 'FindOpenImageIO.cmake')

print("Copying OpenColorIO")
shutil.copytree(src=ocio_install_path, dst=final_package_image_root / 'OpenColorIO')
shutil.copy2(src=script_folder / 'distribution' / 'FindOpenColorIO.cmake', dst=final_package_image_root / 'FindOpenColorIO.cmake')

# the following are considered private dependencies, do not depend on them!
print("Copying LibJPEGTurbo")
shutil.copytree(src=libjpegturbo_install_path, dst=private_deps_folder / 'LibJPEGTurbo')
print("Copying Boost")
shutil.copytree(src=boost_install_path, dst=private_deps_folder / 'Boost')
print("Copying pystring")
shutil.copytree(src=temp_folder_path / 'pystring_install', dst=private_deps_folder / 'pystring')
print("Copying yaml-cpp")
shutil.copytree(src=temp_folder_path / 'yaml-cpp_install', dst=private_deps_folder / 'yaml-cpp')

print("Cleaning unnecessary/private files")
# we don't actually want to expose this copy of boost as being something people can use
# and the OpenImageIO library doesn't expose any boost usage in its public API, so we can remove all the headers.
# note that we delete the cmake and pkgconfig files since they contain absolute paths to the machine
# that they were built on, and won't be useful anyway
# Ignore errors when removing the pkgconfig folders since they won't be present on windows
shutil.rmtree(path=private_deps_folder / 'Boost' / 'include')
shutil.rmtree(path=private_deps_folder / 'Boost' / 'lib' / 'cmake')
shutil.rmtree(path=private_deps_folder / 'LibJPEGTurbo' / 'include')
shutil.rmtree(path=private_deps_folder / 'LibJPEGTurbo' / 'bin')
shutil.rmtree(path=private_deps_folder / 'LibJPEGTurbo' / 'lib' / 'cmake')
shutil.rmtree(path=private_deps_folder / 'LibJPEGTurbo' / 'lib' / 'pkgconfig', ignore_errors=True)
shutil.rmtree(path=final_package_image_root / 'OpenColorIO' / 'lib' / 'pkgconfig', ignore_errors=True)
shutil.rmtree(path=final_package_image_root / 'OpenColorIO' / 'lib' / 'cmake')
shutil.rmtree(path=final_package_image_root / 'OpenColorIO' / 'share')

shutil.rmtree(path=final_package_image_root / 'OpenImageIO' / 'lib' / 'pkgconfig', ignore_errors=True)
shutil.rmtree(path=final_package_image_root / 'OpenImageIO' / 'lib' / 'cmake')

# Generate our PackageInfo.json dynamically for the platform, and pretty
# print the JSON so that it's human readable
print("Generating PackageInfo.json")
platform_name = args.platform.lower()
if platform_name == "darwin":
    platform_name = "mac" # Our convention in the package list is to use mac
package_info = {
    "PackageName" : f"openimageio-opencolorio-2.3.12.0-{platform_name}",
    "URL"         : "https://github.com/OpenImageIO/oiio and https://opencolorio.org/",
    "License"     : "BSD-3-Clause",
    "LicenseFile" : "LICENSE.TXT"
}
package_info_file = open(final_package_image_root / 'PackageInfo.json', "w")
pretty_json = json.dumps(package_info, indent=4)
package_info_file.write(pretty_json)
package_info_file.close()

print("Copying License and package files")
shutil.copy2(src=script_folder / 'distribution' / 'LICENSE.TXT', dst=final_package_image_root / 'LICENSE.TXT')
# note that we're copying the distribution license, ie, the one that goes with the package, not the
# license thats in THIS repo, to the root of the built package.
# we also have to include other license files when the install step for the package doesn't do it themselves
shutil.copy2(src=source_folder_path / 'opencolorio' / 'LICENSE', dst=final_package_image_root / 'OpenColorIO' / 'LICENSE')
shutil.copy2(src=source_folder_path / 'opencolorio' / 'THIRD-PARTY.md', dst=final_package_image_root / 'OpenColorIO' / 'THIRD-PARTY.md')
shutil.copy2(src=source_folder_path / 'boost' / 'LICENSE_1_0.txt', dst=private_deps_folder / 'Boost' / 'LICENSE_1_0.txt')
shutil.copy2(src=source_folder_path / 'boost' / 'README.md', dst=private_deps_folder / 'Boost' / 'README.md')
shutil.copy2(src=private_deps_folder / 'LibJPEGTurbo' / 'share' / 'doc' / 'libjpeg-turbo' / 'LICENSE.md', dst=private_deps_folder / 'LibJPEGTurbo' / 'LICENSE.md')

print("\n----------------------------- Test package image -----------------------------")

module_path_string_with_package_folder = module_path_string + f';{final_package_image_root.as_posix()}'

test_build_folder = build_folder_path / 'test_openimageio'

if test_build_folder.exists():
    shutil.rmtree(str(test_build_folder.resolve()), ignore_errors=True)

test_configure_command = [ 
    'cmake',
    f'-S',
    f'{script_folder / "test"}',
    f'-B',
    test_build_folder,
    f'-DCMAKE_BUILD_TYPE=Release',
    f'-DCMAKE_CXX_STANDARD=17',
    f'-DCMAKE_CXX_VISIBILITY_PRESET=hidden',
    f'-DCMAKE_MODULE_PATH={module_path_string_with_package_folder}',
]

# We want to use ninja on both darwin and linux
if args.platform != "windows":
    test_configure_command += [
        '-G', 'Ninja'
    ]

if args.platform == "darwin":
    test_configure_command += [
        f'-DCMAKE_TOOLCHAIN_FILE={repo_root_path / "Scripts/cmake/Platform/Mac/Toolchain_mac.cmake"}'
    ]

exec_and_exit_if_failed(test_configure_command)

test_build_command = [
        f'cmake',
        f'--build',
        test_build_folder,
        f'--parallel',
        f'--config',
        f'Release',
    ]

exec_and_exit_if_failed(test_build_command)

test_executable_path = ''
if args.platform == 'darwin':
    test_executable_path = test_build_folder / 'test_OpenImageIO.app' / 'Contents' / 'MacOS' / 'test_OpenImageIO'
elif args.platform == 'windows':
    test_executable_path = test_build_folder / 'Release' / 'test_OpenImageIO.exe'
else:
    test_executable_path = test_build_folder / 'test_OpenImageIO'


test_exec_command = [
    test_executable_path
]

exec_and_exit_if_failed(test_exec_command, cwd=test_script_folder)

# Test the OIIO and OCIO python libraries
oiio_site_packages = final_package_image_root / 'OpenImageIO' / 'lib' / 'python3.7' / 'site-packages'
if args.platform == 'windows':
    ocio_site_packages = final_package_image_root / 'OpenColorIO' / 'lib' / 'site-packages'
else:
    ocio_site_packages = final_package_image_root / 'OpenColorIO' / 'lib' / 'python3.7' / 'site-packages'

# Insert our site-packages folders with the pyds into the sys.path so that the test can
# import from them, as well as our actual test scripts folder so we can import the tests
sys.path.insert(1, str(test_script_folder.absolute().resolve()))
sys.path.insert(1, str(oiio_site_packages.absolute().resolve()))
sys.path.insert(1, str(ocio_site_packages.absolute().resolve()))
from python_tests import test_OpenImageIO, test_OpenColorIO

if not test_OpenImageIO():
    print("OpenImageIO python test failed")
    exit(-1)

if not test_OpenColorIO():
    print("OpenColorIO python test failed")
    exit(-1)

print(f"Build and test complete!  Folder image created in {final_package_image_root}")
