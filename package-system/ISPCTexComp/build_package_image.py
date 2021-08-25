# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root
# of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import json
import os
import pathlib
import platform
import re
import requests
import shutil
import stat
import string
import subprocess
import sys
import time

git_url = "https://github.com/GameTechDev/ISPCTextureCompressor.git"
git_commit = "36b80aac50ea401a9adde44d86712c2241b2acfd"
package_name = "ISPCTexComp"
package_version = "36b80aa-rev1"
package_url = "https://github.com/GameTechDev/ISPCTextureCompressor"
package_license = "MIT"
package_license_file = "license.txt"
cmake_find_file = "FindISPCTexComp.cmake"
source_patch_file="ISPCTexComp_36b80aa.patch"

if platform.system() == 'Linux':
    ispc_compiler_url = "https://github.com/ispc/ispc/releases/download/v1.16.1/ispc-v1.16.1-linux.tar.gz"
    ispc_compiler_install_dir = "ISPC/linux"
    ispc_compiler_package_file = "ispc-v1.16.1-linux.tar.gz"
    ispc_compiler = "ispc-v1.16.1-linux/bin/ispc"
    platform_name = "linux"
elif platform.system() == 'Darwin':
    ispc_compiler_url = "https://github.com/ispc/ispc/releases/download/v1.16.1/ispc-v1.16.1-macOS.tar.gz"
    ispc_compiler_install_dir = "ISPC/osx"
    ispc_compiler_package_file = "ispc-v1.16.1-macOS.tar.gz"
    ispc_compiler = "ispc-v1.16.1-macOS/bin/ispc"
    platform_name = "mac"
elif platform.system() == 'Windows':
    ispc_compiler_url = "https://github.com/ispc/ispc/releases/download/v1.16.1/ispc-v1.16.1-windows.zip"
    ispc_compiler_install_dir = "ISPC/win"
    ispc_compiler_package_file = "ispc-v1.16.1-windows.zip"
    ispc_compiler = "ispc-v1.16.1-windows/bin/ispc.exe"
    platform_name = "windows"

def subp_args(args):
    """
    According to subcommand, when using shell=True, its recommended not to pass in an argument list but the full command line as a single string.
    That means in the argument list in the configuration make sure to provide the proper escapements or double-quotes for paths with spaces

    :param args: The list of arguments to transform
    """
    arg_string = " ".join([arg for arg in args])
    print(f"Command: {arg_string}")
    return arg_string

def remove_readonly(func, path, _):
    "Clear the readonly bit and reattempt the removal"
    os.chmod(path, stat.S_IWRITE)
    func(path)

class IspcTexCompBuilder(object):
    def __init__(self, workingDir: pathlib.Path, packageDir: pathlib.Path):
        self.working_dir = workingDir
        self.package_dir = packageDir
        if self.working_dir.exists():
            shutil.rmtree(self.working_dir, onerror=remove_readonly)
        if self.package_dir.exists():
            shutil.rmtree(self.package_dir, onerror=remove_readonly)
        os.mkdir(self.working_dir)
        os.mkdir(self.package_dir)
        os.chdir(self.working_dir)
        self.src_folder = self.working_dir/"src"
        os.mkdir(self.src_folder)

    def clone_to_local(self):
        """
        Perform a clone to the local temp folder
        """
        print(f"Cloning {package_name} to {self.src_folder}")

        # git clone
        working_dir = str(self.src_folder.parent.absolute())
        relative_src_dir = self.src_folder.name
        clone_cmd = ['git',
                     'clone',
                     '--single-branch',
                     '--recursive',
                     git_url,
                     relative_src_dir]
        clone_result = subprocess.run(subp_args(clone_cmd),
                                      shell=True,
                                      capture_output=True,
                                      cwd=working_dir)
        if clone_result.returncode != 0:
            raise BuildError(f"Error cloning from GitHub: {clone_result.stderr.decode('UTF-8', 'ignore')}")
        
        # git checkout commit
        checkout_result = subprocess.run(
            ['git', 'checkout', git_commit],
            capture_output=True,
            cwd=self.src_folder)

        if checkout_result.returncode != 0:
            raise BuildError(f"Error checking out {self.package_info.git_commit}: {checkout_result.stderr.decode('UTF-8', 'ignore')}")

        # apply patch
        subprocess.check_output(
            ['git', 'apply', '--whitespace=fix', str(self.working_dir.parent.joinpath(source_patch_file))],
            cwd=self.src_folder,
        )

    def install_ispc_compiler(self):
        """
        Download ispc compiler and copy to source folder 
        """
        print(f"    > Downloading {ispc_compiler_url} to temp...")   
        with open(ispc_compiler_package_file, "wb") as file:
            # get request
            response = requests.get(ispc_compiler_url)
            # write to file
            file.write(response.content)

        #decompress
        print(f"    > Unzipping {ispc_compiler_package_file} to ispc folder...") 
        shutil.unpack_archive(ispc_compiler_package_file, "ispc")

        #copy the content of bin folder to install folder
        dest_folder = self.src_folder.joinpath(ispc_compiler_install_dir)
        src_file = self.working_dir.joinpath("ispc/" + ispc_compiler)
        print(f"    > Copying {src_file} to {dest_folder} folder...")
        shutil.copy(src_file, dest_folder)

    def build_windows(self):
        """
        build /ispc_texcomp/ispc_texcomp.vcxproj 
        """
        print(f"    > building for windows...")
        batch_file = self.working_dir.parent.joinpath("build_windows.bat")
        subprocess.call([str(batch_file.resolve())])
            
    def build_mac(self):
        """
        build ispc_texcomp.xcodeproj
        """
        print(f"    > building for macos...")
        os.chdir(self.src_folder)
        os.system("xcodebuild build  -scheme ispc_texcomp -project ispc_texcomp.xcodeproj -destination 'platform=macOS'")
        os.chdir(self.working_dir)
        

    def build_linux(self):
        """
        Use make -f Makefile.linux to build the ISPC Texture Compressor library
        """
        print(f"    > building for linux...")
        os.chdir(self.src_folder)
        os.system("make -f Makefile.linux")
        os.chdir(self.working_dir)
                
    def build(self):
        if platform_name == "windows":
            self.build_windows()
        elif platform_name == "linux":
            self.build_linux()
        elif platform_name == "mac":
            self.build_mac()
            
    def write_PackageInfo(self):        
        settings={
            'PackageName': f'{package_name}-{package_version}-{platform_name}',
            "URL"         : f'{package_url}',
            "License"     : f'{package_license}',
            'LicenseFile': f'{package_license_file}'
        }
        package_file = self.package_dir / 'PackageInfo.json'
        with package_file.open('w') as fh:
            json.dump(settings, fh, indent=4)

        print(f"    > file {package_file} was saved")

    def copy_output(self):
        """
        copy library files and license files to self.package_dir folder
        """
        library_foloder = self.package_dir/ package_name
        include_folder = library_foloder/'include'
        bin_folder = library_foloder/'bin'
        os.mkdir(library_foloder)
        os.mkdir(include_folder)
        os.mkdir(include_folder/'ISPC')
        # copy header files
        os.mkdir(bin_folder)
        shutil.copy2(
            src=self.src_folder /'ispc_texcomp/ispc_texcomp.h',
            dst=include_folder/'ISPC',
        )
        # copy library files        
        if platform_name == "windows":
            shutil.copy2(
                src=self.src_folder /'ispc_texcomp/x64/Release/ispc_texcomp.dll',
                dst=bin_folder,
            )
            shutil.copy2(
                src=self.src_folder /'ispc_texcomp/x64/Release/ispc_texcomp.lib',
                dst=bin_folder,
            )
        elif platform_name == "linux":
            shutil.copy2(
                src=self.src_folder /'build/libispc_texcomp.so',
                dst=bin_folder,
            )
        elif platform_name == "mac":
            shutil.copy2(
                src=self.src_folder /'build/libispc_texcomp.dylib',
                dst=bin_folder,
            )

        # copy license file
        shutil.copy2(
            src=self.src_folder / 'license.txt',
            dst=self.package_dir,
        )

        #copy find package cmake
        shutil.copy2(
            src= self.working_dir.parent.joinpath(cmake_find_file),
            dst=self.package_dir,
        )

        # write package info
        self.write_PackageInfo()

def main():
    working_folder = pathlib.Path(os.getcwd()+"/temp")
    package_folder = pathlib.Path(os.getcwd()).parent.joinpath(f'{package_name}-{platform_name}')
    print(f"    > Build ISPCTexComp Package from {working_folder} and saving to {package_folder}")

    builder = IspcTexCompBuilder(working_folder, package_folder)

    builder.clone_to_local()
    builder.install_ispc_compiler()
    builder.build()
    builder.copy_output()

    print(f"    > Build {package_name} Package complete")

    return True

if __name__ == '__main__':

    start = time.time()

    result = main()

    elapsed = time.time() - start
    hour = int(elapsed // 3600)
    minute = int((elapsed - 3600*hour) // 60)
    seconds = int((elapsed - 3600*hour - 60*minute))
    
    print(f'    > Total time {hour}:{minute:02d}:{seconds:02d}')

    if result:
        exit(0)
    else:
        exit(1)
