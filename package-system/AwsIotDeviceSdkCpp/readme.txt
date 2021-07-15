This package will download and build aws-iot-device-sdk-cpp-v2 from the original Github source.  

A few things to be aware of:

1. This sdk requires an extremely short build path to build (on Windows only), such as 'd:\aws' or 'd:\temp'.  Otherwise it will fail to build due to excessively long file names.  

2. As of v1.12.2, the build scripts for the aws-c-common and aws-checksums submodules need to be patched to build their libraries correctly into Debug and Release subdirectories.  Without the patches, the base iot libraries will build into the subdirectories, but the aws-c-common libraries will build into a root 'lib' directory and overwrite each other when the different configurations are built.  These patches have been submitted as PRs, but have not yet been accepted or integrated back into aws-iot-device-sdk-cpp-v2.
	Submitted pull requests:
	https://github.com/awslabs/aws-checksums/pull/47
	https://github.com/awslabs/aws-c-common/pull/792

3. The iOS version doesn't currently build, it has the following error:
/Users/Shared/ly/lyengine/3rdPartySource/package-system/AwsIotDeviceSdkCpp/temp/src/crt/aws-crt-cpp/crt/aws-c-io/source/tls_channel_handler.c:333:5: error: 
   implicit declaration of function 's_tls_ctx_options_pem_clean_up' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
  s_tls_ctx_options_pem_clean_up(options);
  ^
/Users/Shared/ly/lyengine/3rdPartySource/package-system/AwsIotDeviceSdkCpp/temp/src/crt/aws-crt-cpp/crt/aws-c-io/source/tls_channel_handler.c:333:5: note: 
   did you mean 'aws_tls_ctx_options_clean_up'?
/Users/Shared/ly/lyengine/3rdPartySource/package-system/AwsIotDeviceSdkCpp/temp/src/crt/aws-crt-cpp/crt/aws-c-io/source/tls_channel_handler.c:25:6: note: 
   'aws_tls_ctx_options_clean_up' declared here
void aws_tls_ctx_options_clean_up(struct aws_tls_ctx_options *options) {
   ^
/Users/Shared/ly/lyengine/3rdPartySource/package-system/AwsIotDeviceSdkCpp/temp/src/crt/aws-crt-cpp/crt/aws-c-io/source/tls_channel_handler.c:352:5: error: 
   implicit declaration of function 's_tls_ctx_options_pem_clean_up' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
  s_tls_ctx_options_pem_clean_up(options);
  ^
2 errors generated.

4. The Android version requires 'go' and 'perl' installed.
https://www.activestate.com/products/perl/downloads/
https://golang.org/doc/install?download=go1.16.3.windows-amd64.msi
You may also need to do the following for go to work:
	go env -w GOPRIVATE=*


