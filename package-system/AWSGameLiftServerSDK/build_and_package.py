#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#

import argparse
import atexit
import itertools
import json
import os
import shutil
import sys

from contextlib import contextmanager


def ParseArguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', required=True, help='The version number of GameLiftServerSDK, e.g. 3.4.1')
    parser.add_argument('--platform', required=True, choices=['windows', 'linux'])
    parser.add_argument('--config', required=True, help='gamelift-sdk.json')
    parser.add_argument('--msbuild_path', help='msbuild executable path for windows platform')

    return parser.parse_args()

@contextmanager
def InDirectory(path):
    prev = os.getcwd()
    os.chdir(path)
    yield
    os.chdir(prev)

class Variant:
    """
    Variant class is used to store variants info for cmake build
    """
    def __init__(self, platform, arch, toolchain, config, libtype):
        self.platform = platform
        self.arch = arch
        self.toolchain = toolchain
        self.config = config
        self.libtype = libtype

    def __str__(self):
        return f'{self.arch}-{self.toolchain}-{self.config}-{self.libtype}'

    __repr__ = __str__

    def GetPath(self):
        return str(self)

    def GetGenerateProjectsCommand(self):
        return f'cmake {self.platform.GetCMakeDefines(self)} {self.platform.GetCMakeGenerator(self)} ..{os.sep}..'

    def GenerateProjects(self):
        projectPath = self.GetPath()
        os.makedirs(projectPath, exist_ok=True)

        with InDirectory(projectPath):
            return os.system(self.GetGenerateProjectsCommand())

        # shouldn't get here, but there is a chance the chdir could fail
        return 1

    def GetBuildCommand(self):
        return self.platform.GetBuildCommand(self)

    def Build(self):
        with InDirectory(self.GetPath()):
            return os.system(self.GetBuildCommand())

    @property
    def lib_extension(self):
        return self.platform.lib_extension

    @property
    def lib_prefix(self):
        return 'lib' if self.platform.name == 'Linux' else ''

    @property
    def shared_lib_extension(self):
        return self.platform.shared_lib_extension

    @property
    def lib_config_suffix(self):
        return 'd' if self.config == 'Debug' and self.platform.name == 'Windows' else ''

class Platform(object):
    """
    Platform class is used to store platform related configs for cmake build
    """
    def __init__(self, archs, toolchains, configs, libtypes):
        self.archs = archs
        self.toolchains = toolchains
        self.configs = configs
        self.libtypes = libtypes

    def GetVariants(self):
        for variant in itertools.product(*[self.archs, self.toolchains, self.configs, self.libtypes]):
            yield Variant(self, variant[0], variant[1], variant[2], variant[3])

    def GetCMakeGenerator(self, variant):
        return ''

    def GetCMakeDefines(self, variant):
        cmakeDefines = ''
        if variant.libtype == 'Shared':
            cmakeDefines += '-DBUILD_SHARED_LIBS=1'

        if variant.config == 'Debug':
            cmakeDefines += ' -DCMAKE_BUILD_TYPE=Debug'

        return cmakeDefines

class WindowsPlatform(Platform):
    """
    WindowsPlatform is used to store windows specific platform configs
    """
    def __init__(self, archs, toolchains, configs, libtypes):
        super(WindowsPlatform, self).__init__(archs, toolchains, configs, libtypes)
        self.name = 'Windows'
        self.lib_extension = 'lib'
        self.shared_lib_extension = 'dll'
        self.msbuild_path = 'msbuild'

    def GetCMakeGenerator(self, variant):
        return '-G "Visual Studio 15 2017 Win64"'

    def GetBuildCommand(self, variant):
        return f'{self.msbuild_path} ALL_BUILD.vcxproj /p:Configuration={variant.config}'
        
    def SetMSBuildPath(self, msbuild_path):
        self.msbuild_path = msbuild_path

class LinuxPlatform(Platform):
    """
    LinuxPlatform is used to store linux specific platform configs
    """
    def __init__(self, archs, toolchains, configs, libtypes):
        super(LinuxPlatform, self).__init__(archs, toolchains, configs, libtypes)
        self.name = 'Linux'
        self.lib_extension = 'a'
        self.shared_lib_extension = 'so'

    def GetCMakeGenerator(self, variant):
        return '-G "Unix Makefiles"'

    def GetCMakeDefines(self, variant):
        # it is necessary until GameLift sdk cmake properly supports clang or passin
        if variant.toolchain.startswith('clang'):
            os.environ['CC'] = 'clang'
            os.environ['CXX'] = 'clang++'
            os.environ['CXXFLAGS'] = '-fPIC'

        defines = super(LinuxPlatform, self).GetCMakeDefines(variant)
        return defines

    def GetBuildCommand(self, variant):
        return 'make'

class Package:
    """
    Package class is used to package the expected files defined in gamelift-sdk.json from build process
    """
    def __init__(self, outputDir, version, noArchFiles, variantFiles, variantSharedFiles, staticLibOutputDir, sharedLibOutputDir):
        self.outputDir = outputDir
        self.version = version
        self.noArchFiles = noArchFiles
        self.variantFiles = variantFiles
        self.variantSharedFiles = variantSharedFiles
        self.staticLibOutputDir = staticLibOutputDir
        self.sharedLibOutputDir = sharedLibOutputDir
        self.variants = []

    def AddVariant(self, variant):
        self.variants.append(variant)

    def Populate(self):
        packageDir = os.path.join(self.outputDir, self.version)

        # remove any existing package dir
        if os.path.isdir(packageDir):
            shutil.rmtree(packageDir)

        # create package outdir
        try:
            os.mkdir(packageDir)
        except OSError:
            print(f'[Error] failed to properly create package dir {packageDir}')
            return

        for fileName in self.noArchFiles:
            self.SmartCopy(fileName, packageDir)

        # copy built libs by variant
        for variant in self.variants:
            self.InstallVariant(variant, packageDir)

    def InstallVariant(self, variant, outdir):
        libDir = self.sharedLibOutputDir if variant.libtype == 'Shared' else self.staticLibOutputDir

        variantOutdir = os.path.join(outdir, libDir, variant.arch, variant.toolchain, variant.config)
        os.makedirs(variantOutdir)

        for fileNameFormat in self.variantFiles:
            fileName = os.path.normpath(os.path.join(self.outputDir, variant.GetPath(), fileNameFormat.format(variant)))
            self.SmartCopy(fileName, variantOutdir)

        if variant.libtype == 'Shared':
            for fileNameFormat in self.variantSharedFiles:
                fileName = os.path.normpath(os.path.join(self.outputDir, variant.GetPath(), fileNameFormat.format(variant)))
                self.SmartCopy(fileName, variantOutdir)

    def SmartCopy(self, src, dst):
        if os.path.isdir(src):
            newdst = os.path.join(dst, os.path.basename(src))
            print(f'Copying Tree: {src} ==> {newdst}')
            shutil.copytree(src, newdst)
        else:
            print(f'Copying: {src} ==> {dst}')
            shutil.copy2(src, dst)

def main():
    args = ParseArguments()

    if not os.path.isfile(args.config):
        print(f'Invalid config file: {args.config}')
        exit(1)

    with open(args.config) as configFile:
        jsonConfig = json.load(configFile)

    outputDir = jsonConfig["OutputDir"]
    os.makedirs(outputDir, exist_ok=True)

    if args.platform == "windows":
        platformConfig = jsonConfig["Platforms"]["Windows"]
        platformFactory = WindowsPlatform
    else:
        platformConfig = jsonConfig["Platforms"]["Linux"]
        platformFactory = LinuxPlatform

    platform = platformFactory(platformConfig["archs"], platformConfig["toolchains"], platformConfig["configs"], platformConfig["libtypes"])
    if args.msbuild_path:
        platform.SetMSBuildPath(f'"{args.msbuild_path}"')

    package = Package(outputDir, args.version, jsonConfig["NoArchFiles"], jsonConfig["VariantFiles"], jsonConfig["VariantSharedFiles"],
        jsonConfig["StaticLibOutputDir"], jsonConfig["SharedLibOutputDir"])
    projectIssues = []
    buildIssues = []

    # Create projects and build
    with InDirectory(outputDir):
        for variant in platform.GetVariants():
            print()
            print(f'########### {variant} ###########')

            print(f'Running: {variant.GetGenerateProjectsCommand()}')
            projectResult = variant.GenerateProjects()
            if projectResult != 0:
                projectIssues.append(variant)
            else:
                print(f'Running: {variant.GetBuildCommand()}')
                buildResult = variant.Build()
                if buildResult != 0:
                   buildIssues.append(variant)

            package.AddVariant(variant)

        print()
        print('########### Report ###########')
        print(f'Project failures: {projectIssues}')
        print(f'Build failures: {buildIssues}')

    print()
    if len(projectIssues) == 0 and len(buildIssues) == 0:
        package.Populate()
        print(f'Package "{args.version}" created in directory "{outputDir}"')
    else:
        print('Skipping package creation due to build errors.')

if __name__ == '__main__':
    main()

