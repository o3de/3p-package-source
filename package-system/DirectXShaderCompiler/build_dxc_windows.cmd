@echo off
REM
REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 
REM 

SET SRC_PATH=temp\src
SET BLD_PATH=temp\build
SET HCT_PATH=temp\src\utils\hct

SET HCT_START=%HCT_PATH%\\hctstart.cmd

REM Initialize the environment
call %HCT_START% %SRC_PATH% %BLD_PATH%
IF %ERRORLEVEL% NEQ 0 (
    ECHO "%HCT_START% Command Failed"
    exit /b 1
)

REM Make sure TAEF is installed
%PYTHON_BINARY% utils\hct\hctgettaef.py
IF %ERRORLEVEL% NEQ 0 (
    ECHO "utils\hct\hctgettaef.py Command Failed"
    exit /b 1
)

REM Run the build for Release
call utils\hct\hctbuild.cmd -rel -x64 -vs2022 -spirv
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Building Release with hctbuild.cmd -rel -x64 -vs2022 Failed"
    exit /b 1
)

ECHO Custom Build for DirectXShaderCompiler finished successfully
exit /b 0


