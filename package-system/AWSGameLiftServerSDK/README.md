# GameLiftServerSdk C++
## Documentation
You can find the official GameLift documentation [here](https://aws.amazon.com/documentation/gamelift/).

## Minimum requirements:
* Either of the following:  
  * Microsoft Visual Studio 2017 - Windows Build
  * Clang 6.0 - Linux Build
* CMake version 3.1 or later
* Python version 3.6 or later
* A Git client available on the PATH

## Build the GameLiftServerSdk - Windows
1. Download the latest [GameLift Server SDK](https://aws.amazon.com/gamelift/getting-started/) 
   and unzip source `GameLift-Cpp-ServerSDK-{version-number}`
   
2. Copy and put `package-system/AWSGameLiftServerSDK/build_and_package.py` and `package-system/AWSGameLiftServerSDK/gamelift-sdk.json` 
   into `GameLift-Cpp-ServerSDK-{version-number}` directory in step 1
   
3. Run the python script `build_and_package.py` under `GameLift-Cpp-ServerSDK-{version-number}` directory, like
   ```
   & python build_and_package.py --config gamelift-sdk.json --platform windows --version 3.4.1
   ```
   
4. Build package will be located under `GameLift-Cpp-ServerSDK-{version-number}/build/{version-number}` directory

5. Copy and put build package into `package-system/AWSGameLiftServerSDK/windows/AWSGameLiftServerSDK`, for example
   ``` 
   - AWSGameLiftServerSDK
     - bin
     - include
     - lib
     - LICENSE_AMAZON_GAMELIFT_SDK.txt
     - NOTICE_C++_AMAZON_GAMELIFT_SDK.txt
   ```
6. Update `package-system/AWSGameLiftServerSDK/windows/PackageInfo.json` with built version `PackageName`

7. Update `<3p-package-source path>/package_build_list_host_windows.json` with updated `PackageName` in step 6

## Build the GameLiftServerSdk - Linux
1. Download the latest [GameLift Server SDK](https://aws.amazon.com/gamelift/getting-started/) 
   and unzip source `GameLift-Cpp-ServerSDK-{version-number}`
    
2. Copy and put `package-system/AWSGameLiftServerSDK/build_and_package.py`, `package-system/AWSGameLiftServerSDK/gamelift-sdk.json` 
   and `package-system/AWSGameLiftServerSDK/AWSGameLiftServerSDK_3.4.1.patch` into `GameLift-Cpp-ServerSDK-{version-number}` directory in step 1

3. Link Clang compiler for cmake build (if `/usr/bin/clang` and `/usr/bin/clang++` symlink exist already, 
   please remove them first `sudo rm /usr/bin/clang /usr/bin/clang++`)
   ```
   $ sudo ln -s /usr/bin/clang-6.0 /usr/bin/clang
   ```
   ```
   $ sudo ln -s /usr/bin/clang++-6.0 /usr/bin/clang++ 
   ```

4. Patch `External_boost.cmake` under `GameLift-Cpp-ServerSDK-{version-number}/cmake`
   to make sure boost library get build with correct toolset (clang-6.0 for example) and variants
   * Under `GameLift-Cpp-ServerSDK-{version-number}` directory, run command `git init` to init a local git repository with current directory
   * Run command `git add .` to stage all existing files
   * Run command `git commit -m "init commit"` to commit your existing files
   * Run command `git apply --ignore-space-change --ignore-whitespace AWSGameLiftServerSDK_3.4.1.patch` to apply patch 
   * Run command `git diff` to check expected changes like
     ```diff
          BUILD_COMMAND b2 address-model=${am} ${boost_with_args}
        )
      else()
     +  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
     +    set(_build_variant "debug")
     +  else()
     +    set(_build_variant  "release")
     +  endif()
     +
        list(APPEND boost_with_args
     -    "cxxflags=-fPIC")
     +    "cxxflags=-fPIC" "toolset=clang-6.0" "variant=${_build_variant}")
        set(boost_cmds
          CONFIGURE_COMMAND ./bootstrap.sh --prefix=<INSTALL_DIR>
          BUILD_COMMAND ./b2 address-model=${am} ${boost_with_args}
     ```

5. Run the python script `build_and_package.py` under `GameLift-Cpp-ServerSDK-{version-number}` directory, like
   ```
   & python3 build_and_package.py --config gamelift-sdk.json --platform linux --version 3.4.1
   ```

6. Build package will be located under `GameLift-Cpp-ServerSDK-{version-number}/build/{version-number}` directory

7. Copy and put build package into `package-system/AWSGameLiftServerSDK/linux/AWSGameLiftServerSDK`, for example
   ``` 
   - AWSGameLiftServerSDK
     - include
     - lib
     - LICENSE_AMAZON_GAMELIFT_SDK.txt
     - NOTICE_C++_AMAZON_GAMELIFT_SDK.txt
   ```
8. Update `package-system/AWSGameLiftServerSDK/linux/PackageInfo.json` with built version `PackageName`

9. Update `<3p-package-source path>/package_build_list_host_linux.json` with updated `PackageName` in step 6

## FAQ
* For windows build, use `--msbuild_path` argument to specify msbuild executable path if msbuild is unrecognized as a valid command, like
  ```
  & python build_and_package.py --config gamelift-sdk.json --platform windows --version 3.4.1 --msbuild_path "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"
  ```

* For windows build, if you get error message `The specified path, file name, or both are too long. The fully qualified file name must be less than 260 characters, and the directory name must be less than 248 characters`
  Please move `GameLift-Cpp-ServerSDK-{version-number}` directory out of nested directories and retry.

* This SDK is known to work with these CMake generators:
  * Visual Studio 15 2017 Win64
  * Visual Studio 14 2015 Win64
  * Visual Studio 12 2013 Win64
  * Visual Studio 11 2012 Win64
  * Unix MakeFiles
    
  By default, we use `vs2017` for windows build and `clang-6.0` for linux build.
  Please update `gamelift-sdk.json` platform configs: **archs** and **toolchains** if need to change cmake generator.