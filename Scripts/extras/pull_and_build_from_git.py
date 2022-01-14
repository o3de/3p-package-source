#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse
import fnmatch
import glob
import json
import os
import pathlib
import platform
import re
import shutil
import string
import subprocess
import sys

from package_downloader import PackageDownloader

SCHEMA_DESCRIPTION = """
Build Config Description:

The build configuration (build_config.json) accepts keys that are root level only, and some keys that can be 
either global or target platform specific. Root level only keys are keys that define the project and cannot
be different by platform, and all are required. The keys are:

* package_name          : The base name of the package, used for constructing the filename and folder structures
* package_url           : The package url that will be placed in the PackageInfo.json
* package_license       : The type of license that will be described in the PackageInfo.json
* package_license_file  : The name of the source code license file (expected at the root of the source folder pulled from git)

The following keys can exist at the root level or the target-platform level:

* git_url               : The git clone url for the source to pull for building
* git_tag               : The git tag or branch to identify the branch to pull from for building
* git_commit            : (optional) A specific git commit to check out. This is useful for upstream repos that do not tag their releases.
* package_version       : (required) The string to describe the package version. This string is used to build the full package name. 
                          This can be uniform for all platforms or can be set for a specific platform
* prebuilt_source       : (optional) If the 3rd party library files are prebuilt and accessible, then setting this key to the relative location of 
                          the folder will cause the workflow to perform copy operations into the generated target library folder directly (see
                          'prebuilt_args' below.
* prebuild_args         : (required if  prebuilt_source is set) A map of target subfolders within the target 3rd party folder against a glob pattern of
                          file(s) to copy to the target subfolders.
* cmake_find_source     : The name of the source find*.cmake file that will be used in the target package
                          that is ingested by the lumberyard 3P system.
* cmake_find_template   : If the find*.cmake in the target package requires template processing, then this is name of the template file that is used to 
                          generate the contents of the find*.cmake file in the target package. 
                          * Note that either 'cmake_find_source' or 'cmake_fine_template' must be declared.
* cmake_find_target     : (required if prebuilt_source is not set) The name of the target find*.cmake file that is generated based on the template file and 
                          additional arguments (described below)

* build_configs         : (optional) A list of configurations to build during the build process. This is available
                          to restrict building to a specific configuration rather than building all configurations 
                          (provided by the default value: ['Debug', 'Release'])
* patch_file            : (optional) Option patch file to apply to the synced source before performing a build
* source_path           : (optional) Option to provide a path to the project source rather than getting it from github
* git_skip              : (optional) Option to skip all git commands, requires source_path


The following keys can only exist at the target platform level as they describe the specifics for that platform.

* cmake_generate_args                     : The cmake generation arguments (minus the build folder target or any configuration) for generating 
                                            the project for the platform (for all configurations). To perform specific generation commands (i.e.
                                            for situations where the generator does not support multiple configs) the key can contain the 
                                            suffix of the configuration name (cmake_generate_args_debug, cmake_generate_args_release)
                                            
* cmake_build_args                        : Additional build args to pass to cmake during the cmake build command

* cmake_install_filter                    : Optional list of filename patterns to filter what is actually copied to the target package based on
                                            the 3rd party library's install definition. (For example, a library may install headers and static
                                            libraries when all you want in the package is just the binary executables). If omitted, then the entire
                                            install tree will be copied to the target package

* custom_build_cmd                        : A list of custom scripts to run to build from the source that was pulled from git. This option is 
                                            mutually exclusive from the cmake_generate_args and cmake_build_args options.
                                            see the note about environment variables below.

* custom_install_cmd                      : A list of custom scripts to run (after the custom_build_cmd) to copy and assemble the built binaries
                                            into the target package folder.
                                            this argument is optional.  You could do the install in your custom build command instead.
                                            see the note about environment variables below.

* custom_install_json                     : A list of files to copy into the target package folder from the built SDK. This argument is optional.

* custom_test_cmd                         : after making the package, it will run this and expect exit code 0
                                            this argument is optional.
                                            see the note about environment variables below.

* custom_additional_compile_definitions   : Any additional compile definitions to apply in the find*.cmake file for the library that will applied
                                            to targets that consume this 3P library
                                            
* custom_additional_link_options          : Any additional linker options to apply in the find*.cmake file for the library that will applied
                                            to targets that consume this 3P library during linking
                                            
* custom_additional_libraries             : Any additional dependent system library to include in the find*.cmake file for the library that will 
                                            applied to targets that consume this 3P library during linking
                                            
* custom_cmake_install                    : Custom flag for certain platforms (ie iOS) that needs the installation arguments applied during the 
                                            cmake generation, and not to apply the cmake install process

* depends_on_packages                     : list of name of 3-TUPLES of [package name, package hash, subfolder] that 'find' files live in] 
                                            [  ["zlib-1.5.3-rev5",    "some hash", ""],
                                               ["some other package", "some other hash", "subfoldername"], 
                                               ...
                                            ] 
                                            that we need to download and use).
    - note that we don't check recursively - you must name your recursive deps!
    - The packages must be on a public CDN or locally tested with FILE:// - it uses env var 
      "LY_PACKAGE_SERVER_URLS" which can be a semicolon seperated list of places to try.
    - The packages unzip path + subfolder is added to CMAKE_MODULE_PATH if you use cmake commands.
    - Otherwise you can use DOWNLOADED_PACKAGE_FOLDERS env var in your custom script and set
    - CMAKE_MODULE_PATH to be that value, yourself.
    - The subfolder can be empty, in which case the root of the package will be used.

Note about environment variables:
When custom commands are issued (build, install, and test), the following environment variables will be set
for the process:
         PACKAGE_ROOT = root of the package being made (where PackageInfo.json is generated/copied)
         TARGET_INSTALL_ROOT = $PACKAGE_ROOT/$PACKAGE_NAME - usually where you target cmake install to
         TEMP_FOLDER = the temp folder.  This folder usually has subfolder 'build' and 'src'
         PYTHON_BINARY = the path to the python binary that launched the build script. This can be useful if
                         one of the custom build/install scripts (e.g. my_script.sh/.cmd) want to invoke
                         a python script using the same python executable that launched the build.
         DOWNLOADED_PACKAGE_FOLDERS = semicolon seperated list of abs paths to each downloaded package Find folder.
            - usually used to set CMAKE_MODULE_PATH so it can find the packages.
            - unset if there are no dependencies declared
    Note that any of the above environment variables that contain paths will use system native slashes for script
    compatibility, and may need to be converted to forward slash in your script on windows 
    if you feed it to cmake.
    Also note that the working directory for all custom commands will the folder containing the build_config.json file.


The general layout of the build_config.json file is as follows:

{
    ${root level keys}
    ${global keys}
    "Platforms": {
       ${Host Platforms}: {
           ${Target Platform}: {
              ${platform specific general keys}
              ${platform specific required keys}
           }
       }
    }
}

"""

# The current path of this script, expected to be under '3rdPartySource/Scripts'
CURRENT_PATH = pathlib.Path(os.path.dirname(__file__)).resolve()

# Expected package-system folder as the parent of this folder
PACKAGE_SYSTEM_PATH = CURRENT_PATH.parent.parent / 'package-system'
assert PACKAGE_SYSTEM_PATH.is_dir(), "Missing package-system folder, make sure it is synced from source control"

# Some platforms required environment variables to be set before the build, create the appropriate pattern to search for it
if platform.system() == 'Windows':
    ENV_PATTERN = re.compile(r"(%([a-zA-Z0-9_]*)%)")
else:
    ENV_PATTERN = re.compile(r"($([a-zA-Z0-9_]*))")

DEFAULT_BUILD_CONFIG_FILENAME = "build_config.json"


class BuildError(Exception):
    """
    Manage Package Build specific exceptions
    """
    pass


class PackageInfo(object):
    """
    This class manages general information for the package based on the build config and target platform
    information. It does not manage the actual cmake commands
    """

    PACKAGE_INFO_TEMPLATE = """{
    "PackageName" : "$package_name-$package_version-$platform_name",
    "URL"         : "$package_url",
    "License"     : "$package_license",
    "LicenseFile" : "$package_name/$package_license_file"
}
"""

    def __init__(self, build_config, target_platform_name, target_platform_config):
        """
        Initialize the PackageInfo

        :param build_config:            The entire build configuration dictionary (from the build config json file)
        :param target_platform_name:    The target platform name that is being packaged for
        :param target_platform_config:  The target platform configuration (from the build configuration dictionary)
        """

        self.platform_name = target_platform_name
        try:
            self.package_name = build_config["package_name"]
            self.package_url = build_config["package_url"]
            self.package_license = build_config["package_license"]
            self.package_license_file = build_config["package_license_file"]
        except KeyError as e:
            raise BuildError(f"Invalid build config. Missing required key : {str(e)}")

        def _get_value(value_key, required=True, default=None):
            result = target_platform_config.get(value_key, build_config.get(value_key, default))
            if required and result is None:
                raise BuildError(f"Required key '{value_key}' not found in build config")
            return result

        self.git_url = _get_value("git_url")
        self.git_tag = _get_value("git_tag")
        self.package_version = _get_value("package_version")
        self.patch_file = _get_value("patch_file", required=False)
        self.git_commit = _get_value("git_commit", required=False)
        self.cmake_find_template = _get_value("cmake_find_template", required=False)
        self.cmake_find_source = _get_value("cmake_find_source", required=False)
        self.cmake_find_target = _get_value("cmake_find_target")
        self.cmake_find_template_custom_indent = _get_value("cmake_find_template_custom_indent", default=1)
        self.additional_src_files = _get_value("additional_src_files", required=False)
        self.depends_on_packages = _get_value("depends_on_packages", required=False)

        if self.cmake_find_template and self.cmake_find_source:
            raise BuildError("Bad build config file. 'cmake_find_template' and 'cmake_find_source' cannot both be set in the configuration.")            
        if not self.cmake_find_template and not self.cmake_find_source:
            raise BuildError("Bad build config file. 'cmake_find_template' or 'cmake_find_source' must be set in the configuration.")


    def write_package_info(self, install_path):
        """
        Write to the target 'PackageInfo.json' file for the package
        :param install_path:  The folder to write the file to
        """
        package_info_target_file = install_path / "PackageInfo.json"
        if package_info_target_file.is_file():
            package_info_target_file.unlink()
        package_info_env = {
            'package_name': self.package_name,
            'package_version': self.package_version,
            'platform_name': self.platform_name.lower(),
            'package_url': self.package_url,
            'package_license': self.package_license,
            'package_license_file': os.path.basename(self.package_license_file)
        }
        package_info_content = string.Template(PackageInfo.PACKAGE_INFO_TEMPLATE).substitute(package_info_env)
        package_info_target_file.write_text(package_info_content)


def subp_args(args):
    """
    According to subcommand, when using shell=True, its recommended not to pass in an argument list but the full command line as a single string.
    That means in the argument list in the configuration make sure to provide the proper escapements or double-quotes for paths with spaces

    :param args: The list of arguments to transform
    """
    arg_string = " ".join([arg for arg in args])
    print(f"Command: {arg_string}")
    return arg_string


def validate_git():
    """
    If make sure git is available

    :return: String describing the version of the detected git
    """
    call_result = subprocess.run(subp_args(['git', '--version']), shell=True, capture_output=True)
    if call_result.returncode != 0 and call_result.returncode != 1:
        raise BuildError("Git is not installed on the default path. Make sure its installed")
    version_result = call_result.stdout.decode('UTF-8', 'ignore').strip()
    return version_result


def validate_cmake(cmake_path):
    """
    Make sure that the cmake command being used is available and confirm the version

    :return: String describing the version of cmake
    """
    call_result = subprocess.run(subp_args([cmake_path, '--version']), shell=True, capture_output=True)
    if call_result.returncode != 0:
        raise BuildError(f"Unable to detect CMake ({cmake_path})")
    version_result_lines = call_result.stdout.decode('UTF-8', 'ignore').split('\n')
    version_result = version_result_lines[0]
    print(f"Detected CMake: {version_result}")
    return cmake_path


def validate_patch():
    """
    Make sure patch is installed and on the default path

    :return: String describing the version of patch
    """
    call_result = subprocess.run(subp_args(['patch', '--version']), shell=True, capture_output=True)
    if call_result.returncode != 0:
        raise BuildError("'Patch' is not installed on the default path. Make sure its installed")
    version_result_lines = call_result.stdout.decode('UTF-8', 'ignore').split('\n')
    version_result = version_result_lines[0]
    return version_result


def delete_folder(folder):
    """
    Use the system's remove folder command instead of os.rmdir
    """

    if platform.system() == 'Windows':
        call_result = subprocess.run(subp_args(['rmdir', '/Q', '/S', str(folder.name)]),
                                     shell=True,
                                     capture_output=True,
                                     cwd=str(folder.parent.absolute()))
    else:
        call_result = subprocess.run(subp_args(['rm', '-rf', str(folder.name)]),
                                     shell=True,
                                     capture_output=True,
                                     cwd=str(folder.parent.absolute()))
    if call_result.returncode != 0:
        raise BuildError(f"Unable to delete folder {str(folder)}: {str(call_result.stderr)}")


def validate_args(input_args):
    """
    Validate and make sure that if any environment variables are passed into the argument that the environment variable is actually set
    """

    if input_args:
        for arg in input_args:
            match_env = ENV_PATTERN.search(arg)
            if not match_env:
                continue
            env_var_name = match_env.group(2)
            if not env_var_name:
                continue
            env_var_value = os.environ.get(env_var_name)
            if not env_var_value:
                raise BuildError(f"Required environment variable '{env_var_name}' not set")

    return input_args


class BuildInfo(object):
    """
    This is the Build management class that will perform the entire build from source and preparing a folder for packaging
    """

    def __init__(self, package_info, platform_config, base_folder, build_folder, package_install_root, 
                 custom_toolchain_file, cmake_command, clean_build, cmake_find_template, 
                 cmake_find_source, prebuilt_source, prebuilt_args, src_folder, skip_git):
        """
        Initialize the Build management object with information needed

        :param package_info:            The PackageInfo object constructed from the build config
        :param platform_config:         The target platform configuration from the build config dictionary
        :param base_folder:             The base folder where the build_config exists
        :param build_folder:            The root folder to build into
        :param package_install_root:    The root of the package folder where the new package will be assembled
        :param custom_toolchain_file:   Option toolchain file to use for specific target platforms
        :param cmake_command:           The cmake executable command to use for cmake
        :param clean_build:             Option to clean any existing build folder before proceeding
        :param cmake_find_template:     The template for the find*.cmake generated file
        :param cmake_find_source:       The source file for the find*.cmake generated file
        :param prebuilt_source:         If provided, the git fetch / build flow will be replaced with a copy from a prebuilt folder
        :param prebuilt_args:           If prebuilt_source is provided, then this argument is required to specify the copy rules to assemble the package from the prebuilt package
        :param src_folder:              Path to the source code / where to clone the git repo.
        :param skip_git:                If true skip all git interaction and .
        """

        assert (cmake_find_template is not None and cmake_find_source is None) or \
                (cmake_find_template is None and cmake_find_source is not None), "Either cmake_find_template or cmake_find_source must be set, but not both"

        self.package_info = package_info
        self.platform_config = platform_config
        self.custom_toolchain_file = custom_toolchain_file
        self.cmake_command = cmake_command
        self.base_folder = base_folder
        self.base_temp_folder = build_folder
        self.src_folder = src_folder
        self.build_folder = self.base_temp_folder / "build"
        self.package_install_root = package_install_root / f"{package_info.package_name}-{package_info.platform_name.lower()}"
        self.build_install_folder = self.package_install_root / package_info.package_name
        self.clean_build = clean_build
        self.cmake_find_template = cmake_find_template
        self.cmake_find_source = cmake_find_source
        self.build_configs = platform_config.get('build_configs', ['Debug', 'Release'])
        self.prebuilt_source = prebuilt_source
        self.prebuilt_args = prebuilt_args
        self.skip_git = skip_git


    def clone_to_local(self):
        """
        Perform a clone to the local temp folder
        """

        print(f"Cloning {self.package_info.package_name}/{self.package_info.git_tag} to {str(self.src_folder.absolute())}")

        working_dir = str(self.src_folder.parent.absolute())
        relative_src_dir = self.src_folder.name
        clone_cmd = ['git',
                     'clone',
                     '--single-branch',
                     '--recursive',
                     '--branch',
                     self.package_info.git_tag,
                     self.package_info.git_url,
                     relative_src_dir]
        clone_result = subprocess.run(subp_args(clone_cmd),
                                      shell=True,
                                      capture_output=True,
                                      cwd=working_dir)
        if clone_result.returncode != 0:
            raise BuildError(f"Error cloning from GitHub: {clone_result.stderr.decode('UTF-8', 'ignore')}")

        if self.package_info.git_commit is not None:
            # Allow the package to specify a specific commit to check out. This is useful for upstream repos that do
            # not tag their releases.
            checkout_result = subprocess.run(
                ['git', 'checkout', self.package_info.git_commit],
                capture_output=True,
                cwd=self.src_folder)

            if checkout_result.returncode != 0:
                raise BuildError(f"Error checking out {self.package_info.git_commit}: {checkout_result.stderr.decode('UTF-8', 'ignore')}")

    def prepare_temp_folders(self):
        """
        Prepare the temp folders for cloning, building, and local installing
        """

        # Always clean the target package install folder to prevent stale files from being included
        if self.package_install_root.is_dir():
            delete_folder(self.package_install_root)

        if not self.build_folder.is_dir():
            self.build_folder.mkdir(parents=True)
        elif self.clean_build:
            delete_folder(self.build_folder)
            self.build_folder.mkdir(parents=True)

        if not self.build_install_folder.is_dir():
            self.build_install_folder.mkdir(parents=True)

    def sync_source(self):
        """
        Sync the 3rd party from its git source location (either cloning if its not there or syncing)
        """
        if self.skip_git:
            return

        # Validate Git is installed
        git_version = validate_git()
        print(f"Detected Git: {git_version}")

        # Sync to the source folder
        if self.src_folder.is_dir():
            # If the folder exists, see if git stash works or not
            git_pull_cmd = ['git',
                            'stash']
            call_result = subprocess.run(subp_args(git_pull_cmd),
                                         shell=True,
                                         capture_output=True,
                                         cwd=str(self.src_folder.absolute()))
            if call_result.returncode != 0:
                # Not a valid git folder, okay to remove and re-clone
                delete_folder(self.src_folder)
                self.clone_to_local()
            else:
                # Do a re-pull
                git_pull_cmd = ['git',
                                'pull']
                call_result = subprocess.run(subp_args(git_pull_cmd),
                                             shell=True,
                                             capture_output=True,
                                             cwd=str(self.src_folder.absolute()))
                if call_result.returncode != 0:
                    raise BuildError(f"Error pulling source from GitHub: {call_result.stderr.decode('UTF-8', 'ignore')}")
        else:
            self.clone_to_local()

        if self.package_info.additional_src_files:
            for additional_src in self.package_info.additional_src_files:
                additional_src_path = self.base_folder / additional_src
                if not additional_src_path.is_file():
                    raise BuildError(f"Invalid additional src file: : {additional_src}")
                additional_tgt_path = self.src_folder / additional_src
                if additional_tgt_path.is_file():
                    additional_tgt_path.unlink()
                shutil.copy2(str(additional_src_path), str(additional_tgt_path))

        # Check/Validate the license file from the package, and copy over to install path
        if self.package_info.package_license_file:
            package_license_src = self.src_folder / self.package_info.package_license_file
            if not package_license_src.is_file():
                package_license_src = self.src_folder / os.path.basename(self.package_info.package_license_file)
                if not package_license_src.is_file():
                    raise BuildError(f"Invalid/missing license file '{self.package_info.package_license_file}' specified in the build config.")

            license_file_content = package_license_src.read_text("UTF-8", "ignore")
            if "Copyright" not in license_file_content and "OPEN 3D ENGINE LICENSING" not in license_file_content and "copyright" not in license_file_content:
                raise BuildError(f"Unable to find 'Copyright' or the O3DE licensing text in the license file {str(self.package_info.package_license_file)}. Is this a valid license file?")
            target_license_copy = self.build_install_folder / os.path.basename(package_license_src)
            if target_license_copy.is_file():
                target_license_copy.unlink()
            shutil.copy2(str(package_license_src), str(target_license_copy))

        # Check if there is a patch to apply
        if self.package_info.patch_file:
            patch_file_path = self.base_folder / self.package_info.patch_file
            if not patch_file_path.is_file():
                raise BuildError(f"Invalid/missing patch file '{patch_file_path}' specified in the build config.")

            patch_cmd = ['git',
                         'apply',
                         "--ignore-whitespace",
                         str(patch_file_path.absolute())]

            patch_result = subprocess.run(subp_args(patch_cmd),
                                          shell=True,
                                          capture_output=True,
                                          cwd=str(self.src_folder.absolute()))
            if patch_result.returncode != 0:
                raise BuildError(f"Error Applying patch {str(patch_file_path.absolute())}: {patch_result.stderr.decode('UTF-8', 'ignore')}")
        # Check if there are any package dependencies.
        if self.package_info.depends_on_packages:
            for package_name, package_hash, _ in self.package_info.depends_on_packages:
                temp_packages_folder = self.base_temp_folder
                if not PackageDownloader.DownloadAndUnpackPackage(package_name, package_hash, str(temp_packages_folder)):
                    raise BuildError(f"Failed to download a required dependency: {package_name}")


    def build_and_install_cmake(self):
        """
        Build and install to a local folder to prepare for packaging
        """

        is_multi_config = 'cmake_generate_args' in self.platform_config
        if not is_multi_config:
            if 'cmake_generate_args_debug' not in self.platform_config and 'cmake_generate_args_release' not in self.platform_config:
                raise BuildError("Invalid configuration")
        custom_cmake_install = self.platform_config.get('custom_cmake_install', False)

        # Check for the optional install filter
        cmake_install_filter = self.platform_config.get('cmake_install_filter', None)
        if cmake_install_filter:
            # If there is a custom install filter, then we need to install to another temp folder and copy over based on the filter rules
            install_target_folder = self.base_temp_folder / 'working_install'
            if not install_target_folder.is_dir():
                install_target_folder.mkdir(parents=True)
        else:
            # Otherwise install directly to the target
            install_target_folder = self.build_install_folder

        build_args = validate_args(self.platform_config.get('cmake_build_args', []))

        can_skip_generate = False

        for config in self.build_configs:

            if not can_skip_generate:
                cmake_generator_args = self.platform_config.get(f'cmake_generate_args_{config.lower()}')
                if not cmake_generator_args:
                    cmake_generator_args = self.platform_config.get('cmake_generate_args')
                    # Can skip generate the next time since there is only 1 unique cmake generation
                    can_skip_generate = True

                validate_args(cmake_generator_args)

                cmake_generate_cmd = [self.cmake_command,
                                      '-S', str(self.src_folder.absolute()),
                                      '-B', str(self.build_folder.name)]

                if self.custom_toolchain_file:
                    cmake_generator_args.append( f'-DCMAKE_TOOLCHAIN_FILE="{self.custom_toolchain_file}"')

                cmake_module_path = ""
                paths_to_join = []
                if self.package_info.depends_on_packages:
                    paths_to_join = []
                    for package_name, package_hash, subfolder_name in self.package_info.depends_on_packages:
                        package_download_location = self.base_temp_folder / package_name / subfolder_name
                        paths_to_join.append(str(package_download_location.resolve()))
                    cmake_module_path = ';'.join(paths_to_join).replace('\\', '/')

                if cmake_module_path:
                    cmake_generate_cmd.extend([f"-DCMAKE_MODULE_PATH={cmake_module_path}"])

                cmake_generate_cmd.extend(cmake_generator_args)
                
                if custom_cmake_install:
                    cmake_generate_cmd.extend([f"-DCMAKE_INSTALL_PREFIX={str(self.build_install_folder.resolve())}"])

                call_result = subprocess.run(subp_args(cmake_generate_cmd),
                                             shell=True,
                                             capture_output=False,
                                             cwd=str(self.build_folder.parent.resolve()))
                if call_result.returncode != 0:
                    raise BuildError(f"Error generating project for platform {self.package_info.platform_name}")

            cmake_build_args = self.platform_config.get(f'cmake_build_args_{config.lower()}') or \
                               self.platform_config.get('cmake_build_args') or \
                               []

            validate_args(cmake_build_args)

            cmake_build_cmd = [self.cmake_command,
                               '--build', str(self.build_folder.name),
                               '--config', config]
            if custom_cmake_install:
                cmake_build_cmd.extend(['--target', 'install'])

            cmake_build_cmd.extend(build_args)

            call_result = subprocess.run(subp_args(cmake_build_cmd),
                                         shell=True,
                                         capture_output=False,
                                         cwd=str(self.build_folder.parent.resolve()))
            if call_result.returncode != 0:
                raise BuildError(f"Error building project for platform {self.package_info.platform_name}")

            if not custom_cmake_install:
                cmake_install_cmd = [self.cmake_command,
                                     '--install', str(self.build_folder.name),
                                     '--prefix', str(install_target_folder.resolve()),
                                     '--config', config]
                call_result = subprocess.run(subp_args(cmake_install_cmd),
                                             shell=True,
                                             capture_output=False,
                                             cwd=str(self.build_folder.parent.resolve()))
                if call_result.returncode != 0:
                    raise BuildError(f"Error installing project for platform {self.package_info.platform_name}")

        if cmake_install_filter:
            # If an install filter was specified, then perform a copy from the intermediate temp install folder
            # to the target package folder, applying the filter rules defined in the 'cmake_install_filter'
            # attribute.

            source_root_folder = str(install_target_folder.resolve())
            glob_results = glob.glob(f'{source_root_folder}/**', recursive=True)
            for glob_result in glob_results:
                if os.path.isdir(glob_result):
                    continue
                print(glob_result)
                source_relative = os.path.relpath(glob_result, source_root_folder)
                matched = False
                for pattern in cmake_install_filter:
                    if fnmatch.fnmatch(source_relative, pattern):
                        matched = True
                        break

                if matched:
                    target_path = self.build_install_folder / source_relative
                    target_folder_path = target_path.parent
                    if not target_folder_path.is_dir():
                        target_folder_path.mkdir(parents=True)
                    shutil.copy2(glob_result, str(target_folder_path.resolve()), follow_symlinks=False)

    def create_custom_env(self):
        custom_env = os.environ.copy()
        custom_env['TARGET_INSTALL_ROOT'] = str(self.build_install_folder.resolve())
        custom_env['PACKAGE_ROOT'] = str(self.package_install_root.resolve())
        custom_env['TEMP_FOLDER'] = str(self.base_temp_folder.resolve())
        custom_env['PYTHON_BINARY'] = sys.executable
        if self.package_info.depends_on_packages:
            package_folder_list = []
            for package_name, _, subfoldername in self.package_info.depends_on_packages:
                package_folder_list.append(str( (self.base_temp_folder / package_name / subfoldername).resolve().absolute()))
            custom_env['DOWNLOADED_PACKAGE_FOLDERS'] = ';'.join(package_folder_list)
        return custom_env

    def build_and_install_custom(self):
        """
        Build and install from source using custom commands defined by 'custom_build_cmd' and 'custom_install_cmd'
        """
        # we add TARGET_INSTALL_ROOT, TEMP_FOLDER and DOWNLOADED_PACKAGE_FOLDERS to the environ for both
        # build and install, as they are useful to refer to from scripts.
        
        env_to_use = self.create_custom_env()
        custom_build_cmds = self.platform_config.get('custom_build_cmd', [])
        for custom_build_cmd in custom_build_cmds:
            # Support the user specifying {python} in the custom_build_cmd to invoke
            # the Python executable that launched this build script
            call_result = subprocess.run(custom_build_cmd.format(python=sys.executable),
                                         shell=True,
                                         capture_output=False,
                                         cwd=str(self.base_folder),
                                         env=env_to_use)
            if call_result.returncode != 0:
                raise BuildError(f"Error executing custom build command {custom_build_cmd}")

        custom_install_cmds = self.platform_config.get('custom_install_cmd', [])
       
        for custom_install_cmd in custom_install_cmds:
            # Support the user specifying {python} in the custom_install_cmd to invoke
            # the Python executable that launched this build script
            call_result = subprocess.run(custom_install_cmd.format(python=sys.executable),
                                         shell=True,
                                         capture_output=False,
                                         cwd=str(self.base_folder),
                                         env=env_to_use)
            if call_result.returncode != 0:
                raise BuildError(f"Error executing custom install command {custom_install_cmd}")
                
        # Allow libraries to define a list of files to include via a json script that stores folder paths and
        # individual files in the "Install_Paths" array
        custom_install_jsons = self.platform_config.get('custom_install_json', [])
        for custom_install_json_file in custom_install_jsons:
            custom_json_full_path = os.path.join(self.base_folder, custom_install_json_file)
            print(f"Running custom install json file {custom_json_full_path}")
            custom_json_full_path_file = open(custom_json_full_path)
            custom_install_json = json.loads(custom_json_full_path_file.read())
            if not custom_install_json:
                raise BuildError(f"Error loading custom install json file {custom_install_json_file}")
            source_subfolder = None
            if "Source_Subfolder" in custom_install_json:
                source_subfolder = custom_install_json["Source_Subfolder"]
            for install_path in custom_install_json["Install_Paths"]:
                install_src_path = install_path
                if source_subfolder is not None:
                    install_src_path = os.path.join(source_subfolder, install_src_path)
                resolved_src_path = os.path.join(env_to_use['TEMP_FOLDER'], install_src_path)
                resolved_target_path = os.path.join(env_to_use['TARGET_INSTALL_ROOT'], install_path)
                if os.path.isdir(resolved_src_path):
                    # Newer versions of Python support the parameter dirs_exist_ok=True,
                    # but that's not available in earlier Python versions.
                    # It's useful to treat it as an error if the target exists, because that means that something has
                    # already touched that folder and there might be unexpected behavior copying an entire tree into it.
                    print(f"    Copying directory '{resolved_src_path}' to '{resolved_target_path}'")
                    shutil.copytree(resolved_src_path, resolved_target_path)
                elif os.path.isfile(resolved_src_path):
                    print(f"    Copying file '{resolved_src_path}' to '{resolved_target_path}'")
                    os.makedirs(os.path.dirname(resolved_target_path), exist_ok=True)
                    shutil.copy2(resolved_src_path, resolved_target_path)
                else:
                    raise BuildError(f"Error executing custom install json {custom_install_json_file}, found invalid source path {resolved_src_path}")


    def check_build_keys(self, keys_to_check):
        """
        Check a platform configuration for specific build keys
        """
        config_specific_build_keys = []
        for config in self.build_configs:
            for build_key in keys_to_check:
                config_specific_build_keys.append(f'{build_key}_{config.lower()}')

        for platform_config_key in self.platform_config.keys():
            if platform_config_key in keys_to_check:
                return True
            elif platform_config_key in config_specific_build_keys:
                return True

        return False

    def build_for_platform(self):
        """
        Build for the current platform (host+target)
        """

        has_cmake_arguments = self.check_build_keys(['cmake_generate_args', 'cmake_build_args'])

        has_custom_arguments = self.check_build_keys(['custom_build_cmd', 'custom_install_cmd'])

        if has_cmake_arguments and has_custom_arguments:
            raise BuildError("Bad build config file. You cannot have both cmake_* and custom_* platform build commands at the same time.")

        if has_cmake_arguments:
            self.build_and_install_cmake()
        elif has_custom_arguments:
            self.build_and_install_custom()
        else:
            raise BuildError("Bad build config file. Missing generate and build commands (cmake or custom)")

    def generate_package_info(self):
        """
        Generate the package file (PackageInfo.json)
        """

        self.package_info.write_package_info(self.package_install_root)

    def generate_cmake(self):
        """
        Generate the find*.cmake file for the library
        """

        if self.cmake_find_template is not None:

            template_file_content = self.cmake_find_template.read_text("UTF-8", "ignore")

            def _build_list_str(indent, key):
                list_items = self.platform_config.get(key, [])
                indented_list_items = []
                for list_item in list_items:
                    indented_list_items.append(f'{" "*(indent*4)}{list_item}')
                return '\n'.join(indented_list_items)

            cmake_find_template_def_ident_level = self.package_info.cmake_find_template_custom_indent

            template_env = {
                "CUSTOM_ADDITIONAL_COMPILE_DEFINITIONS": _build_list_str(cmake_find_template_def_ident_level, 'custom_additional_compile_definitions'),
                "CUSTOM_ADDITIONAL_LINK_OPTIONS": _build_list_str(cmake_find_template_def_ident_level, 'custom_additional_link_options'),
                "CUSTOM_ADDITIONAL_LIBRARIES": _build_list_str(cmake_find_template_def_ident_level, 'custom_additional_libraries')
            }

            find_cmake_content = string.Template(template_file_content).substitute(template_env)

        elif self.cmake_find_source is not None:
            find_cmake_content = self.cmake_find_source.read_text("UTF-8", "ignore")

        target_cmake_find_script = self.package_install_root / self.package_info.cmake_find_target
        target_cmake_find_script.write_text(find_cmake_content)

    def assemble_from_prebuilt_source(self):

        assert self.prebuilt_source
        assert self.prebuilt_args

        # Optionally clean the target package folder first
        if self.clean_build and self.package_install_root.is_dir():
            delete_folder(self.package_install_root)

        # Prepare the target package folder
        if not self.build_install_folder.is_dir():
            self.build_install_folder.mkdir(parents=True)

        prebuilt_source_path = (self.base_folder.resolve() / self.prebuilt_source).resolve()
        target_base_package_path = self.build_install_folder.resolve()

        # Loop through each of the prebuilt arguments (target/source glob pattern)
        for dest_path, glob_pattern in self.prebuilt_args.items():

            # Assemble the search pattern as a full path and keep track of the root of the search pattern so that
            # only the subpaths after the root of the search pattern will be copied to the target folder
            full_search_pattern = f"{str(prebuilt_source_path)}/{glob_pattern}"
            wildcard_index = full_search_pattern.find('*')
            source_base_folder_path = '' if wildcard_index < 0 else os.path.normpath(full_search_pattern[:wildcard_index])

            # Make sure the specified target folder exists
            target_base_folder_path = target_base_package_path / dest_path
            if not target_base_folder_path.is_dir():
                target_base_folder_path.mkdir(parents=True)

            total_copied = 0

            # For each search pattern, run a glob
            glob_results = glob.glob(full_search_pattern, recursive=True)
            for glob_result in glob_results:
                if os.path.isdir(glob_result):
                    continue
                source_relative = os.path.relpath(glob_result, source_base_folder_path)
                target_path = target_base_folder_path / source_relative
                target_folder_path = target_path.parent
                if not target_folder_path.is_dir():
                    target_folder_path.mkdir(parents=True)
                shutil.copy2(glob_result, str(target_folder_path.resolve()), follow_symlinks=False)
                total_copied += 1
            print(f"{total_copied} files copied to {target_base_folder_path}")

        pass

    def test_package(self):
        has_test_commands = self.check_build_keys(['custom_test_cmd'])
        if not has_test_commands:
            return

        custom_test_cmds= self.platform_config.get('custom_test_cmd', [])
        for custom_test_cmd in custom_test_cmds:

            call_result = subprocess.run(custom_test_cmd,
                                        shell=True,
                                        capture_output=False,
                                        cwd=str(self.base_folder),
                                        env=self.create_custom_env())
            if call_result.returncode != 0:
                raise BuildError(f"Error executing custom test command {custom_test_cmd}")

    def execute(self):
        """
        Perform all the steps to build a folder for the 3rd party library for packaging
        """

        # Prepare the temp folder structure
        if self.prebuilt_source:
            self.assemble_from_prebuilt_source()
        else:
            self.prepare_temp_folders()

            # Sync Source
            self.sync_source()

            # Build the package
            self.build_for_platform()

        # Generate the Find*.cmake file
        self.generate_cmake()

        self.test_package()

        # Generate the package info file
        self.generate_package_info()


def prepare_build(platform_name, base_folder, build_folder, package_root_folder, cmake_command, toolchain_file, build_config_file,
                  clean, src_folder, skip_git):
    """
    Prepare a Build manager object based on parameters provided (possibly from command line)

    :param platform_name:       The name of the target platform that the package is being for
    :param base_folder:         The base folder where the build_config exists
    :param build_folder:        The root folder to build into
    :param package_root_folder: The root of the package folder where the new package will be assembled
    :param cmake_command:       The cmake executable command to use for cmake
    :param toolchain_file:      Option toolchain file to use for specific target platforms
    :param build_config_file:   The build config file to open from the base_folder
    :param clean:               Option to clean any existing build folder before proceeding
    :param src_folder:          Option to manually specify the src folder
    :param skip_git:            Option to skip all git commands, requires src_folder be supplied

    :return:    The Build management object
    """
    base_folder_path = pathlib.Path(base_folder)
    build_folder_path = pathlib.Path(build_folder) if build_folder else base_folder_path / "temp"
    package_install_root = pathlib.Path(package_root_folder)
    src_folder_path = pathlib.Path(src_folder) if src_folder else build_folder_path / "src"

    if skip_git and src_folder is None:
        raise BuildError("Specified to skip git interactions but didn't supply a source code path")

    if src_folder is not None and not src_folder_path.is_dir():
        raise BuildError(f"Invalid path for 'git-path': {src_folder}")

    build_config_path = base_folder_path / build_config_file
    if not build_config_path.is_file():
        raise BuildError(f"Invalid build config path ({build_config_path.absolute()}). ")

    with build_config_path.open() as build_json_file:
        build_config = json.load(build_json_file)

    try:
        eligible_platforms = build_config["Platforms"][platform.system()]
        target_platform_config = eligible_platforms[platform_name]
    except KeyError as e:
        raise BuildError(f"Invalid build config : {str(e)}")

    # Check if this is a prebuilt package to validate any additional required arguments
    prebuilt_source = target_platform_config.get('prebuilt_source') or build_config.get('prebuilt_source')
    if prebuilt_source:
        prebuilt_path = base_folder_path / prebuilt_source
        if not prebuilt_path.is_dir():
            raise BuildError(f"Invalid path given for 'prebuilt_source': {prebuilt_source}")
        prebuilt_args = target_platform_config.get('prebuilt_args')
        if not prebuilt_args:
            raise BuildError(f"Missing required 'prebuilt_args' argument for platform {platform_name}")
    else:
        prebuilt_args = None

    package_info = PackageInfo(build_config=build_config,
                               target_platform_name=platform_name,
                               target_platform_config=target_platform_config)

    cmake_find_template_path = None
    cmake_find_source_path = None

    if package_info.cmake_find_template is not None:

        # Validate the cmake find template
        if os.path.isabs(package_info.cmake_find_template):
            raise BuildError("Invalid 'cmake_find_template' entry in build config. Absolute paths are not allowed, must be relative to the package base folder.")
        
        cmake_find_template_path = base_folder_path / package_info.cmake_find_template
        if not cmake_find_template_path.is_file():
            raise BuildError("Invalid 'cmake_find_template' entry in build config")

    elif package_info.cmake_find_source is not None:

        # Validate the cmake find source
        if os.path.isabs(package_info.cmake_find_source):
            raise BuildError("Invalid 'cmake_find_source' entry in build config. Absolute paths are not allowed, must be relative to the package base folder.")

        cmake_find_source_path = base_folder_path / package_info.cmake_find_source
        if not cmake_find_source_path.is_file():
            raise BuildError("Invalid 'cmake_find_source' entry in build config")

    else:
        raise BuildError("Bad build config file. 'cmake_find_template' or 'cmake_find_template' must be specified.")            

    return BuildInfo(package_info=package_info,
                     platform_config=target_platform_config,
                     base_folder=base_folder_path,
                     build_folder=build_folder_path,
                     package_install_root=package_install_root,
                     custom_toolchain_file=toolchain_file,
                     cmake_command=cmake_command,
                     clean_build=clean,
                     cmake_find_template=cmake_find_template_path,
                     cmake_find_source=cmake_find_source_path,
                     prebuilt_source=prebuilt_source,
                     prebuilt_args=prebuilt_args,
                     src_folder=src_folder_path,
                     skip_git=skip_git)


if __name__ == '__main__':

    try:
        parser = argparse.ArgumentParser(description="Tool to prepare a 3rd Party Folder for packaging for an open source project pulled from Git.",
                                         formatter_class=argparse.RawDescriptionHelpFormatter,
                                         epilog=SCHEMA_DESCRIPTION)

        parser.add_argument('base_path',
                            help='The base path where the build configuration exists')

        parser.add_argument('--platform-name',
                            help='The platform to build the package for.',
                            required=True)
        parser.add_argument('--package-root',
                            help="The root path where to install the built packages to.",
                            required=True)
        parser.add_argument('--cmake-path',
                            help='Path to where cmake is installed. Defaults to the system installed one.',
                            default='')
        parser.add_argument('--custom-toolchain-file',
                            help=f'Path to a custom toolchain file if needed.',
                            default=None)
        parser.add_argument('--build-config-file',
                            help=f"Filename of the build config file within the base_path. Defaults to '{DEFAULT_BUILD_CONFIG_FILENAME}'.",
                            default=DEFAULT_BUILD_CONFIG_FILENAME)
        parser.add_argument('--clean',
                            help=f"Option to clean the build folder for a clean rebuild",
                            action="store_true")
        parser.add_argument('--build-path',
                            help="Path to build the repository in. Defaults to {base_path}/temp.")
        parser.add_argument('--source-path',
                            help='Path to a folder. Can be used to specify the git sync folder or provide an existing folder with source for the library.',
                            default=None)
        parser.add_argument('--git-skip',
                            help='skips all git commands, requires source-path to be provided',
                            default=False)

        parsed_args = parser.parse_args(sys.argv[1:])

        cmake_path = validate_cmake(f"{parsed_args.cmake_path}/cmake" if parsed_args.cmake_path else "cmake")

        if parsed_args.custom_toolchain_file:
            if os.path.isabs(parsed_args.custom_toolchain_file):
                custom_toolchain_file = parsed_args.custom_toolchain_file
            else:
                custom_toolchain_file = os.path.abspath(parsed_args.custom_toolchain_file)
        else:
            custom_toolchain_file = None

        # Prepare for the build
        build_info = prepare_build(platform_name=parsed_args.platform_name,
                                   base_folder=parsed_args.base_path,
                                   build_folder=parsed_args.build_path,
                                   package_root_folder=parsed_args.package_root,
                                   cmake_command=cmake_path,
                                   toolchain_file=custom_toolchain_file,
                                   build_config_file=parsed_args.build_config_file,
                                   clean=parsed_args.clean,
                                   src_folder=parsed_args.source_path,
                                   skip_git=parsed_args.git_skip)

        # Execute the generation of the 3P folder for packaging
        build_info.execute()

        exit(0)

    except BuildError as err:

        print(err)
        exit(1)

