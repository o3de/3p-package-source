# Ilmbase Build From Source Instructions #
## Prerequisites ##
* 3p-package-scripts (https://github.com/o3de/3p-package-scripts)

## To build

set the working directory the the root of the 3p-package-source repository (where the package_build_list* json files are located.)

# mac
    python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . OpenEXR-3.1.3-rev1-mac
# windows
    python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . OpenEXR-3.1.3-rev1-windows
# linux
    python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . OpenEXR-3.1.3-rev1-linux

# on all platforms:

Build artifacts will be located in the packages folder.

## note about iMath library
The iMath library is built as part of OpenEXR but lives in a separate repository.  The build script for OpenEXR will fetch imath and pass the same build parameters that were fed in for OpenEXR when building it.  This means the command line for OpenEXR should contain both OpenEXR-specific parameters like ``OPENEXR_BUILD_TESTS`` but also more generic parameters that iMath will recognise like ``BUILD_TESTING=OFF`` to be passed through.

