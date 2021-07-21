@echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM
REM SPDX-License-Identifier: Apache-2.0 OR MIT



SET SRC_PATH=temp\src

cd %SRC_PATH%

REM Call the build and test script
call python test.and.py

IF %ERRORLEVEL% NEQ 0 (
    cd ..
    exit /b 1
) ELSE (
    cd ..
    exit /b 0
)


