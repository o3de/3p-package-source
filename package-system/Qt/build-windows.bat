@echo off
setlocal enabledelayedexpansion

REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

REM Set these before running the script
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if not defined QTARRAY set QTARRAY=qtbase,qtimageformats,qtsvg

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
set CHECKS_FAILED=0
for %%P IN (VCVARS_PATH,TEMP_FOLDER,TARGET_INSTALL_ROOT) do (
    if not exist !%%P! (
        echo %%P not found at !%%P!
        set CHECKS_FAILED=1
    )
)

if %CHECKS_FAILED%==1 goto FAILURE

echo Setting up VS2022
call %VCVARS_PATH% amd64

REM The Qt source directory will get cloned into a local temp\src folder
set BUILD_ROOT=%TEMP_FOLDER%\src
set BUILD_PATH=%TEMP_FOLDER%\build

REM For OpenSSL support
set OPENSSL_ROOT=%TEMP_FOLDER%\OpenSSL-1.1.1o-rev1-windows\OpenSSL
set OPENSSL_INCLUDE=%OPENSSL_ROOT%\include
set OPENSSL_LIB_DEBUG=%OPENSSL_ROOT%\debug\lib
set OPENSSL_LIB_RELEASE=%OPENSSL_ROOT%\lib
set INCLUDE=%OPENSSL_INCLUDE%;%INCLUDE%
set LIB=%OPENSSL_LIB_DEBUG%;%OPENSSL_LIB_RELEASE%;%LIB%

cd %BUILD_PATH%

set _OPTS=-prefix %TARGET_INSTALL_ROOT% ^
    -submodules %QTARRAY% ^
    -debug-and-release ^
    -force-debug-info ^
    -opensource ^
    -shared ^
    -opengl dynamic ^
    -openssl-linked

cmd /c ""%BUILD_ROOT%\configure.bat" %_OPTS%" || goto FAILURE

cmd /c cmake --build . --parallel || goto FAILURE

cmd /c ninja install || goto FAILURE

:FINISH
exit

:FAILURE
echo Build failed, see errors above.
exit 1
