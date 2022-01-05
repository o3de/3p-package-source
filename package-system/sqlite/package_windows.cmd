 @echo off

REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM


SET PACKAGE_BASE=%TARGET_INSTALL_ROOT%
SET BLD_PATH=%TEMP_FOLDER%\build

SET INSTALL_SOURCE=%TEMP_FOLDER%\build

cp %TEMP_FOLDER%\src\copyright.txt %PACKAGE_BASE%\

REM Copy extra source files just for reference
cp %INSTALL_SOURCE%\shell.c %PACKAGE_BASE%\
cp %INSTALL_SOURCE%\sqlite3.c %PACKAGE_BASE%\

REM Copy the header files
cp %INSTALL_SOURCE%\sqlite3ext.h %PACKAGE_BASE%\
cp %INSTALL_SOURCE%\sqlite3.h %PACKAGE_BASE%\

REM Copy the static library
mkdir %PACKAGE_BASE%\lib
copy %TEMP_FOLDER%\build\libsqlite3.lib %PACKAGE_BASE%\lib\sqlite3.lib

exit /b 0

