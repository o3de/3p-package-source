@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #
@rem #

rmdir /S /Q  temp\build_test
mkdir temp\build_test

@rem in this case, we really just want to make sure the package is found successfully

@rem CMAKE demands forward slashes but PACKAGE_ROOT is in native path:
set "PACKAGE_ROOT=%PACKAGE_ROOT:\=/%"
set "DOWNLOADED_PACKAGE_FOLDERS=%DOWNLOADED_PACKAGE_FOLDERS:\=/%"

cmake -S test/find-using-config -B temp/build_test/find-using-config ^
    -G "Visual Studio 17 2022" ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%;%PACKAGE_ROOT%" || exit /b 1

cmake -S test/find-using-module -B temp/build_test/find-using-module ^
    -G "Visual Studio 17 2022" ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%;%PACKAGE_ROOT%" || exit /b 1

cmake --build temp/build_test/find-using-config --config Release  || exit /b 1
cmake --build temp/build_test/find-using-config --config Debug  || exit /b 1
cmake --build temp/build_test/find-using-module --config Release  || exit /b 1
cmake --build temp/build_test/find-using-module --config Debug  || exit /b 1

temp\build_test\find-using-config\Release\test_imath.exe || exit /b 1
temp\build_test\find-using-config\Debug\test_imath.exe || exit /b 1
temp\build_test\find-using-module\Release\test_imath.exe || exit /b 1
temp\build_test\find-using-module\Debug\test_imath.exe || exit /b 1


exit /b 0
