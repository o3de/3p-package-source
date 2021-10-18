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
if not defined QTARRAY set QTARRAY=(qtbase,qtgraphicaleffects,qtimageformats,qtsvg,qttools,qtwebengine)

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

REM We use Miniconda to get a Python 2.7 executable, which is needed for WebEngine to build
set MINICONDA_PATH=%TEMP_FOLDER%\miniconda

set PATH=%MINICONDA_PATH%;%PATH%;%JOM_PATH%;%ICU_PATH%

REM Replace PYTHONPATH with our Miniconda Python paths so that only the Python 2.7 from Miniconda
REM will be found. Otherwise, there will be an invalid syntax error in site.py because the build
REM machine will likely have a different version of Python (most likely Python 3) on the PATH,
REM and since the build_package script will be launched from the Python 3 that is pulled down
REM for O3DE, its paths will be in the PATH as well.
set PYTHONPATH=%MINICONDA_PATH%;%MINICONDA_PATH%\Lib

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
    -opengl dynamic ^
    -openssl-linked

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
