@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #
@rem #
@setlocal

set OUT_PATH=%TARGET_INSTALL_ROOT%
set SRC_PATH=temp\src
set BLD_PATH=temp\build

mkdir %OUT_PATH%\include
mkdir %OUT_PATH%\lib

copy %BLD_PATH%\zconf.h %OUT_PATH%\include\zconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\zlib.h %OUT_PATH%\include\zlib.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\LICENSE %OUT_PATH%\LICENSE
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %BLD_PATH%\Release\zlibstatic.lib %OUT_PATH%\lib\zlibstatic.lib
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %BLD_PATH%\Debug\zlibstaticd.lib %OUT_PATH%\lib\zlibstaticd.lib
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %BLD_PATH%\Debug\zlibstaticd.pdb %OUT_PATH%\lib\zlibstaticd.pdb
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy FindZLIB_compat_windows.cmake %OUT_PATH%\FindZLIB.cmake
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
