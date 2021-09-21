@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #

@rem # note that we explicitly turn off the compilation of all features that rely on 3rd Party Libraries
@rem # except the ones we want.  This prevents the cmake build system from automatically finding things
@rem # if they happen to be installed locally, which we don't want.
cmake -S temp/src -B temp/build ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW ^
    -DBUILD_SHARED_LIBS=OFF ^
    -Djpeg=OFF ^
    -Dold-jpeg=OFF ^
    -Dpixarlog=OFF ^
    -Dlzma=OFF ^
    -Dwebp=OFF ^
    -Djbig=OFF ^
    -Dzstd=OFF ^
    -Djpeg12=OFF ^
    -Dzlib=ON ^
    -Dlibdeflate=OFF ^
    -Dcxx=OFF ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%" || exit /b 1

cmake --build temp/build --target tiff --config Release --parallel || exit /b 1

exit /b 0
