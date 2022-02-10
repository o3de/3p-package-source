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

@rem cd temp/build

@rem release build
%PYTHON_BINARY% temp/src/scripts/update_deps.py --dir temp/src/external --arch x64 --config release
cmake -C temp/src/external/helper.cmake -S temp/src -B temp/build
cmake --build temp/build --config Release --target clean
cmake --build temp/build --config Release --target install 
mkdir temp\\build\\install\\lib\\release
move temp\\build\\install\\lib\\* temp\\build\\install\\lib\\release\\

@rem debug build
%PYTHON_BINARY% temp/src/scripts/update_deps.py --dir temp/src/external --arch x64 --config debug
cmake --build temp/build --config Debug --target clean
cmake -C temp/src/external/helper.cmake -S temp/src -B temp/build
cmake --build temp/build --config Debug --target install 
mkdir temp\\build\\install\\lib\\debug
move temp\\build\\install\\lib\\* temp\\build\\install\\lib\\debug\\

exit /b 0