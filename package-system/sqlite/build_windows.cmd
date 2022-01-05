@echo off
REM
REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 
REM 

SET SRC_PATH=%TEMP_FOLDER%\src
SET BLD_PATH=%TEMP_FOLDER%\build


ECHO In order to build sqlite for windows, you must have the visual studio command environment
ECHO setup by running the appropriate vcvars.bat. You also need tclsh installed and in the system 
ECHO path as tcl is required to build for windows


cd %BLD_PATH%

REM Build the release library
call nmake /f ..\src\Makefile.msc TOP=..\src libsqlite3.lib DEBUG=0
IF %ERRORLEVEL% NEQ 0 (
    ECHO "nmake for debug Command Failed"
    exit /b 1
)

ECHO Build Successful

exit /b 0
