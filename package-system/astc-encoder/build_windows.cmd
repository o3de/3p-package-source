REM
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM
REM

REM Note: on x86/x64 platforms, O3DE requires a minimum of SSE 4.1, so we do request this.

cmake -S temp/src -B temp/build -G "Visual Studio 16 2019" -DISA_SSE41=ON

@if %errorlevel% NEQ 0 ( exit /b 1 )
cmake --build temp/build --config Release -j 8
@if %errorlevel% NEQ 0 ( exit /b 1 )
cmake --build temp/build --config Debug -j 8
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
