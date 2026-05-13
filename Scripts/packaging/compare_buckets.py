#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import boto3
import argparse
import sys
import functools

'''
This script, given the names of 2 s3 buckets and optionally a profile to use to log in, will show what packages
exist on each bucket, allowing you to find packages that are orphaned or are missing on production.
The output is a table in markdown format.
'''

from common import CommonUtils
from find_package_on_server import FindPackageUtils

def GetAllPackagesInBucket(aws_profile_name, bucket_name):
    ''' given a server URL (s3 bucket)
        Returns contents of the server.
        '''
    # make sure a package with that name is not already present:
    packages_found = []
    session =  boto3.session.Session(profile_name=aws_profile_name)
    package_descriptor_extension = '.' + CommonUtils.package_descriptor_name
    package_descriptor_extension_length = len(package_descriptor_extension)

    paginator = session.client('s3').get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=bucket_name):
        contents = page["Contents"]
        for obj in contents:
            key = obj["Key"]
            if (key.endswith(package_descriptor_extension)):
                packages_found.append(key[:-package_descriptor_extension_length])

    return packages_found

def CompareBuckets(aws_profile_name, package_list_data, bucket1, bucket2):
    packages_in_bucket1 = GetAllPackagesInBucket(aws_profile_name, bucket1)
    packages_in_bucket2 = GetAllPackagesInBucket(aws_profile_name, bucket2)
    
    build_from_source_packages = package_list_data['build_from_source'].keys()
    build_from_folder_packages = package_list_data['build_from_folder'].keys()
    packages_in_host_files_union = list(set(build_from_source_packages) | set(build_from_folder_packages))
    
    packages_in_buckets_union = list(set(packages_in_bucket1) | set(packages_in_bucket2) | set(packages_in_host_files_union))
    packages_in_buckets_union.sort()
    longest_package_name = len(functools.reduce(lambda a,b : a if len(a) > len(b) else b, packages_in_buckets_union))

    # this internal function formats the table nicely
    def PrintResultTable(lambda_to_use_to_select_packages_to_show):
        print('| PACKAGE NAME'.ljust(longest_package_name + 1) + '  | B1 | B2 | LF |')
        print('| -'.ljust(longest_package_name + 1, '-') + '--|----|----|----|')
        for element in packages_in_buckets_union:
            # only show packages that are also in the host files:
            if lambda_to_use_to_select_packages_to_show(element):
                package_name_with_padding = element.ljust(longest_package_name + 1 )# = '{:<{}}'.format(element, longest_package_name)
                package_in_bucket1 = 'x' if element in packages_in_bucket1 else ' '
                package_in_bucket2 = 'x' if element in packages_in_bucket2 else ' '
                package_in_host = 'x' if element in packages_in_host_files_union else ' '
                print(f'| {package_name_with_padding}|  {package_in_bucket1} |  {package_in_bucket2} | {package_in_host}  |')
        print() # blank line for markdown safety

    print(f"Buckets to compare: B1 = {args.bucket1}     B2 = {args.bucket2}   LF=(package Build List File)")

    print(f"Packages in Build List File, in {args.bucket2} but not {args.bucket1}:")
    package_is_in_dev_bucket_only = lambda element: element in packages_in_host_files_union and element in packages_in_bucket2 and element not in packages_in_bucket1
    PrintResultTable(package_is_in_dev_bucket_only)

    print("Packages which appear to be deprecated (not in any package list):")
    package_is_not_in_package_list_file = lambda element: element not in packages_in_host_files_union
    PrintResultTable(package_is_not_in_package_list_file)

    print("Packages which are not uploaded to ANY bucket but are in the package list (missing packages):")
    package_is_not_in_package_list_file = lambda element: element not in packages_in_bucket1 and element not in packages_in_bucket2
    PrintResultTable(package_is_not_in_package_list_file)
    
"""A CLI utility to compare what packages are in what buckets."""
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Compares the packages in a bucket with another bucket')
    CommonUtils.AddCommonArgs(parser)

    parser.add_argument('-p', '--profile_name', 
                action='store', default = FindPackageUtils.aws_profile_name, 
                help='(optional) The AWS Profile to run under, you can also set the env var AWS_PROFILE or LY_AWS_PROFILE')

    parser.add_argument('bucket1', metavar='bucket1', type=str, action='store', help='Name of first bucket')
    parser.add_argument('bucket2', metavar='bucket2', type=str, action='store', help='Name of second bucket')
    
    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    if not args.bucket1 or not args.bucket2:
        print("Missing bucket arguments - need exactly 2 buckets")
        sys.exit(1)
    
    merged_package_list = {}
    merged_package_list['build_from_source'] = {}
    merged_package_list['build_from_folder'] = {}

    for pal_platform in ['darwin', 'linux', 'windows']:
        host_data = CommonUtils.LoadPackageLists(args.search_path, pal_platform)
        for keyname in host_data['build_from_source'].keys():
            if keyname not in merged_package_list['build_from_source']:
                merged_package_list['build_from_source'][keyname] = host_data['build_from_source'][keyname]

        for keyname in host_data['build_from_folder'].keys():
            if keyname not in merged_package_list['build_from_folder']:
                merged_package_list['build_from_folder'][keyname] = host_data['build_from_folder'][keyname]
    
    CompareBuckets(args.profile_name, merged_package_list, args.bucket1, args.bucket2)
