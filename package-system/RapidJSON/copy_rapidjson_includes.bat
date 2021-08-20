set OUT_PATH=%TARGET_INSTALL_ROOT%
set SRC_PATH=temp\src\include
mkdir %OUT_PATH%\include
xcopy %SRC_PATH% %OUT_PATH%\include /s 
