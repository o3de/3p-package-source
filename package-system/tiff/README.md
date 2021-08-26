# libtiff Build From Source Instructions #
## Prerequisites ##
* 3p-package-scripts (https://github.com/o3de/3p-package-scripts)

## Instructions ##
1. Print packages available. Look for tiff versions to build from source
    ```
    cd 3p-package-source
    python ..\3p-package-scripts\o3de_package_scripts\list_packages.py --search_path .
    ```
2. Build libtiff
    ```
    cd 3p-package-source
    python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . <tiff_version>
    # e.g. tiff_version=tiff-4.2.0.15-windows
    ```
    
3. Build artifacts will be located in the packages folder.