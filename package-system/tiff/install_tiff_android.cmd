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

copy %BLD_PATH%\libtiff\tiffconf.h %OUT_PATH%\include\tiffconf.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\libtiff\tiff.h %OUT_PATH%\include\tiff.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\libtiff\tiffvers.h %OUT_PATH%\include\tiffvers.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\libtiff\tiffio.h %OUT_PATH%\include\tiffio.h
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %SRC_PATH%\COPYRIGHT %OUT_PATH%\COPYRIGHT
@if %errorlevel% NEQ 0 ( exit /b 1 )
copy %BLD_PATH%\libtiff\libtiff.a %OUT_PATH%\lib\libtiff.a
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
