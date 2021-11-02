@echo off

REM
REM  All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
REM  its licensors.
REM
REM  For complete copyright and license terms please see the LICENSE at the root of this
REM  distribution (the "License"). All use of this software is governed by the License,
REM  or, if provided, by the license below or the license accompanying this file. Do not
REM  remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
REM  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM

SET BIN_PATH=%TARGET_INSTALL_ROOT%\bin

SET SRC_PATH=temp\src

mkdir %BIN_PATH%

copy /Y %SRC_PATH%\README.md %TARGET_INSTALL_ROOT%\
copy /Y %SRC_PATH%\LICENSE_APACHE2.TXT %TARGET_INSTALL_ROOT%\
copy /Y %SRC_PATH%\LICENSE_MIT.TXT %TARGET_INSTALL_ROOT%\

mkdir %BIN_PATH%\Release

copy /Y %SRC_PATH%\build\win_x64\Release\azslc.exe %BIN_PATH%\Release\

exit /b 0
