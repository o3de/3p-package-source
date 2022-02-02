This package will download and build aws-iot-device-sdk-cpp-v2 from the original Github source. 

Supported platforms include Windows, Linux and MacOS. The iOS version doesn't build and the Android version is in preview.

A few things to be aware of:

1. This sdk requires an extremely short build path to build (on Windows only), such as 'd:\aws' or 'd:\temp'.  Otherwise it will fail to build due to excessively long file names.  

2. As of v1.15.2, the build scripts for the aws-c-common and aws-checksums submodules need to be patched to build their libraries correctly into Debug and Release subdirectories.  Without the patches, the base iot libraries will build into the subdirectories, but the aws-c-common libraries will build into a root 'lib' directory and overwrite each other when the different configurations are built.  These patches have been submitted as PRs, but have not yet been accepted or integrated back into aws-iot-device-sdk-cpp-v2.
	Submitted pull requests:
	https://github.com/awslabs/aws-checksums/pull/47
	https://github.com/awslabs/aws-c-common/pull/792

3. The iOS version is not supported by O3DE currently and it has a build error about the implicit declaration of function 's_tls_ctx_options_pem_clean_up'.

4. The Android version is not supported by O3DE currently, but you can try to build it with 'go' and 'perl' installed:
* https://www.activestate.com/products/perl/downloads/
* https://golang.org/doc/install?download=go1.16.3.windows-amd64.msi
You may also need to do the following for go to work:
	go env -w GOPRIVATE=*
This command causes the go command to treat any module as private and should therefore not use the proxy or checksum database.


