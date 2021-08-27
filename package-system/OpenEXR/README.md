# Ilmbase Build From Source Instructions #
## Prerequisites ##
* 3p-package-scripts (https://github.com/o3de/3p-package-scripts)

## Instructions ##
1. Print packages available. Look for zlib and ilmbase versions to build from source
    ```
    cd 3p-package-source
    python ..\3p-package-scripts\o3de_package_scripts\list_packages.py --search_path .
    ```
2. Build zlib
    ```
    cd 3p-package-source
    python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . <zlib_version>
    # e.g. zlib_version=zlib-1.2.11-rev1-windows
    ```
3. Build ilmbase
    ```
    cd 3p-package-source
    python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . <ilmbase_version>
    # e.g. ilmbase_version=ilmbase-2.3.0-rev4-windows
    ```
4. Build artifacts will be located in the packages folder.