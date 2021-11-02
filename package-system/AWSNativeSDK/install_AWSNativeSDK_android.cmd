@echo off
REM
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM

SET BLD_PATH=temp\build
SET SRC_PATH=temp\src
SET INST_PATH=temp\install

SET OUT_BIN_PATH=%TARGET_INSTALL_ROOT%\bin
mkdir %OUT_BIN_PATH%\Debug
mkdir %OUT_BIN_PATH%\Release

SET OUT_INCLUDE_PATH=%TARGET_INSTALL_ROOT%\include
mkdir %OUT_INCLUDE_PATH%

SET OUT_LIB_PATH=%TARGET_INSTALL_ROOT%\lib
mkdir %OUT_LIB_PATH%\Debug\dependencies
mkdir %OUT_LIB_PATH%\Release\dependencies

REM CMake Install Debug and 3rdParty
ECHO "CMake Install Debug Shared to %INST_PATH%"
call cmake --install %BLD_PATH%\Debug_Shared --prefix %INST_PATH% --config Debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Install Debug Shared to %INST_PATH% failed"
    exit /b 1
)

ECHO "CMake Install Debug Static to %INST_PATH%"
call cmake --install %BLD_PATH%\Debug_Static --prefix %INST_PATH% --config Debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Install Debug Static to %INST_PATH% failed"
    exit /b 1
)

call:CopyDynamicAndStaticLibs "Debug"
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

REM CMake Install Release and 3rdParty
ECHO "CMake Install Release Shared to %INST_PATH%"
call cmake --install %BLD_PATH%\Release_Shared --prefix %INST_PATH% --config Release
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Install Release Shared to %INST_PATH% failed"
    exit /b 1
)

ECHO "CMake Install Release Static to %INST_PATH%"
call cmake --install %BLD_PATH%\Release_Static --prefix %INST_PATH% --config Release
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Install Release Static to %INST_PATH% failed"
    exit /b 1
)

call:CopyDynamicAndStaticLibs "Release"
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

REM Copy include headers
ECHO "Copying include headers to %OUT_INCLUDE_PATH%"
Xcopy %INST_PATH%\include\* %OUT_INCLUDE_PATH% /E /Y
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying include headers to %OUT_INCLUDE_PATH% failed"
    exit /b 1
)

REM Copy license
ECHO "Copying LICENSE.TXT to %TARGET_INSTALL_ROOT%"
copy /Y %SRC_PATH%\LICENSE.TXT %TARGET_INSTALL_ROOT%
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying LICENSE.TXT to %TARGET_INSTALL_ROOT% failed"
    exit /b 1
)

ECHO "Custom Install for AWSNativeSDK finished successfully"
exit /b 0

:CopyDynamicAndStaticLibs
SET BUILD_TYPE=%~1
ECHO "Copying shared .so to %OUT_BIN_PATH%\%BUILD_TYPE%"
copy /Y %INST_PATH%\lib\%BUILD_TYPE%_Shared\*.so %OUT_BIN_PATH%\%BUILD_TYPE%\
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying shared .so to %OUT_BIN_PATH%\%BUILD_TYPE% failed"
    exit /b 1
)

ECHO "Copying static .a to %OUT_LIB_PATH%\%BUILD_TYPE%"
copy /Y %INST_PATH%\lib\%BUILD_TYPE%_Static\*.a %OUT_LIB_PATH%\%BUILD_TYPE%\
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying static .a to %OUT_LIB_PATH%\%BUILD_TYPE% failed"
    exit /b 1
)

ECHO "Copying curl openssl and zlib static .a to %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies"
copy /Y %BLD_PATH%\%BUILD_TYPE%_Static\external-install\curl\lib\*.a %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies\
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying 3rdParty static .a to %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies failed"
    exit /b 1
)

copy /Y %BLD_PATH%\%BUILD_TYPE%_Static\external-install\openssl\lib\*.a %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies\
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying 3rdParty static .a to %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies failed"
    exit /b 1
)

copy /Y %BLD_PATH%\%BUILD_TYPE%_Static\external-install\zlib\lib\*.a %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies\
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Copying 3rdParty static .a to %OUT_LIB_PATH%\%BUILD_TYPE%\dependencies failed"
    exit /b 1
)
GOTO:EOF