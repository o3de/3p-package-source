@echo off
setlocal enabledelayedexpansion

REM 
REM Copyright (c) Contributors to the Open 3D Engine Project.
REM For complete copyright and license terms please see the LICENSE at the root of this distribution.
REM 
REM SPDX-License-Identifier: Apache-2.0 OR MIT
REM 

REM Set these before running the script
if not defined VCVARS_PATH set VCVARS_PATH="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
if not defined QTARRAY set QTARRAY=qtbase,qtimageformats,qtsvg,qttools,qttranslations

REM TEMP_FOLDER and TARGET_INSTALL_ROOT get set from the pull_and_build_from_git.py script
set QT_SOURCE_ROOT=%TEMP_FOLDER%\src
set CHECKS_FAILED=0
for %%P IN (VCVARS_PATH,TEMP_FOLDER,TARGET_INSTALL_ROOT) do (
    if not exist !%%P! (
        echo %%P not found at !%%P!
        set CHECKS_FAILED=1
    )
)

if %CHECKS_FAILED%==1 goto FAILURE

echo Setting up VS2022
call %VCVARS_PATH% amd64

REM For OpenSSL support
set OPENSSL_ROOT=%TEMP_FOLDER%\OpenSSL-1.1.1o-rev1-windows\OpenSSL
set OPENSSL_INCLUDE=%OPENSSL_ROOT%\include
set OPENSSL_LIB_DEBUG=%OPENSSL_ROOT%\debug\lib
set OPENSSL_LIB_RELEASE=%OPENSSL_ROOT%\lib
set INCLUDE=%OPENSSL_INCLUDE%;%INCLUDE%
set LIB=%OPENSSL_LIB_DEBUG%;%OPENSSL_LIB_RELEASE%;%LIB%

REM To prevent max path issues, we go as close as possible to disk root
cd %TEMP_FOLDER%\..\..\..\..\..
rmdir b /S /Q
mkdir b
cd b

set _OPTS=-prefix %TARGET_INSTALL_ROOT% ^
    -submodules %QTARRAY% ^
    -skip qtdeclarative ^
    -skip qtactiveqt ^
    -platform win32-msvc ^
    -nomake examples ^
    -nomake tests ^
    -debug-and-release ^
    -c++std c++20 ^
    -force-debug-info ^
    -separate-debug-info ^
    -opensource ^
    -confirm-license ^
    -opengl dynamic ^
    -openssl-linked ^
    -no-dbus ^
    -no-feature-printsupport ^
    -no-feature-sql ^
    -qt-webp ^
    -no-jasper ^
    -no-mng ^
    -no-feature-designer ^
    -feature-linguist ^
    -no-feature-assistant ^
    -no-feature-distancefieldgenerator ^
    -no-feature-kmap2qmap ^
    -no-feature-pixeltool ^
    -no-feature-qdbus ^
    -no-feature-qdoc ^
    -no-feature-qtattributionsscanner ^
    -no-feature-qtdiag ^
    -no-feature-qtplugininfo ^
    -- ^
    -Wno-dev ^
    -DQT_USE_DEFAULT_CMAKE_OPTIMIZATION_FLAGS=ON ^
    -DCMAKE_C_FLAGS_DEBUG="/MDd /O2 /Zi" ^
    -DCMAKE_CXX_FLAGS_DEBUG="/MDd /O2 /Zi" ^
    -DCMAKE_INSTALL_MESSAGE=NEVER

cmd /c ""%QT_SOURCE_ROOT%\configure.bat" %_OPTS%" || goto FAILURE

cmd /c cmake --build . --parallel || goto FAILURE

cmd /c cmake --install . --config Debug || goto FAILURE
cmd /c cmake --install . --config RelWithDebInfo || goto FAILURE

:FINISH
exit

:FAILURE
echo Build failed, see errors above.
exit 1
