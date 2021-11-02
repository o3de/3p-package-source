 @echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM

SET SRC_PATH=temp\src
SET BLD_PATH=temp\build

cmake -S %SRC_PATH% -B %BLD_PATH% -G "Visual Studio 16 2019" -A x64 -T host=x64 -DDISABLE_QMAKE_BUILD=ON -DBUILD_APPS=OFF -DOPENMESH_DOCS=OFF -DOPENMESH_BUILD_SHARED=OFF -DOPENMESH_BUILD_UNIT_TESTS=OFF
IF %ERRORLEVEL% NEQ 0 (
    ECHO CMake Configuration Error
    exit /b 1
)

cmake --build %BLD_PATH% --config Debug
IF %ERRORLEVEL% NEQ 0 (
    ECHO CMake Build Debug Error
    exit /b 1
)

cmake --build %BLD_PATH% --config Release
IF %ERRORLEVEL% NEQ 0 (
    ECHO CMake Build Release Error
    exit /b 1
)

exit /b 0

