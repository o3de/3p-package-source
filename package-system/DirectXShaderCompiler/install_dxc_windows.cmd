 @echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM

SET BLD_PATH=temp\build
SET SRC_PATH=temp\src
SET BIN_PATH=%TARGET_INSTALL_ROOT%\bin


REM Locate the Windows Kit 10 installation path to get the dxil.dll located inside the Redist/D3D folder
set REG_QUERY=REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
set WINKIT_ROOT=
for /F "tokens=1,2*" %%A in ('%REG_QUERY% /v InstallationFolder') do (
  if "%%A"=="InstallationFolder" (
    set WINKIT_ROOT=%%C
  )
)
set DXIL_PATH="%WINKIT_ROOT%\Redist\D3D\x64\dxil.dll"
IF NOT EXIST %DXIL_PATH% (
    echo Unable to find dxil.dll. Make sure that Windows Kit is installed
    exit /b 1
)


mkdir %BIN_PATH%\Release

echo Copying LICENSE.TXT to %TARGET_INSTALL_ROOT%
copy /Y %SRC_PATH%\\LICENSE.TXT %TARGET_INSTALL_ROOT%\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy LICENSE.TXT
    exit /b 1
)

mkdir %BIN_PATH%\Debug
echo Copying %BLD_PATH%\Debug\bin\dxc.exe to %BIN_PATH%\Debug\
copy /Y %BLD_PATH%\Debug\bin\dxc.exe %BIN_PATH%\Debug\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %BLD_PATH%\Debug\bin\dxc.exe
    exit /b 1
)

echo Copying %BLD_PATH%\Debug\bin\dxcompiler.dll to %BIN_PATH%\Debug\
copy /Y %BLD_PATH%\Debug\bin\dxcompiler.dll %BIN_PATH%\Debug\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %BLD_PATH%\Debug\bin\dxcompiler.dll
    exit /b 1
)

echo Copying %DXIL_PATH% to %BIN_PATH%\Debug\
copy /Y %DXIL_PATH% %BIN_PATH%\Debug\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %DXIL_PATH%
    exit /b 1
)

mkdir %BIN_PATH%\Release

echo Copying %BLD_PATH%\Release\bin\dxc.exe to %BIN_PATH%\Release\
copy /Y %BLD_PATH%\Release\bin\dxc.exe %BIN_PATH%\Release\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %BLD_PATH%\Release\bin\dxc.exe
    exit /b 1
)

ECHO Copying %BLD_PATH%\Release\bin\dxcompiler.dll to %BIN_PATH%\\Release\
copy /Y %BLD_PATH%\Release\bin\dxcompiler.dll %BIN_PATH%\\Release\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %BLD_PATH%\Release\bin\dxcompiler.dll
    exit /b 1
)

ECHO Copying DXIL_PATH to %BIN_PATH%\Release\
copy /Y %DXIL_PATH% %BIN_PATH%\Release\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy %DXIL_PATH%
    exit /b 1
)

exit /b 0




