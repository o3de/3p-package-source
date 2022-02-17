# GameLiftServerSdk C++
## Documentation
You can find the official GameLift documentation [here](https://aws.amazon.com/documentation/gamelift/).

## Minimum requirements:
* Either of the following:
  * Microsoft Visual Studio 2019 - Windows Build
  * Clang 12.0 and GCC 9.3 - Linux Build
* CMake version 3.20 or later
* Python version 3.7 or later
* A Git client available on the PATH

## Build the GameLiftServerSdk - Linux
Link Clang compiler for cmake build, for example:
```
$ sudo ln -s /usr/lib/llvm-12/bin/clang /usr/bin/clang
```
```
$ sudo ln -s /usr/lib/llvm-12/bin/clang++ /usr/bin/clang++ 
```

## FAQ
* For windows build, if you get error message `The specified path, file name, or both are too long. The fully qualified file name must be less than 260 characters, and the directory name must be less than 248 characters`
  Please move `3p-package-source` directory out of nested directories and retry.

