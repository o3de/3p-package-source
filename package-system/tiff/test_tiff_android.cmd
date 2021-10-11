@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #
@rem #

rmdir /S /Q  temp\build_test
mkdir temp\build_test

@rem CMAKE demands forward slashes but PACKAGE_ROOT is in native path:
set "PACKAGE_ROOT=%PACKAGE_ROOT:\=/%"
set "DOWNLOADED_PACKAGE_FOLDERS=%DOWNLOADED_PACKAGE_FOLDERS:\=/%"

cmake -S test -B temp/build_test ^
    -G Ninja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/Android/Toolchain_android.cmake ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%;%PACKAGE_ROOT%" || exit /b 1

cmake --build temp/build_test --parallel || exit /b 1

@rem we can't actually run this - its an android binary.  But at least the above
@rem makes sure it links and that our FindTIFF script is working.

exit /b 0
