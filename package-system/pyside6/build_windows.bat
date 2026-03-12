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

echo "cd src"

echo Setup Python Virtual ENV

set LOCAL_PYTHON_BIN=%TEMP_FOLDER%\python-3.10.13-rev1-windows\python\python.exe

echo Created Python Virtual ENV

cd %TEMP_FOLDER%
%LOCAL_PYTHON_BIN% -m venv testenv
call testenv\Scripts\activate
call testenv\Scripts\pip.exe install -r %TEMP_FOLDER%\src\requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo "Failed to create venv"
    exit /B 1
)

cd %TEMP_FOLDER%\src

echo "Installing build dependencies"

ECHO Building Pyside2 (Release)

set LLVM_INSTALL_DIR=%TEMP_FOLDER%\libclang-release_20.1.3-based-windows-vs2019_64\libclang
set PATH=%LLVM_INSTALL_DIR%\bin;%PATH%

call %TEMP_FOLDER%\testenv\Scripts\python.exe setup.py install ^
    --qtpaths=%TEMP_FOLDER%\qt-6.10.2-rev4-windows\qt\bin\qtpaths6.exe ^
    --ignore-git ^
    --parallel=8 ^
    --build-type=all ^
    --skip-docs ^
    --log-level=verbose ^
    --limited-api=yes ^
    --skip-modules=Quick,MultimediaWidgets,Pdf,PdfWidgets,Positioning,Location,NetworkAuth,Nfc,WebEngineQuick,Multimedia,QuickControls2,QuickTest,QuickWidgets,UiToolsPrivate,RemoteObjects,Positioning,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,AxContainer
if %ERRORLEVEL% NEQ 0 (
    echo "Failed to build pyside2 (release)"
    exit /B 1
)
exit /B 0

  