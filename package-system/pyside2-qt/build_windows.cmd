@echo off
REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

REM Prerequisites:
REM - Visual Studio 2017 is installed
REM - 7-zip is installed: https://www.7-zip.org/

REM Check whether 7-zip is installed
if not defined ZIP_EXE (
    set ZIP_EXE="C:\Program Files\7-Zip\7z.exe"
)
if not exist %ZIP_EXE% (
    echo "7-zip is not found at %ZIP_EXE%"
    echo "You will need to download and install 7-zip from https://www.7-zip.org/ to unzip the prebuilt clang package"
    echo "Set the ZIP_EXE environment variable to the path of 7z.exe if 7-zip is not installed at the default location C:\Program Files\7-Zip\7z.exe"
    exit 1
)

REM Download the prebuilt clang package from the Qt server. The current version of PySide2 is not compatible with the latest version of clang package.
echo Downloading the prebuilt clang package from the Qt server
call curl https://download.qt.io/development_releases/prebuilt/libclang/libclang-release_80-based-windows-vs2017_64.7z -L -o %TEMP_FOLDER%\libclang-release_80-based-windows-vs2017_64.7z
call %ZIP_EXE% x %TEMP_FOLDER%\libclang-release_80-based-windows-vs2017_64.7z -o%TEMP_FOLDER%\libclang-release_80-based-windows-vs2017_64 -y
REM Set up the environment variables required by the PySide build
set LLVM_INSTALL_DIR=%TEMP_FOLDER%\libclang-release_80-based-windows-vs2017_64\libclang
set PATH=%TEMP_FOLDER%\libclang-release_80-based-windows-vs2017_64\libclang\bin;%TEMP_FOLDER%\cmake-3.10.2-win64-x64\cmake-3.10.2-win64-x64\bin;%PATH%

REM Download CMake version 3.10.2. The current version of PySide2 is not compatible with the latest version of CMake.
echo Downloading CMake (version 3.10.2)
call curl https://github.com/Kitware/CMake/releases/download/v3.10.2/cmake-3.10.2-win64-x64.zip -L -o %TEMP_FOLDER%\cmake-3.10.2-win64-x64.zip
call %ZIP_EXE% x %TEMP_FOLDER%\cmake-3.10.2-win64-x64.zip -o%TEMP_FOLDER%\cmake-3.10.2-win64-x64 -y

REM Get the paths to the package dependencies: Python, Qt and OpenSSL
for /F "tokens=1,2,3 delims=;" %%a in ("%DOWNLOADED_PACKAGE_FOLDERS%") do (
   set LOCAL_PYTHON_EXE=%%a\python\python.exe
   set LOCAL_3P_QTBUILD_PATH=%%b\qt
   set LOCAL_OPENSSL_QTBUILD_PATH=%%c\openssl
)

if not exist %LOCAL_PYTHON_EXE% (
    echo "Missing 3P dependency of python3.7 %LOCAL_PYTHON_EXE%"
    echo "You will need to declare the O3DE version of python as a dependency in build_config.json"
    exit 1
)

REM Get the qt package's qmake location
set LOCAL_3P_QTBUILD_QMAKE_PATH=%LOCAL_3P_QTBUILD_PATH%\bin\qmake.exe
set LOCAL_3P_QTBUILD_LIB_PATH=%LOCAL_3P_QTBUILD_PATH%\lib
if not exist %LOCAL_3P_QTBUILD_QMAKE_PATH% (
    echo "Missing 3P dependency of Qt %LOCAL_3P_QTBUILD_PATH%"
    exit 1
)
set LD_LIBRARY_PATH=%LOCAL_3P_QTBUILD_LIB_PATH%

REM Set up Visual Studio 2017. The current version of PySide2 is not compatible with Visual Studio 2019.
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvars64.bat"
echo Setting up VS2017
call %VCVARS_PATH% amd64

REM Create and activate a Python virtual environment
%LOCAL_PYTHON_EXE% -m venv %TEMP_FOLDER%\.env
call %TEMP_FOLDER%\.env\Scripts\activate

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
echo Building source
pushd %TEMP_FOLDER%\src

echo "Install required dependencies"
python -m pip install -r requirements.txt

echo "python setup.py install --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --limited-api=yes --skip-modules=Qml,Quick,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer,Script,ScriptTools,Charts,DataVisualization --openssl=%LOCAL_OPENSSL_QTBUILD_PATH%"
python setup.py build --qmake=%LOCAL_3P_QTBUILD_QMAKE_PATH% --build-type=all --limited-api=yes --skip-modules=Qml,Quick,QuickWidgets,Positioning,Location,RemoteObjects,Scxml,TextToSpeech,3DCore,3DRender,3DInput,3DLogic,3DAnimation,3DExtras,Multimedia,MultimediaWidgets,AxContainer,Script,ScriptTools,Charts,DataVisualization --openssl=%LOCAL_OPENSSL_QTBUILD_PATH%

popd
REM Deactivate Python virtual environment
call deactivate
exit 0
