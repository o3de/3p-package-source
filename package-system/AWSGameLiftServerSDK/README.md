# GameLiftServerSdk C++
## Documentation
You can find the official GameLift documentation [here](https://aws.amazon.com/documentation/gamelift/).

## Minimum requirements:
* Either of the following:
  * Microsoft Visual Studio 2017 - Windows Build
  * Clang 12.0 and GCC 9.3 - Linux Build
* CMake version 3.20 or later
* Python version 3.7 or later
* A Git client available on the PATH

## Prepare steps:
1. As there is no public repository for server sdk source code, please double check [Amazon GameLift Release Notes](https://docs.aws.amazon.com/gamelift/latest/developerguide/release-notes.html)
   to confirm server sdk version information
2. Modify `PACKAGE_VERSION`, `GAMELIFT_SERVER_SDK_RELEASE_VERSION` and `GAMELIFT_SERVER_SDK_DOWNLOAD_URL` to update version 
   (Refer to `build_package_image.py` script)
3. [Linux Build] Link Clang compiler for cmake build, for example:
   ```
   $ sudo ln -s /usr/lib/llvm-12/bin/clang /usr/bin/clang
   ```
   ```
   $ sudo ln -s /usr/lib/llvm-12/bin/clang++ /usr/bin/clang++ 
   ```

## FAQ
* For windows build, it is recommend to build with `Visual Studio 17 2022`
* For windows build, if you get error message `The specified path, file name, or both are too long. The fully qualified file name must be less than 260 characters, and the directory name must be less than 248 characters`
  (Refer to [PathTooLongException](https://docs.microsoft.com/en-us/dotnet/api/system.io.pathtoolongexception?view=net-6.0))
  Please move `3p-package-source` directory to shorter path location and retry.

