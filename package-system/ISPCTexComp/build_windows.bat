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
set tempdir=%ScriptDir%temp
set srcDir=%tempdir%\src

set vswhere_location=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer

echo adding %vswhere_location% to PATH
set PATH=%vswhere_location%;%PATH%

for /f "tokens=*" %%i in ('vswhere -property installationPath') do set VS2019_LOCATION=%%i

echo Using Visual Studio: %VS2019_LOCATION%

if NOT exist "%VS2019_LOCATION%\Common7\Tools\vsdevcmd.bat" (
     echo Could not find visual studio 2019 installed
    exit /B 1
 )
call "%VS2019_LOCATION%\Common7\Tools\vsdevcmd.bat"

echo building release...
msbuild.exe %srcDir%\ispc_texcomp\ispc_texcomp.vcxproj /t:Build /m /nologo /v:m /p:Configuration=Release /p:Platform=x64
if %ERRORLEVEL% NEQ 0 (
  echo Failed to build release ispc_texcomp
  exit /B 1
)
