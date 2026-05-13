@echo off

rem
rem Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
rem
rem SPDX-License-Identifier: Apache-2.0 OR MIT
rem


rem Launch build_package.py in this directory with all forwarded arguments
setlocal
set "SCRIPT=%~dp0\Scripts\packaging\package.py"

where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python "%SCRIPT%" %*
  exit /b %ERRORLEVEL%
)
echo Python launcher not found. Install Python or add it to PATH.
exit /b 1
