@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #

@IF "%LY_ANDROID_NDK_ROOT%" == "" (
    @echo Need to set the varible LY_ANDROID_NDK_ROOT to the location of your NDK install!
    @exit /b 1
)

@REM The CMAKE_FIND_ROOT_PATH_ settings are necessary to prevent the android toolchain from forcing cmake to link against their version of zlib
cmake -S temp/src -B temp/build   -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_STANDARD=17 -DCMAKE_TOOLCHAIN_FILE=%LY_ANDROID_NDK_ROOT%\\build\\cmake\\android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DBUILD_SHARED_LIBS=OFF   -DZLIB_ROOT=../zlib-android/zlib  -DPNG_SHARED=OFF -DPNG_TESTS=OFF -DPNG_DEBUG=OFF -DCMAKE_POLICY_DEFAULT_CMP0074=NEW -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=NEVER -DM_LIBRARY=""

@if %errorlevel% NEQ 0 ( exit /b 1 )

cmake --build temp/build --target png_static
@if %errorlevel% NEQ 0 ( exit /b 1 )

@exit /b 0