# Build New AWS Service Target in AWSNativeSDK
## Overview

This package defines and builds the AWS C++ SDK libarires for O3DE. It builds all core libraries and an opinionated subset of AWS client libraries. To add a new AWS Service client (or target) please use the example and instructions below.

Find and identify the service package(s) required from the package directory at [aws/aws-sdk-cpp](https://github.com/aws/aws-sdk-cpp) on GitHub. Refer to the [AWS SDK for C++ Developer Guide](https://docs.aws.amazon.com/sdk-for-cpp/v1/developer-guide/welcome.html) for further help.
The package name is the suffix of the directory name for the service.

```
aws-sdk-cpp\aws-cpp-sdk-<packageName>   # Repo directory name and packageName
aws-sdk-cpp\aws-cpp-sdk-s3              # Example: Package name is s3
```

Note: If the AWS service package is not currently available in AWSNativeSDK, then please upgrade AWSNativeSDK version first.

## Example: Build ElasticSearch (ES)

### 1. Check [aws/aws-sdk-cpp](https://github.com/aws/aws-sdk-cpp) for aws-cpp-sdk-es

### 2. Add ElasticSearch as part of AWSNativeSDK build target
Modify AWSNativeSDK build script by adding ElasticSearch as a build target. The example below uses the windows build script as a reference:

[AWSNativeSDK build script (windows)](https://github.com/o3de/3p-package-source/blob/main/package-system/AWSNativeSDK/build_AWSNativeSDK_windows.cmd)
```diff
--- a/package-system/AWSNativeSDK/build_AWSNativeSDK_windows.cmd
+++ b/package-system/AWSNativeSDK/build_AWSNativeSDK_windows.cmd
@@ -58,7 +58,7 @@ call cmake -S %SRC_PATH% -B %BLD_PATH%\%BUILD_TYPE%_%LIB_TYPE% ^
            -DTARGET_ARCH=WINDOWS ^
            -DCMAKE_CXX_STANDARD=17 ^
            -DCPP_STANDARD=17 ^
-           -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;gamelift;identity-management;kinesis;lambda;queues;s3;sns;sqs;sts;transfer" ^
+           -DBUILD_ONLY="access-management;cognito-identity;cognito-idp;core;devicefarm;dynamodb;es;gamelift;identity-management;kinesis;lambda;queues;s3;sns;sqs;sts;transfer" ^
            -DENABLE_TESTING=OFF ^
            -DENABLE_RTTI=ON ^
            -DCUSTOM_MEMORY_MANAGEMENT=ON ^
```
aws-cpp-sdk-es shared and static libraries will be generated after AWSNativeSDK is built.

### 3. Create a 3rdParty library target for ElasticSearch
Modify FindAWSNativeSDK.cmake file by creating a new target for ElasticSearch, The example below uses the windows cmake file as a reference:

[FindAWSNativeSDK.cmake.Windows](https://github.com/o3de/3p-package-source/blob/main/package-system/AWSNativeSDK/FindAWSNativeSDK.cmake.Windows)
```diff
--- a/package-system/AWSNativeSDK/FindAWSNativeSDK.cmake.Windows
+++ b/package-system/AWSNativeSDK/FindAWSNativeSDK.cmake.Windows
@@ -272,6 +272,13 @@ ly_declare_aws_library(
         aws-cpp-sdk-transfer
 )

+#### ElasticSearch ####
+ly_declare_aws_library(
+    NAME
+        ElasticSearch
+    LIB_FILE
+        aws-cpp-sdk-es
+)
```
It is up to the consumer to pull aws-cpp-sdk-es shared and static libraries as build and runtime dependencies by using `3rdParty::AWSNativeSDK::ElasticSearch` target.

### 4. Update AWSNativeSDK with correct version and revision
Modify build config and list file to bump AWSNativeSDK with correct version and revision value. The example below uses the windows build as a reference:

As current version is `1.9.50-rev2`, bump it to `1.9.50-rev3` for example

[build_config.json](https://github.com/o3de/3p-package-source/blob/main/package-system/AWSNativeSDK/build_config.json)
```diff
--- a/package-system/AWSNativeSDK/build_config.json
+++ b/package-system/AWSNativeSDK/build_config.json
@@ -12,7 +12,7 @@
    "Platforms":{
       "Windows":{
          "Windows":{
-            "package_version":"1.9.50-rev2",
+            "package_version":"1.9.50-rev3",
             "patch_file":"AWSNativeSDK-1.9.50-windows.patch",
             "cmake_find_source":"FindAWSNativeSDK.cmake.Windows",
             "custom_build_cmd": [
```
[package_build_list_host_windows.json](https://github.com/o3de/3p-package-source/blob/main/package_build_list_host_windows.json)
```diff
--- a/package_build_list_host_windows.json
+++ b/package_build_list_host_windows.json
@@ -4,7 +4,7 @@
     "comment3" : "build_from_folder is package name --> folder containing built image of package",
     "comment4" : "Note:  Build from source occurs before build_from_folder",
     "build_from_source": {
-        "AWSNativeSDK-1.9.50-rev2-windows": "Scripts/extras/pull_and_build_from_git.py ../../package-system/AWSNativeSDK --platform-name Windows --package-root ../../package-system --clean",
+        "AWSNativeSDK-1.9.50-rev3-windows": "Scripts/extras/pull_and_build_from_git.py ../../package-system/AWSNativeSDK --platform-name Windows --package-root ../../package-system --clean",
         "AWSNativeSDK-1.9.50-rev1-android": "Scripts/extras/pull_and_build_from_git.py ../../package-system/AWSNativeSDK --platform-name Android --package-root ../../package-system --clean",
         "Blast-v1.1.7_rc2-9-geb169fe-rev2-windows": "package-system/Blast/build_package_image.py --platform-name windows",
         "Crashpad-0.8.0-rev3-windows": "package-system/Crashpad/build_package_image.py",
@@ -51,7 +51,7 @@
   "build_from_folder": {
     "astc-encoder-3.2-rev2-windows" : "package-system/astc-encoder-windows",
     "AWSGameLiftServerSDK-3.4.1-rev1-windows" : "package-system/AWSGameLiftServerSDK/windows",
-    "AWSNativeSDK-1.9.50-rev2-windows": "package-system/AWSNativeSDK-windows",
+    "AWSNativeSDK-1.9.50-rev3-windows": "package-system/AWSNativeSDK-windows",
     "AWSNativeSDK-1.9.50-rev1-android": "package-system/AWSNativeSDK-android",
     "Blast-v1.1.7_rc2-9-geb169fe-rev1-windows": "package-system/Blast-windows",
     "Crashpad-0.8.0-rev3-windows" : "package-system/Crashpad-windows",
```

### 5. Follow 3p-package-scripts runbook to build and distribute package
[o3de/3p-package-scripts](https://github.com/o3de/3p-package-scripts/blob/main/README.md)
