@echo off
setlocal enabledelayedexpansion

REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

REM Set these before running the script
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
if not defined QTARRAY set QTARRAY=(qtbase,qtgraphicaleffects,qtimageformats,qtsvg,qttools,qtwinextras)

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
set CHECKS_FAILED=0
for %%P IN (VCVARS_PATH,TEMP_FOLDER,TARGET_INSTALL_ROOT) do (
    if not exist !%%P! (
        echo %%P not found at !%%P!
        set CHECKS_FAILED=1
    )
)

if %CHECKS_FAILED%==1 goto FAILURE

echo Setting up VS2019
call %VCVARS_PATH% amd64

REM We need jom and ICU to build on Windows
set JOM_PATH=%TEMP_FOLDER%\jom
set ICU_PATH=%TEMP_FOLDER%\icu\bin64

set PATH=%PATH%;%JOM_PATH%;%ICU_PATH%

REM The Qt source directory will get cloned into a local temp\src folder
set BUILD_ROOT=%TEMP_FOLDER%\src
set BUILD_PATH=%BUILD_ROOT%\qtbase

REM For OpenSSL support
set OPENSSL_ROOT=%TEMP_FOLDER%\OpenSSL-1.1.1b-rev2-windows\OpenSSL
set OPENSSL_INCLUDE=%OPENSSL_ROOT%\include
set OPENSSL_LIB_DEBUG=%OPENSSL_ROOT%\debug\lib
set OPENSSL_LIB_RELEASE=%OPENSSL_ROOT%\lib
set INCLUDE=%OPENSSL_INCLUDE%;%INCLUDE%
set LIB=%OPENSSL_LIB_DEBUG%;%OPENSSL_LIB_RELEASE%;%LIB%

REM Base the Tiff of the dependent tiff O3DE package (static)
set TIFF_PREFIX=%TEMP_FOLDER%\tiff-4.2.0.15-rev3-windows\tiff
set TIFF_INCDIR=%TIFF_PREFIX%\include
set TIFF_LIBDIR=%TIFF_PREFIX%\lib

REM  We need to also bring in the zlib dependency since Tiff is a static lib dependency
set ZLIB_PREFIX=%TEMP_FOLDER%\zlib-1.2.11-rev5-windows\zlib
set ZLIB_INCDIR=%ZLIB_PREFIX%\include
set ZLIB_LIBDIR=%ZLIB_PREFIX%\lib

cd %BUILD_PATH%

set _OPTS=-v^
    -prefix %TARGET_INSTALL_ROOT% ^
    -debug-and-release ^
    -force-debug-info ^
    -opensource ^
    -confirm-license ^
    -nomake examples ^
    -nomake tests ^
    -shared ^
    --tiff=system ^
    -opengl dynamic ^
    -openssl-linked ^
    -I %TIFF_INCDIR% ^
    -I %ZLIB_INCDIR% ^
    -L %TIFF_LIBDIR% ^
    -L %ZLIB_LIBDIR%

cmd /c ""%BUILD_ROOT%\configure.bat" %_OPTS%" || goto FAILURE

for %%M IN %QTARRAY% do (
    echo Building %%M...
    jom module-%%M || goto FAILURE
    echo Built %%M.
)

for %%M IN %QTARRAY% do (
    echo Installing %%M...
    jom module-%%M-install_subtargets || goto FAILURE
    echo %%M installed.
)

:FINISH
exit

:FAILURE
echo Build failed, see errors above.
exit 1
