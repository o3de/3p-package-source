@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #
@rem #

@rem The expected OPENSSL_VERSION_TEXT and its sha1sum (Refer to build_package_image.py for the current version being built)
set "EXPECTED_OPENSSL_VERSION=OpenSSL 3.6.3 9 Jun 2026"
set "EXPECTED_OPENSSL_VERSION_SHA256=5559d73213aff02be756d7cb30491444c9c21473"

rmdir /S /Q  temp\build_test
mkdir temp\build_test

@rem CMAKE demands forward slashes but PACKAGE_ROOT is in native path:
set "PACKAGE_ROOT=%PACKAGE_ROOT:\=/%"
set "DOWNLOADED_PACKAGE_FOLDERS=%DOWNLOADED_PACKAGE_FOLDERS:\=/%"

cmake -S test -B temp/build_test ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%;%PACKAGE_ROOT%" || exit /b 1

@rem Single-config generators (e.g. Ninja, used by CI) place the exe directly under temp\build_test.
@rem Multi-config generators (e.g. Visual Studio, used by local devs) place it under a Release\/Debug\ subfolder.
cmake --build temp/build_test --parallel --config Release || exit /b 1
if exist temp\build_test\Release\test_OpenSSL.exe (
    temp\build_test\Release\test_OpenSSL.exe "%EXPECTED_OPENSSL_VERSION%" %EXPECTED_OPENSSL_VERSION_SHA256% || exit /b 1
) else (
    temp\build_test\test_OpenSSL.exe "%EXPECTED_OPENSSL_VERSION%" %EXPECTED_OPENSSL_VERSION_SHA256% || exit /b 1
)

cmake --build temp/build_test --parallel --config Debug || exit /b 1
if exist temp\build_test\Debug\test_OpenSSL.exe (
    temp\build_test\Debug\test_OpenSSL.exe "%EXPECTED_OPENSSL_VERSION%" %EXPECTED_OPENSSL_VERSION_SHA256% || exit /b 1
) else (
    temp\build_test\test_OpenSSL.exe "%EXPECTED_OPENSSL_VERSION%" %EXPECTED_OPENSSL_VERSION_SHA256% || exit /b 1
)

exit /b 0
