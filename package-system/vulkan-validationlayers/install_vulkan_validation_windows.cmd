@rem
@rem Copyright (c) Contributors to the Open 3D Engine Project.
@rem For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem 
@rem SPDX-License-Identifier: Apache-2.0 OR MIT
@rem
@rem
@setlocal

set OUT_PATH=%TARGET_INSTALL_ROOT%
set SRC_PATH=temp\\src
set BLD_PATH=temp\\build

mkdir %OUT_PATH%\\include
mkdir %OUT_PATH%\\lib

mkdir %OUT_PATH%\\lib\\release
mkdir %OUT_PATH%\\lib\\debug

copy %BLD_PATH%\\install\\lib\\release\\* %OUT_PATH%\\lib\\release\\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy to %BLD_PATH%\\install\\lib\\release\\
    exit /b 1
)
copy %BLD_PATH%\\install\\lib\\debug\\* %OUT_PATH%\\lib\\debug\\
IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to copy to %BLD_PATH%\\install\\lib\\debug\\
    exit /b 1
)

exit /b 0