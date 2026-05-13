#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this script verifies and then uploads any packages not present on 3rd PArty target location
# s3 Bucket.  
# to use this script, set AWS_PROFILE to be a valid profile name in your
# ~/.aws/config file
# and set LY_PACKAGE_BUCKET_NAME to be a valid S3 bucket name in your env.

import os
import sys
import argparse
import boto3

from common import CommonUtils
from find_package_on_server import FindPackageUtils

def UploadPackage(package_folder, package_name, session, bucket_name):
    bucket = session.resource('s3').Bucket(bucket_name)

    # we actually want this to be uploaded in ORDER, so we don't put it into a dict
    # which would otherwise mess with the order:
    for expected_file in CommonUtils.GetPackageParts(package_name):
        abspath = os.path.join(package_folder, expected_file)
        print(f"    - Uploading {expected_file}...")
        bucket.upload_file(abspath, expected_file, ExtraArgs={'ACL':'bucket-owner-full-control'})
    
    print(f"    - Uploaded package {package_name}.")

def UploadPackages(aws_profile_name, aws_bucket_name, package_folder):
    # we assume all packages in the package location are candidates:
    if aws_profile_name:
        print(f"Using profile: {aws_profile_name}")

    print(f"Using bucket: {aws_bucket_name}")

    # verify that boto3 actually gives us access:
    session = boto3.session.Session(profile_name=aws_profile_name)

    # find out what packages are locally available to upload:
    onlyfiles = [f for f in os.listdir(package_folder) if os.path.isfile(os.path.join(package_folder, f))]
    for existing_file in onlyfiles:
        if existing_file.endswith(CommonUtils.package_extension):
            package_name = existing_file[:-len(CommonUtils.package_extension)]
            print(f"Package: {package_name} ...")
            # don't bother doing anything if the package is already on s3.
            # if this throws an exception we're going to allow it to flow back 
            # down and cause a non zero exit code
            if (FindPackageUtils.IsPackageAlreadyInS3Bucket(package_name, session, aws_bucket_name)):
                continue
    
            # don't upload invalid packages, test them locally before uploading
            if not CommonUtils.FullyValidatePackage(package_folder, package_name):
                continue

            # this too, can cause an exception, so if it flows down, its okay,
            # allow the non zero exit code to flow all the way down into the main
            # return.
            UploadPackage(package_folder, package_name, session, aws_bucket_name)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Uploads packages to s3.')
    
    CommonUtils.AddCommonArgs(parser)
    FindPackageUtils.AddServerArgs(parser)

    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    if not args.bucket_name:
        print("Please set LY_PACKAGE_BUCKET_NAME in env or pass in --bucket_name <bucket_name>")
        sys.exit(1)

    if not args.profile_name:
        print("Not using an AWS profile.  Set LY_AWS_PROFILE or AWS_PROFILE or use command line params to change this.")
    else:
        print(f"Using AWS profile: {args.profile_name}")

    # this will throw an exception and thus produce a non zero exit code
    # if something goes wrong.
    UploadPackages(args.profile_name, args.bucket_name, args.output_folder)
    sys.exit(0)