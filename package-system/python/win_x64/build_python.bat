@setlocal enabledelayedexpansion
@echo off

REM
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM
REM

set ScriptDir=%~dp0
set outputdir=%ScriptDir%package
set tempdir=%ScriptDir%temp
set python_src=%tempdir%\cpython

rem dont allow python to read pip packages from user's local folder
set PYTHONNOUSERSITE=1

echo Building python from source - Basic requirements:
echo     - Visual studio vc141 build tools installed (VS2017).  This can be installed into vs2019 or above.
echo     - git installed
echo. 
echo  ... This will take about 10 minutes ...
echo.

set vswhere_location=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer

echo adding %vswhere_location% to PATH
set PATH=%vswhere_location%;%PATH%

for /f "tokens=*" %%i in ('vswhere -property installationPath') do set VS2017_LOCATION=%%i

echo Using Visual Studio: %VS2017_LOCATION%

if NOT exist "%VS2017_LOCATION%\Common7\Tools\vsdevcmd.bat" (
     echo Could not find visual studio 2017 installed
    exit /B 1
 )
call "%VS2017_LOCATION%\Common7\Tools\vsdevcmd.bat"


echo Clearing %tempdir% if present...
rmdir /s /q %tempdir% > NUL
echo Clearing %outputdir% if present...
rmdir /s /q %outputdir% > NUL

mkdir %outputdir%
mkdir %tempdir%
cd /d %tempdir%

echo Cloning python from git using v3.7.10...
git clone https://github.com/python/cpython.git --branch "v3.7.10" --depth 1
if %ERRORLEVEL% NEQ 0 (
    echo "Git clone failed"
    exit /B 1
)

cd /d %python_src%
call .\PCBuild\get_externals.bat

msbuild.exe "%python_src%\PCbuild\pcbuild.proj" /t:Build /m /nologo /v:m /p:Configuration=Debug /p:Platform=x64 /p:IncludeExternals=true /p:IncludeSSL=true /p:IncludeTkinter=true /p:PlatformToolset=v141
if %ERRORLEVEL% NEQ 0 (
  echo Failed to build debug python
  exit /B 1
)
echo building release...
msbuild.exe "%python_src%\PCbuild\pcbuild.proj" /t:Build /m /nologo /v:m /p:Configuration=Release /p:Platform=x64 /p:IncludeExternals=true /p:IncludeSSL=true /p:IncludeTkinter=true /p:PlatformToolset=v141
if %ERRORLEVEL% NEQ 0 (
  echo Failed to build release python
  exit /B 1
)

cd /d %python_src%
echo installing PIP...
.\PCBuild\amd64\Python.exe  -m ensurepip --upgrade
if %ERRORLEVEL% NEQ 0 (
  echo Failed to ensure pip is present.
  exit /B 1
)
.\PCBuild\amd64\Python.exe -m pip install --upgrade pip

echo creating the installation image...
rem We'll actually use the real python dist builder to do this:
cd /d %python_src%
.\PCBuild\amd64\python.exe .\PC\layout\main.py --copy %outputdir%\python -v -d --include-stable --include-pip --include-distutils --include-tcltk --include-idle --include-tools --include-venv --include-dev --include-launchers
if %ERRORLEVEL% NEQ 0 (
  echo "Failed to call python's layout script (debug)"
  exit /B 1
)

.\PCBuild\amd64\python.exe .\PC\layout\main.py --copy %outputdir%\python -v --include-stable --include-pip --include-distutils --include-tcltk --include-idle --include-tools --include-venv --include-dev --include-launchers
if %ERRORLEVEL% NEQ 0 (
  echo "Failed to call python's layout script (release)"
  exit /B 1
)

echo copying package metadata and cmake files...
rem But we do add our own few things...
set ROBOCOPY_OPTIONS=/NJH /NJS /NP /NDL
robocopy %ScriptDir% %outputdir% *.cmake PackageInfo.json %ROBOCOPY_OPTIONS%

cd /d %ScriptDir%

echo clearing temp dir...
rmdir /s /q %tempdir%

rem we leave only the output folder which is the actual output for packaging.
echo this folder is ready for packaging: %outputdir%

exit /B 0
