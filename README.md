# 3p-package-source repo

This is the repository that manages the rules and definitions for the pre-built 3rd Party libraries that is consumed by O3DE. For 3rd Party libraries that are declared in the O3DE engine or one of its gems, they are either declared as [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) in cmake, where they are built on demand as part of the overall build compilation, or they are downloaded as prebuilt binaries from the O3DE 3rd Party repository.

This repository contains the scripts, configurations, and custom tools that will package an O3DE 3rd Party package (refer to [Structure of a package](https://github.com/o3de/3p-package-scripts/blob/main/README.md#structure-of-a-package---authoring-side) for detailed information).

# Authoring a 3rd Party package
When deciding how to bring in a 3rd Party library into O3DE, there are different factors you need to consider:

1. Is there already a 3rd Party defined in O3DE to do this
2. Consider the license of the 3rd Party library being brought in.
3. The size and complexity of the library
4. Is the library supported on all platforms that support O3DE

If the 3rd party library does not significantly increase the overall build time and complexity of O3DE, then it is recommended to use [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) instead of creating a new library to build with this system. An example of this can be found in the [RecastNavigation Gem](https://github.com/o3de/o3de/blob/607adb6a1ecfb9e69de3a504963f7fed40ff1552/Gems/RecastNavigation/3rdParty/FindRecastNavigation.cmake#L30).

However, if the 3rd Party Library does increase the build times, or pulls excessive requirements to build, then it is better to use the 3rd Party Packaging system to author the 3rd Party Package.

## Declaring the package
The 3rd party package declarations are defined in the package build lists at the root of the folder, which includes the host platform they are defining the packages for: `package_build_list_host_<platform>.json` where `<platform>` is the current host platform that is running the script. The support host platforms are `windows`, `linux`, `linux-aarch64`, `darwin`, and `darwin-arm64`.

In each of the files, there are two sections that need to be filled out per library:
* **build_from_source** <br>
This section defines the key-value pair of package name to package build command line from source script. The build command can either be a custom batch/shell/python script or one of the provided general build scripts.

* **build_from_folder**
This section defines the key-value pair of package name to package content that the scripts will use to generate the O3DE 3rd Party package and hashes.

Generally, a package name is present in both the `build_from_source` and `build_from_folder` section. When a build for a specific package is started, the scripts will first look in the `build_from_source` section to build the package image, then reference that image in the `build_from_folder` section to generate the final package.

## Using pull_and_build_from_git.py
The `pull_and_build_from_git.py` script is a utility located in `Scripts/extras` that automates the process of cloning a git repository, building it from source, and preparing a package image folder. This is useful for packages where you want to fetch and build sources dynamically rather than committing prebuilt binaries to source control.

### When to Use This Script
Use `pull_and_build_from_git.py` when:
- You want to build a 3rd party package from source at build time
- The source code is hosted in a git repository
- You need to apply patches or custom build configurations
- You want to keep your repository lightweight by avoiding large prebuilt binaries
- The package build process is consistent and reproducible

### Basic Usage
The script is typically invoked from a `build_from_source` entry in the package build list files:

```json
{
    "build_from_source" : {
        "my-package-1.0-multiplatform" : "python Scripts/extras/pull_and_build_from_git.py --repo-uri https://github.com/user/my-package.git --package-name my-package --output-folder ./temp/my-package-image"
    }
}
```

### Common Parameters
- `--repo-uri` : The git repository URL to clone from
- `--package-name` : The name of the package (used in PackageInfo.json)
- `--output-folder` : The destination folder where the package image will be created
- `--branch` : Git branch to checkout (optional, defaults to main/master)
- `--tag` : Git tag to checkout (optional, takes precedence over branch)
- `--build-command` : Custom build command to execute after cloning (optional)

### Workflow Example
1. The script clones the repository to a temporary location
2. Checks out the specified branch or tag
3. Executes any build commands to compile the source
4. Copies the built artifacts and headers to the output folder
5. Generates a valid package image with PackageInfo.json and license file

### Example: Lua Package
The Lua package is a good reference implementation. It uses `pull_and_build_from_git.py` to:
- Clone the Lua repository
- Build Lua from source
- Package the resulting binaries and headers
- Create the package image ready for packing

### Output Structure
After successful execution, the output folder will contain:
```
./temp/my-package-image/
 - PackageInfo.json          (auto-generated or provided)
 - LICENSE                   (copied from source or specified)
 - include/                  (headers)
 - lib/                      (compiled libraries)
 - bin/                      (executables if applicable)
```

### Next Steps
Once `pull_and_build_from_git.py` successfully creates the package image, reference that folder in the `build_from_folder` section of your package build list to package and generate hashes.

## Authoring Packages
The workflow for authoring a package involves creating a folder containing the "Image" of the package to be packed up, then running scripts on that folder to pack it up and generate hashes for the files present.

This is where the "sources" (ie, build scripts which make packages) for the O3DE package system are located.

Note that the "sources" of most packages are not actually stored here, most "package sources" actually just consist of a script which fetches the source code (or prebuilt packages) from somewhere else, constructs a temporary folder image for it, and then lets the package system pack that folder up as the package.

In general:
 * Add your new package to the appropriate package_build_list_host_xxxx file
 * Put the scripts or instructions to construct the package image folder into the package-system subfolder
 * Build the package locally and test with a local copy of O3DE using the package and hash
 * Commit changes and push to your fork
 * Create a Pull Request and request reviews
 * Push packages to production and merge in PR
 * Update O3DE 3P dependency with the updated package name and hash

### Package Image Structure
On the **authoring** side, a package image (ready to pack) is valid as long as there are at least two files present:
 - PackageInfo.json, which describes the package (and must be at the root folder of the package)
 - A license file (such as LICENSE.TXT) that contains the license information. This file can be anywhere in the package.

The PackageInfo "LicenseFile" field must point at the license file, relative to where the PackageInfo.json file is. The PackageInfo 'PackageName' field uniquely identifies a package and is also a unique key for it in terms of uploading / downloading. The "License" field must be a [SPDX license](https://spdx.org/licenses/) identifier or the word "Custom".

```json
{
    "PackageName" : "zlib-1.2.8-multiplatform",
    "URL"         : "https://zlib.net",
    "License"     : "zlib",
    "LicenseFile" : "zlib/LICENSE"
}
```
Note that 'PackageName' is a full identifier of the package and must be unique across all packages used. This is why it includes its name, version, and platform(s) its meant for.

If the PackageInfo.json file is present and the fields are correct (there must also be an actual license file at the location that the PackageInfo.json specifies), then the package is a valid package and will function.

However, even though just these two files make a valid package, the package would not serve any useful purpose. All packages thus also contain their actual payload files (for example, a [FindXXXX.CMake file](https://cmake.org/cmake/help/latest/command/find_package.html#search-modes) as well as headers and libraries, executables, etc).

An example package folder image on the *authoring* side could be:
```
 - PackageInfo.json       <--- required file
 - FindMyLibrary.cmake
 - MyLibrary
   - License.txt          <--- required file, pointed at by PackageInfo.json
   - include
     - MyLibrary
        - mylib.h
   - lib (Directory)
     - windows
       - mylibrary.lib
     - linux
       - mylibrary.a
```
It is convenient to place a Find(LIBRARYNAME).cmake at the root if the package contains libraries or code, because the root of unpacked packages is added to the CMAKE_MODULE_PATH after unpacking (the place where CMake searches for Find*****.cmake files).

## Structure of a package - packaged up
Once you have a package *image* as in the above structure, you use the package build scripts to turn it into a package. This results in the following files being created (by default in the 'packages' sub-folder).
Note that PackageName comes from PackageInfo.json, not the folder names on disk.

 - PackageName.tar.xz
 - PackageName.tar.xz.SHA256SUMS
 - PackageName.tar.xz.content.SHA256SUMS
 - PackageName.PackageInfo.json

The tar.xz file contains the authored package image (described in the prior section) plus a hash of its contents, named content.SHA256SUMS.

The SHA256SUMS file is the SHA256 sum of the actual tar.xz file.

The content.SHA256SUMS file is a standard SHA256SUMS file that lists each file in the archive and has a SHA256 hash for it. (Except for the SHA256SUM file itself). Its the same as the one inside the package tar.xz at the root.

The PackageInfo.json file is just the PackageInfo.json from inside the package.

These four files are whats uploaded to a download site, for the package consumer side to download as needed.

## The package list files
Because package building and uploading is intended to be automated by continuous integration / code review systems, there is a set of package list files which automated systems can use to iterate over all the packages and build/upload them all.

Thus making a package involves creating the above 'package image' folder (either by writing a script to do it or by actually just committing the image to source control) and then also updating the package build list files to mention that folder where the package image now exists.

The package building scripts (discussed later on in this document) expect to be passed a --search-path parameter which tells it where to look for these build list files (usually stored in another folder or repository)

 Given a search path, the scripts will search for files in that path called
 "package_build_list_host_(windows|linux|darwin).json"(host type specific list).

 Note that the host type in the above name indicates which system the package is being built on, not which system its being built *for*.

The package build list file json file format:
```json
{
    "build_from_source" : {
        "package-name" : "build-script-to-run (params)"
        ... n packages
    },
    "build_from_folder" : {
        "package-name" : "folder-name"
        ... n packages
    }
}
```

Note that there is a "build_from_source" as well as a "build_from_folder" section. The above document has so far covered the "build_from_folder" section (where a pre-made package image folder is already present).

In the above, "folder-name" is expected to be relative to the search path specified (ie, the location the host files are kept).
In the above, "build-script-to-run" will use the script relative to the search path, so make sure any scripts used are in the same repository or local to the host files.

The working directory for the build script to run will be the folder containing the build script.

"Build from source" is used when, instead of checking in the actual package binaries to source control, you prefer to check in a script that fetches/builds the binaries from elsewhere. For example, instead of checking in the whole of python pre-compiled, its possible to check in a shell script that will clone the python repo and then build it. In that case, the script's job is to produce a folder image that is then mentioned later on, again, in the "build_from_folder" section, usually by building, then carefully cherrypicking binaries, headers, etc.

When specifying a *multiplatform* package in a list file, pick **ONE** authoratative host platform to build the package on. For example, if a package contains Windows, Mac, and Linux binaries in it, add the package **ONCE** to either the Linux, Mac, or Windows host files. By picking one host type for each package, you reduce the combinatorics involved in "What host produced the same package?" versus what it works on (We don't want to end up in a situation where what host a package was built on can cause subtle bugs even for the same logical package).

Recommendation would be to make any temp packing in a folder called **/temp/** so as to use the current git ignores.

## Using the package script

The `package.bat`/`package.sh` script provides a convenient way to build packages. It automatically locates your Python installation and runs the packaging process.

### Requirements

- Python must be installed and available in your system PATH, or the Python launcher must be installed

### Usage

Run the script from the command line with one of the following commands:

#### Windows
```batch
package.bat list
package.bat build <package-name>
```

#### Linux/Mac
```batch
package.sh list
package.sh build <package-name>
```

### Available Commands

- `list` - List all packages available in the package-system directory, including their hash information and build type
- `build <package-name>` - Build a specific package by name

### How It Works

1. The script locates the `Scripts/packaging/package.py` file in the same directory
2. It checks if Python is available on your system
3. If Python is found, it executes the packaging script with your command
4. Returns the exit code from the Python script

### Troubleshooting

If you see "Python launcher not found" error:
- Install Python from [python.org](https://www.python.org/downloads/)
- Or add your Python installation directory to your system PATH environment variable

## examples

```
package.bat build list
```

```
package.bat build zlib-1.2.11-rev5-windows
```


## Setup Packages Using Prebuilt Libraries
3rdParty packages depend on prebuilt libraries. This allows 3rdParty authors to ship their libraries (.dll, .lib, .so, .a, etc) so customers do not need source code. This section covers how to author packages that depend on prebuilt libraries who also have dependencies of their own.

### The Problem
There was problems early on with O3DE 3rdParty libraries. Many 3rdParties used [CMake interface libraries](https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries). The problem is that interfaces can only control their dependencies, not the hierarchy. For example, the O3DE LibTIFF 3rdParty depends on a prebuilt libtiff.a, and libtiff.a depends on ZLib. As an interface, the old LibTIFF used `target_link_libraries` to link in libtiff.a and ZLib.

```
add_library(3rdParty::TIFF INTERFACE IMPORTED GLOBAL)

target_link_libraries(3rdParty::TIFF INTERFACE ZLIB::ZLIB "${TIFF_LIBRARY}")  # No actual dependency between ZLib and TIFF and thus has undefined link order.
```

This is a flat dependency list, and so there was no way to tell that libtiff.a depends on ZLib. When CMake generates a Makefile it is free to list those libraries in any order. Depending on the order, LibTIFF could fail find ZLib definitions. As a result, a program using the LibTIFF 3rdParty would fail to link.

### The Proper Way to Declare a Prebuilt Library Dependency
Instead of using INTERFACE, use whatever library target type has been prebuilt.

- `add_library(<libname> STATIC IMPORTED)` for a static library

- `add_library(<libname> SHARED IMPORTED)` for a shared library

- `add_library(<libname> MODULE IMPORTED)` for a runtime loadable-ONLY library

Today's LibTIFF is a proper example of how to declare static library dependencies. The 3rdParty [specifies the path to the library file on disk](https://cmake.org/cmake/help/latest/prop_tgt/IMPORTED_LOCATION.html). In this case, 3rdParty::TIFF points to the prebuilt libtiff.a. The 3rdParty, now acting as a wrapper, can tack on dependencies required by the static library.

```
# Add the CMake standard 3rdParty::TIFF library. It is a static library.
add_library(3rdParty::TIFF STATIC IMPORTED GLOBAL)

set_target_properties(3rdParty::TIFF PROPERTIES IMPORTED_LOCATION "${TIFF_LIBRARY}")

target_link_libraries(3rdParty::TIFF INTERFACE ZLIB::ZLIB)
```
