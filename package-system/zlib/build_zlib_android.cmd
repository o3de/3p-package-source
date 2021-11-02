@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #


@rem note that toolchain path is relative to the source path (-S) not to the folder this script lives in.
cmake -S temp/src -B temp/build -G Ninja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DCMAKE_TOOLCHAIN_FILE=../../../../Scripts/cmake/Platform/Android/Toolchain_android.cmake ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DSKIP_INSTALL_FILES=YES
@if %errorlevel% NEQ 0 ( exit /b 1 )

cmake --build temp/build --target zlibstatic --parallel
@if %errorlevel% NEQ 0 ( exit /b 1 )

exit /b 0
