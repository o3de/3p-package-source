@echo off
REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

set PACKAGE_BASE=%TARGET_INSTALL_ROOT%

set INSTALL_SOURCE=%TEMP_FOLDER%\src\.env3a_install\py3.7-qt5.15.1-64bit-release
echo INSTALL_SOURCE=%INSTALL_SOURCE%

REM Copy the LICENSE and README files
copy %TEMP_FOLDER%\src\LICENSE.* %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\README.* %PACKAGE_BASE%\

REM Copy the Pyside2 package
xcopy %INSTALL_SOURCE%\lib\site-packages\PySide2 %PACKAGE_BASE%\PySide2\ /e /y
copy %INSTALL_SOURCE%\lib\pyside2.abi3.lib %PACKAGE_BASE%\PySide2\
copy %INSTALL_SOURCE%\bin\pyside2.abi3.dll %PACKAGE_BASE%\PySide2\

REM Copy the shiboken2 package
xcopy %INSTALL_SOURCE%\lib\site-packages\shiboken2 %PACKAGE_BASE%\shiboken2\ /e /y
copy %INSTALL_SOURCE%\lib\shiboken2.abi3.lib %PACKAGE_BASE%\shiboken2\
copy %INSTALL_SOURCE%\bin\shiboken2.abi3.dll %PACKAGE_BASE%\shiboken2\

REM Add additional files needed for pip install
copy %TEMP_FOLDER%\..\__init__.py %PACKAGE_BASE%\
copy %TEMP_FOLDER%\..\setup.py %PACKAGE_BASE%\

GOTO:EOF
