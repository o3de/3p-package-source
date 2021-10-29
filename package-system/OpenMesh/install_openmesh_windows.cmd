 @echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM

SET BLD_PATH=temp\build
SET SRC_PATH=temp\src
SET INCLUDE_PATH=%TARGET_INSTALL_ROOT%\include
SET LIB_PATH=%TARGET_INSTALL_ROOT%\lib

REM Prepare and Copy the include files for Core
mkdir %INCLUDE_PATH%
mkdir %INCLUDE_PATH%\OpenMesh
mkdir %INCLUDE_PATH%\OpenMesh\Core

xcopy %SRC_PATH%\src\OpenMesh\Core\*.hh %INCLUDE_PATH%\OpenMesh\Core /S /I /F /Y

REM Prepare and copy the debug and pdb files for Core
mkdir %LIB_PATH%
mkdir %LIB_PATH%\debug
copy /Y %BLD_PATH%\Build\lib\OpenMeshCored.lib %LIB_PATH%\debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy OpenMeshCored.lib
    exit /b 1
)
copy /Y %BLD_PATH%\src\OpenMesh\Core\Debug\OpenMeshCored.pdb %LIB_PATH%\debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy OpenMeshCored.pdb
    exit /b 1
)

mkdir %LIB_PATH%\release
copy /Y %BLD_PATH%\Build\lib\OpenMeshCore.lib %LIB_PATH%\release
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy OpenMeshCore.lib
    exit /b 1
)

echo Copying LICENSE to %TARGET_INSTALL_ROOT%
copy /Y %SRC_PATH%\\LICENSE %TARGET_INSTALL_ROOT%\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy LICENSE
    exit /b 1
)

echo Copying VERSION to %TARGET_INSTALL_ROOT%
copy /Y %SRC_PATH%\\VERSION %TARGET_INSTALL_ROOT%\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy VERSION
    exit /b 1
)

exit /b 0

