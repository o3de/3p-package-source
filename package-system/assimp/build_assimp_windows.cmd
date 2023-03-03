@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #

@rem # note that we explicitly turn off the compilation of all features that rely on 3rd Party Libraries
@rem # except the ones we want.  This prevents the cmake build system from automatically finding things
@rem # if they happen to be installed locally, which we don't want.

@rem # cmake expects fowardslashes:
set "DOWNLOADED_PACKAGE_FOLDERS=%DOWNLOADED_PACKAGE_FOLDERS:\=/%"

cmake -S temp/src ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%" ^
    -DASSIMP_BUILD_ZLIB=OFF ^
    -DASSIMP_BUILD_ASSIMP_TOOLS=ON ^
    temp/src/CMakeLists.txt || exit /b 1
cmake --build temp/src --config release || exit /b 1
cmake --build temp/src --config debug || exit /b 1

cmake -S temp/src ^
    -DBUILD_SHARED_LIBS=ON ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_MODULE_PATH="%DOWNLOADED_PACKAGE_FOLDERS%" ^
    -DASSIMP_BUILD_ZLIB=OFF ^
    -DASSIMP_BUILD_ASSIMP_TOOLS=ON ^
    temp/src/CMakeLists.txt || exit /b 1
cmake --build temp/src --config release || exit /b 1
cmake --build temp/src --config debug || exit /b 1

exit /b 0
