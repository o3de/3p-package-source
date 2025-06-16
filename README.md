# 3p-package-source repo

This is where the "sources" (ie, build scripts which make packages) for the O3DE package system are located.

Note that the "sources" of most packages are not actually stored here, most "package sources" actually just consist of a script which fetches the source code (or prebuilt packages) from somewhere else, constructs a temporary folder image for it, and then lets the package system pack that folder up as the package.

In general
 * Add your new package to the appropriate package_build_list_host_xxxx file
 * Put the scripts or instructions to construct the package image folder into the package-system subfolder

Recommendation would be to make any temp packing in a folder called **/temp/** so as to use the current git ignores.

Some notable examples
 * xxhash - a tiny header-only library that is just committed-as-is since it fits in git.  No build scripts.
 * OpenSSL - this one uses vcpkg to build the package image.
 * Lua - this one uses a script called pull_and_build_from_git.py (in Scripts/extras) to build the package image.

 See the documentation (README.md in [3p-package-scripts repo](https://github.com/o3de/3p-package-scripts) for a full description of how to author packages.)
 
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
