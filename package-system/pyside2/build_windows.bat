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

SET CURRENT_PATH=%CD%

REM Set these before running the script
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
set CHECKS_FAILED=0
for %%P IN (VCVARS_PATH,TEMP_FOLDER,TARGET_INSTALL_ROOT) do (
    if not exist !%%P! (
        echo %%P not found at !%%P!
        set CHECKS_FAILED=1
    )
)

echo Setting up VS2019
call %VCVARS_PATH% amd64


REM Get the python executable from the package dependency

SET LOCAL_PYTHON37_BIN=%TEMP_FOLDER%\\python-3.10.5-rev1-windows\python\python.exe
IF EXIST %LOCAL_PYTHON37_BIN% (
    echo Using Python located at %LOCAL_PYTHON37_BIN%
) ELSE (
    echo ERROR: Unable to find Python at %LOCAL_PYTHON37_BIN%
    exit /b 1
)


SET LOCAL_3P_QTBUILD_PATH=%TEMP_FOLDER%\qt-5.15.2-rev7-windows\qt
IF EXIST %LOCAL_3P_QTBUILD_PATH% (
    echo Using Qt located at %LOCAL_3P_QTBUILD_PATH%
) ELSE (
    echo ERROR: Unable to find Qt at %LOCAL_3P_QTBUILD_PATH%
    exit /b 1
)
SET LOCAL_3P_QTBUILD_QMAKE_PATH=%LOCAL_3P_QTBUILD_PATH%\bin\qmake.exe
SET LOCAL_3P_QTBUILD_LIB_PATH=%LOCAL_3P_QTBUILD_PATH%\lib

SET LLVM_INSTALL_DIR=%TEMP_FOLDER%\libclang-release_130-based-windows-vs2019_64\libclang
SET PATH=%LLVM_INSTALL_DIR%\bin;%PATH%

echo Created Python Virtual ENV

cd temp
%LOCAL_PYTHON37_BIN% -m venv testenv
call testenv\Scripts\activate
call testenv\Scripts\pip.exe install -r src\requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo "Failed to create venv"
    exit /B 1
)

cd src

echo call ..\testenv\Scripts\activate.bat
call ..\testenv\Scripts\activate.bat

ECHO Building Pyside2 (Debug)

SET PYTHON_LIBRARIES==%TEMP_FOLDER%\python-3.10.5-rev1-windows\python\libs\python39_d.lib
SET PYTHON_DEBUG_LIBRARIES==%TEMP_FOLDER%\python-3.10.5-rev1-windows\python\libs\python39_d.lib

echo call ..\testenv\Scripts\python_d.exe setup.py install --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --debug --limited-api=no --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer
call ..\testenv\Scripts\python_d.exe setup.py install --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --debug --limited-api=no --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer
if %ERRORLEVEL% NEQ 0 (
    echo "Failed to build pyside2 (debug)"
    exit /B 1
)

ECHO Building Pyside2 (Release)

echo call ..\testenv\Scripts\python.exe setup.py install --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer
call ..\testenv\Scripts\python.exe setup.py install --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer
if %ERRORLEVEL% NEQ 0 (
    echo "Failed to build pyside2 (release)"
    exit /B 1
)

echo call ..\testenv\Scripts\deactivate.bat
call ..\testenv\Scripts\deactivate.bat

cd %CURRENT_PATH%

exit /B 0
