@echo off
setlocal enabledelayedexpansion

REM
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM
REM

REM https://doc.qt.io/qtforpython/gettingstarted-windows.html

echo.
echo TEMP_FOLDER=%TEMP_FOLDER%
echo.

REM Set these before running the script
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if not defined QTARRAY set QTARRAY=qtbase,qtimageformats,qtsvg,qttranslations

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

REM For OpenSSL support
set OPENSSL_ROOT=%TEMP_FOLDER%\OpenSSL-1.1.1o-rev1-windows\OpenSSL
set OPENSSL_INCLUDE=%OPENSSL_ROOT%\include
set OPENSSL_LIB_DEBUG=%OPENSSL_ROOT%\debug\lib
set OPENSSL_LIB_RELEASE=%OPENSSL_ROOT%\lib
set INCLUDE=%OPENSSL_INCLUDE%;%INCLUDE%
set LIB=%OPENSSL_LIB_DEBUG%;%OPENSSL_LIB_RELEASE%;%LIB%


echo "cd src"
cd %TEMP_FOLDER%\src

echo "Installing build dependencies"
%TEMP_FOLDER%\python-3.10.13-rev1-windows\python\python.exe -m pip install -r %TEMP_FOLDER%\src\requirements.txt

set LLVM_INSTALL_DIR=%TEMP_FOLDER%\libclang-release_130-based-windows-vs2019_64\libclang
set PATH=%LLVM_INSTALL_DIR%\bin;%PATH%

echo LLVM_INSTALL_DIR=%LLVM_INSTALL_DIR%
echo PATH=%PATH%

echo Building Pyside6
%TEMP_FOLDER%\python-3.10.13-rev1-windows\python\python.exe setup.py build --qtpaths=%TEMP_FOLDER%\qt-6.10.2-rev1-windows\qt\bin\qtpaths6.exe --build-tests --ignore-git --parallel=8 --build-type=all --debug --limited-api=no --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer

REM  --openssl=c:\path\to\openssl\bin --build-tests --ignore-git --parallel=8
REM %TEMP_FOLDER%\qt-6.10.2-rev1-windows\qt\bin\qtpaths.exe --qtpaths-target=host --qtpaths-query=libexec > qt_host_libexec_path.txt
exit /B 1
