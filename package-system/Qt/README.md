# QT O3DE 3rd Party Package




## Prerequisites

1. **Python 3.10+** or higher installed
1. Python package `boto3`
1. [3p-package-scripts](https://github.com/o3de/3p-package-scripts) cloned locally at the same directory level as the local [3p-package-source](https://github.com/o3de/3p-package-source)


## Updating

When creating updates to the package, the rev number needs to be bumped as a minimum in order to represent a new package. If a new version of Qt is being used as the base source code, then the full version number needs to be updated. 

In `build_config.json`, the following lines control the git url and tag/commit that is used to pull the source code from. 
```
    "git_url": "https://github.com/o3de/qt5.git",
    "git_tag": "5.15.1-o3de",
    "git_commit": "b3a1a6947422928e8aecb14ad607199e9720d266",
```

To control the version and rev of the package, the entry for `package_version` is used. For Qt, the package versioning is specific to the target platform, so this key resides inside each target platform's definition block. 

```
        "Windows": {
            "Windows": {
                "package_version": "5.15.2-rev7",
                ...
            }
        },
        "Darwin": {
            "Mac": {
                ...
                "package_version": "5.15.2-rev8",
                ...
            }
        },
        "Linux": {
            "Linux": {
                "package_version": "5.15.2-rev10",
                ...
            },
	        "Linux-aarch64": {
                "package_version": "5.15.2-rev10",
                ...
            }
        }
```
The package version controls path and filename of the target package. The target file name will be built following the pattern of qt-${package_version}-${platform_lower} where `platform_lower` will be one of the following depending on the target platform/architecture:

1. windows
1. linux
1. linux-aarch64
1. mac

Then, depending on the platform, the package manifest file needs to be updated with this new folder name. Each manifest file is specific to the HOST platform that the package is being built on. (In the case of Linux, if the architecture is aarch64, then the package manifest file has an additional `-aarch64` suffix to the name). 

The values in the corresponding `build_from_source` and `build_from_folder` needs to be updated to reflect the new name of the package if changed.

## Building 

The following build command line examples are based on the current values of the package names by platform. If a new version is being being built, update the command lines below as needed.

### Windows

```
python ..\3p-package-scripts\o3de_package_scripts\build_package.py --search_path . qt-5.15.2-rev10-windows
```

## Linux

### amd64
```
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-5.15.2-rev10-linux
```

### aarch64
```
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-5.15.2-rev10-linux-aarch64
```

## Mac

```
python3 ../3p-package-scripts/o3de_package_scripts/build_package.py --search_path . qt-5.15.2-rev8-mac

```
