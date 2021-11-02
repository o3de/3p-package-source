 @echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM


REM Use a custom install script which does the same as using the normal cmake install parameters
REM but also add the pdb file for OpenMeshCored.lib into the installed lib folder as well

SET BLD_PATH=temp\build
SET SRC_PATH=temp\src
SET LIB_PATH=%TARGET_INSTALL_ROOT%\lib

echo cmake --install %BLD_PATH% --prefix %TARGET_INSTALL_ROOT% --config Debug
cmake --install %BLD_PATH% --prefix %TARGET_INSTALL_ROOT% --config Debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to cmake install OpenMesh for Debug
    exit /b 1
)

echo cmake --install %BLD_PATH% --prefix %TARGET_INSTALL_ROOT% --config Release
cmake --install %BLD_PATH% --prefix %TARGET_INSTALL_ROOT% --config Release
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to cmake install OpenMesh for Release
    exit /b 1
)

REM Prepare and copy the pdb files for Core
copy /Y %BLD_PATH%\src\OpenMesh\Core\Debug\OpenMeshCored.pdb %LIB_PATH%\OpenMeshCored.pdb
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy OpenMeshCored.pdb
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

