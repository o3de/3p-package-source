@echo off

REM
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM
REM

REM Note: both the executable and static library are packed in the package. Only the static library is used in O3DE. 
REM       The executable is for debugging purpose and it's not required to build O3DE gems or projects.

SET BIN_PATH=%TARGET_INSTALL_ROOT%\bin
SET INCLUDE_PATH=%TARGET_INSTALL_ROOT%\include

mkdir %INCLUDE_PATH%
mkdir %BIN_PATH%
mkdir %BIN_PATH%\Release
mkdir %BIN_PATH%\Debug

copy /Y temp\src\LICENSE.TXT %TARGET_INSTALL_ROOT%\
copy /Y temp\src\Source\astcenc.h %INCLUDE_PATH%

SET BUILD_PATH=temp\build\Source

copy /Y %BUILD_PATH%\Release\*.exe %BIN_PATH%\Release\
copy /Y %BUILD_PATH%\Release\*.lib %BIN_PATH%\Release\

copy /Y %BUILD_PATH%\Debug\*.exe %BIN_PATH%\Debug\
copy /Y %BUILD_PATH%\Debug\*.lib %BIN_PATH%\Debug\

exit /b 0
