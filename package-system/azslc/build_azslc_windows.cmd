@echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM
REM SPDX-License-Identifier: Apache-2.0 OR MIT



SET SRC_PATH=temp\src

cd %SRC_PATH%

REM call prepare_solution_win.bat continue

REM IF %ERRORLEVEL% NEQ 0 (
REM     ECHO "prepare_solution_win.bat Command Failed"
REM     exit /b 1
REM )

call build_win.bat Debug

IF %ERRORLEVEL% NEQ 0 (
    ECHO "prepare_solution_win.bat Debug Command Failed"
    exit /b 1
)

call build_win.bat Release

IF %ERRORLEVEL% NEQ 0 (
    ECHO "prepare_solution_win.bat Release Command Failed"
    exit /b 1
)

cd tests

call launch_tests.bat
IF %ERRORLEVEL% NEQ 0 (
    ECHO "Windows Tests Failed"
    exit /b 1
) ELSE (
    ECHO "Windows Tests Passed"
)

cd ..

exit /b 0


