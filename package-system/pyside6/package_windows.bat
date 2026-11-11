@echo off

REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM  
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 
REM 

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script

echo TEMP_FOLDER=%TEMP_FOLDER%
echo TARGET_INSTALL_ROOT=%TARGET_INSTALL_ROOT%

SET PACKAGE_BASE=%TARGET_INSTALL_ROOT%

SET INSTALL_SOURCE=%TEMP_FOLDER%\src\build\testenva\install
SET BUILD_SOURCE=%TEMP_FOLDER%\src\build\testenva\build

REM Copy the LICENSE and README files
ECHO copy %TEMP_FOLDER%\src\LICENSES\* %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\LICENSES\* %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\src\README.* %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\README.* %PACKAGE_BASE%\

REM Copy the bin 
mkdir %PACKAGE_BASE%\bin
robocopy %INSTALL_SOURCE%\bin %PACKAGE_BASE%\bin *.* /E

REM Copy the lib
mkdir %PACKAGE_BASE%\lib
robocopy %INSTALL_SOURCE%\lib %PACKAGE_BASE%\lib *.* /E
copy %INSTALL_SOURCE%\lib\pyside6.abi3.lib %PACKAGE_BASE%\lib\site-packages\PySide6\
copy %INSTALL_SOURCE%\bin\pyside6.abi3.dll %PACKAGE_BASE%\lib\site-packages\PySide6\
copy "%INSTALL_SOURCE%\bin\pyside6.abi3.pdb" "%PACKAGE_BASE%\lib\site-packages\PySide6\" || exit /b 1
copy %INSTALL_SOURCE%\lib\shiboken6.abi3.lib %PACKAGE_BASE%\lib\site-packages\shiboken6\
copy %INSTALL_SOURCE%\bin\shiboken6.abi3.dll %PACKAGE_BASE%\lib\site-packages\shiboken6\
copy "%INSTALL_SOURCE%\bin\shiboken6.abi3.pdb" "%PACKAGE_BASE%\lib\site-packages\shiboken6\" || exit /b 1

REM Make the include folder
mkdir %PACKAGE_BASE%\include

REM Copy the PySide6 folder
mkdir %PACKAGE_BASE%\include\PySide6
robocopy %INSTALL_SOURCE%\include\PySide6 %PACKAGE_BASE%\include\PySide6 *.* /E

REM Copy the shiboken6 folder
mkdir %PACKAGE_BASE%\include\shiboken6
robocopy %INSTALL_SOURCE%\include\shiboken6 %PACKAGE_BASE%\include\shiboken6 *.* /E

REM Copy the shiboken6_generator folder
mkdir %PACKAGE_BASE%\shiboken6_generator
robocopy %INSTALL_SOURCE%\shiboken6_generator %PACKAGE_BASE%\shiboken6_generator *.* /E

REM Copy over libclang and its license file
copy %TEMP_FOLDER%\libclang-release_20.1.3-based-windows-vs2019_64\libclang\bin\libclang.dll %PACKAGE_BASE%\bin\
copy %TEMP_FOLDER%\libclang-release_20.1.3-based-windows-vs2019_64\libclang\include\llvm\Support\LICENSE.TXT %PACKAGE_BASE%\LICENSE.LIBCLANG.TXT

REM Copy the lib (release) folder

REM Copy necessary files to register for pip install
copy %TEMP_FOLDER%\..\__init__.py %PACKAGE_BASE%\lib\site-packages\
copy %TEMP_FOLDER%\..\setup.py %PACKAGE_BASE%\lib\site-packages\

REM Copy the share folder
mkdir %PACKAGE_BASE%\share
robocopy %INSTALL_SOURCE%\share %PACKAGE_BASE%\share *.* /E

REM Merge Debug binaries without replacing the shared Python sources or Release CMake exports.
set DEBUG_INSTALL_SOURCE=%TEMP_FOLDER%\src\build\testenvdp\install
set DEBUG_SUFFIX=_d
for %%L in (pyside6 shiboken6) do (
    copy "%DEBUG_INSTALL_SOURCE%\lib\%%L%DEBUG_SUFFIX%.lib" "%PACKAGE_BASE%\lib\" || exit /b 1
    copy "%DEBUG_INSTALL_SOURCE%\bin\%%L%DEBUG_SUFFIX%.dll" "%PACKAGE_BASE%\bin\" || exit /b 1
    copy "%DEBUG_INSTALL_SOURCE%\bin\%%L%DEBUG_SUFFIX%.dll" "%PACKAGE_BASE%\lib\site-packages\%%L\" || exit /b 1
    copy "%DEBUG_INSTALL_SOURCE%\bin\%%L%DEBUG_SUFFIX%.pdb" "%PACKAGE_BASE%\bin\" || exit /b 1
    copy "%DEBUG_INSTALL_SOURCE%\bin\%%L%DEBUG_SUFFIX%.pdb" "%PACKAGE_BASE%\lib\site-packages\%%L\" || exit /b 1
)
for %%M in (PySide6 shiboken6) do (
    robocopy "%DEBUG_INSTALL_SOURCE%\lib\site-packages\%%M" "%PACKAGE_BASE%\lib\site-packages\%%M" *_d.pyd *.pdb /E
    if errorlevel 8 exit /b 1
)


exit /b 0
