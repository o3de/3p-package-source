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
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%;%PACKAGE_ROOT%" || exit /b 1

cmake --build temp/build_test --parallel --config Release || exit /b 1
temp\build_test\Release\test_Freetype.exe || exit /b 1

cmake --build temp/build_test --parallel --config Debug || exit /b 1
temp\build_test\Debug\test_Freetype.exe || exit /b 1

exit /b 0
