@rem #
@rem # Copyright (c) Contributors to the Open 3D Engine Project.
@rem # For complete copyright and license terms please see the LICENSE at the root of this distribution.
@rem # 
@rem # SPDX-License-Identifier: Apache-2.0 OR MIT
@rem #

set curdir=%cd%

rem The tests leave behind a lot of temp files in the current working directory,
rem so change to a directory in temp to keep things clean
cd temp
mkdir test_out
cd test_out

%TARGET_INSTALL_ROOT%\bin\Debug\unit.exe || goto ExitWithError
%TARGET_INSTALL_ROOT%\bin\Release\unit.exe || goto ExitWithError

cd %curdir%
exit /b 0

:ExitWithError
cd %curdir%
exit /b 1