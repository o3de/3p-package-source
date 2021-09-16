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
mkdir %OUT_PATH%\include\libpng16
mkdir %OUT_PATH%\lib

copy %SRC_PATH%\png.h %OUT_PATH%\include\png.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\png.h %OUT_PATH%\include\libpng16\png.h
@if %errorlevel% NEQ 0 ( exit /b 1 )

copy %SRC_PATH%\pngconf.h %OUT_PATH%\include\pngconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\pngconf.h %OUT_PATH%\include\libpng16\pngconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )

copy %BLD_PATH%\pnglibconf.h %OUT_PATH%\include\pnglibconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %BLD_PATH%\pnglibconf.h %OUT_PATH%\include\libpng16\pnglibconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )

copy %BLD_PATH%\libpng16.a %OUT_PATH%\lib\libpng16.a
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
