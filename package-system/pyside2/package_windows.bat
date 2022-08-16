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

SET INSTALL_SOURCE_RELEASE=%TEMP_FOLDER%\src\testenv3a_install\py3.10-qt5.15.1-64bit-release
SET INSTALL_SOURCE_DEBUG=%TEMP_FOLDER%\src\testenv3dp_install\py3.10-qt5.15.1-64bit-debug
SET BUILD_SOURCE_DEBUG=%TEMP_FOLDER%\\src\testenv3dp_build\py3.10-qt5.15.1-64bit-debug

REM Copy the LICENSE and README files

ECHO copy %TEMP_FOLDER%\src\LICENSE.FDL %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\LICENSE.FDL %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\src\LICENSE.GPLv3 %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\LICENSE.GPLv3 %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\src\LICENSE.GPLv3-EXCEPT %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\LICENSE.GPLv3-EXCEPT %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\src\LICENSE.LGPLv3 %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\LICENSE.LGPLv3 %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\..\LICENSES.TXT %PACKAGE_BASE%\
copy %TEMP_FOLDER%\..\LICENSES.TXT %PACKAGE_BASE%\
ECHO copy %TEMP_FOLDER%\src\README.* %PACKAGE_BASE%\
copy %TEMP_FOLDER%\src\README.* %PACKAGE_BASE%\


REM Copy the bin (release) folder 
mkdir %PACKAGE_BASE%\bin
robocopy %INSTALL_SOURCE_RELEASE%\bin %PACKAGE_BASE%\bin *.* /E
REM Copy over libclang and its license file
copy %TEMP_FOLDER%\libclang-release_130-based-windows-vs2019_64\libclang\bin\libclang.dll %PACKAGE_BASE%\bin\
copy %TEMP_FOLDER%\libclang-release_130-based-windows-vs2019_64\libclang\include\llvm\Support\LICENSE.TXT %PACKAGE_BASE%\LICENSE.LIBCLANG.TXT

REM Copy the include (release) folder
mkdir %PACKAGE_BASE%\include
robocopy %INSTALL_SOURCE_RELEASE%\include %PACKAGE_BASE%\include *.* /E

REM Copy the lib (release) folder
mkdir %PACKAGE_BASE%\lib
robocopy %INSTALL_SOURCE_RELEASE%\lib %PACKAGE_BASE%\lib *.* /E
copy %INSTALL_SOURCE_RELEASE%\lib\pyside2.abi3.lib %PACKAGE_BASE%\lib\site-packages\PySide2\
copy %INSTALL_SOURCE_RELEASE%\bin\pyside2.abi3.dll %PACKAGE_BASE%\lib\site-packages\PySide2\
copy %INSTALL_SOURCE_RELEASE%\lib\shiboken2.abi3.lib %PACKAGE_BASE%\lib\site-packages\shiboken2\
copy %INSTALL_SOURCE_RELEASE%\bin\shiboken2.abi3.dll %PACKAGE_BASE%\lib\site-packages\shiboken2\

REM Overlay debug versions
robocopy %INSTALL_SOURCE_DEBUG%\lib\site-packages\PySide2 %PACKAGE_BASE%\lib\site-packages\PySide2 *.pyd /E
robocopy %INSTALL_SOURCE_DEBUG%\lib\site-packages\shiboken2 %PACKAGE_BASE%\lib\site-packages\shiboken2 *.pyd /E
copy %INSTALL_SOURCE_DEBUG%\lib\pyside2_d.cp310-win_amd64.lib %PACKAGE_BASE%\lib\site-packages\PySide2\
copy %INSTALL_SOURCE_DEBUG%\bin\pyside2_d.cp310-win_amd64.dll %PACKAGE_BASE%\lib\site-packages\PySide2\
copy %INSTALL_SOURCE_DEBUG%\lib\shiboken2_d.cp310-win_amd64.lib %PACKAGE_BASE%\lib\site-packages\shiboken2\
copy %INSTALL_SOURCE_DEBUG%\bin\shiboken2_d.cp310-win_amd64.dll %PACKAGE_BASE%\lib\site-packages\shiboken2\

REM Copy necessary files to register for pip install
cp %TEMP_FOLDER%\..\__init__.py %PACKAGE_BASE%\lib\site-packages\
cp %TEMP_FOLDER%\..\setup.py %PACKAGE_BASE%\lib\site-packages\

REM Copy the share folder
mkdir %PACKAGE_BASE%\share
robocopy %INSTALL_SOURCE_RELEASE%\share %PACKAGE_BASE%\share *.* /E



REM ##############################################################################################################################
GOTO skipcopy
REM Copy the egg-info for Pyside2
mkdir %PACKAGE_BASE%\PySide2.egg-info
robocopy %TEMP_FOLDER%\src\PySide2.egg-info %PACKAGE_BASE%\PySide2.egg-info /E


REM Copy the PySide2 module
mkdir %PACKAGE_BASE%\PySide2

copy %INSTALL_SOURCE_RELEASE%\lib\pyside2.abi3.lib %PACKAGE_BASE%\PySide2\
copy %INSTALL_SOURCE_RELEASE%\bin\pyside2.abi3.dll %PACKAGE_BASE%\PySide2\
robocopy %INSTALL_SOURCE_RELEASE%\lib\site-packages\PySide2 %PACKAGE_BASE%\PySide2 *.py *.pyd /E

copy %INSTALL_SOURCE_DEBUG%\lib\pyside2_d.cp310-win_amd64.lib %PACKAGE_BASE%\PySide2\
copy %INSTALL_SOURCE_DEBUG%\bin\pyside2_d.cp310-win_amd64.dll %PACKAGE_BASE%\PySide2\
copy %BUILD_SOURCE_DEBUG%\pyside2\pyside2_d.cp310-win_amd64.pdb %PACKAGE_BASE%\shiboken2\


robocopy %INSTALL_SOURCE_DEBUG%\lib\site-packages\PySide2 %PACKAGE_BASE%\PySide2 *.pyd /E


REM Copy the shiboken2 module
mkdir %PACKAGE_BASE%\shiboken2

copy %INSTALL_SOURCE_RELEASE%\lib\shiboken2.abi3.lib %PACKAGE_BASE%\shiboken2\
copy %INSTALL_SOURCE_RELEASE%\bin\shiboken2.abi3.dll %PACKAGE_BASE%\shiboken2\
robocopy %INSTALL_SOURCE_RELEASE%\lib\site-packages\shiboken2 %PACKAGE_BASE%\shiboken2 *.py *.pyd /E
                                
copy %INSTALL_SOURCE_DEBUG%\lib\shiboken2_d.cp310-win_amd64.lib %PACKAGE_BASE%\shiboken2\
copy %INSTALL_SOURCE_DEBUG%\bin\shiboken2_d.cp310-win_amd64.dll %PACKAGE_BASE%\shiboken2\
copy %BUILD_SOURCE_DEBUG%\shiboken2\libshiboken\shiboken2_d.cp310-win_amd64.pdb %PACKAGE_BASE%\shiboken2\
robocopy %INSTALL_SOURCE_DEBUG%\lib\site-packages\shiboken2 %PACKAGE_BASE%\shiboken2 *.pyd /E

REM Add additional files needed for pip install
cp %TEMP_FOLDER%\..\__init__.py %PACKAGE_BASE%\
cp %TEMP_FOLDER%\..\setup.py %PACKAGE_BASE%\

:skipcopy
REM ##############################################################################################################################






exit /b 0
