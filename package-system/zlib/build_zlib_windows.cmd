@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #

cmake -S temp/src -B temp/build  -DCMAKE_CXX_STANDARD=17 -DCMAKE_DEBUG_POSTFIX=d -DBUILD_SHARED_LIBS=OFF -DSKIP_INSTALL_FILES=YES
@if %errorlevel% NEQ 0 ( exit /b 1 )
cmake --build temp/build --target zlibstatic --config Release -j 8
@if %errorlevel% NEQ 0 ( exit /b 1 )
cmake --build temp/build --target zlibstatic --config Debug -j 8
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
