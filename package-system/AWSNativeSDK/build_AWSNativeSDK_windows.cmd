@echo off
REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

SET SRC_PATH=temp\src
SET BLD_PATH=temp\build

SET CMAKE_COMMON_ARGS=""
call::GenerateCommonCMakeArgs CMAKE_COMMON_ARGS

REM Debug Shared
call:ConfigureAndBuild Debug Shared
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

REM Debug Static
call:ConfigureAndBuild Debug Static
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

REM Release Shared
call:ConfigureAndBuild Release Shared
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

REM Release Static
call:ConfigureAndBuild Release Static
IF %ERRORLEVEL% NEQ 0 (
    exit /b 1
)

ECHO "Custom Build for AWSNativeSDK finished successfully"
exit /b 0

:ConfigureAndBuild
SET BUILD_TYPE=%~1
SET LIB_TYPE=%~2
SET BUILD_SHARED=OFF
IF %LIB_TYPE% EQU Shared (
    SET BUILD_SHARED=ON
)
ECHO "CMake Configure %BUILD_TYPE% %LIB_TYPE% with %CMAKE_COMMON_ARGS%"
call cmake -S %SRC_PATH% -B %BLD_PATH%\%BUILD_TYPE%_%LIB_TYPE% %CMAKE_COMMON_ARGS% -DBUILD_SHARED_LIBS=%BUILD_SHARED% -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" -DCMAKE_INSTALL_BINDIR="bin/%BUILD_TYPE%" -DCMAKE_INSTALL_LIBDIR="lib/%BUILD_TYPE%"
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Configure %BUILD_TYPE% %LIB_TYPE% failed"
    exit /b 1
)

ECHO "CMake Build %BUILD_TYPE% %LIB_TYPE% to %BLD_PATH%\%BUILD_TYPE%_%LIB_TYPE%"
call cmake --build %BLD_PATH%\%BUILD_TYPE%_%LIB_TYPE% --config %BUILD_TYPE% -j
IF %ERRORLEVEL% NEQ 0 (
    ECHO "CMake Build %BUILD_TYPE% %LIB_TYPE% to %BLD_PATH%\%BUILD_TYPE%_%LIB_TYPE% failed"
    exit /b 1
)
GOTO:EOF

:GenerateCommonCMakeArgs
SET %~1= -G "Visual Studio 16 2019" -A x64 -DCPP_STANDARD=17 -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;mobileanalytics;queues;s3;sns;sqs;sts;transfer" -DENABLE_TESTING=OFF -DENABLE_RTTI=ON -DCUSTOM_MEMORY_MANAGEMENT=ON
GOTO:EOF