#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import os
import urllib
import urllib.request
import ssl
import certifi
import tempfile
import boto3
from common import CommonUtils

class FindPackageUtils():
    # built in defaults:
    default_package_server_urls = ""

    # override with environ:
    package_server_urls = os.environ.get("LY_PACKAGE_SERVER_URLS", default=default_package_server_urls)
    aws_profile_name = os.environ.get('AWS_PROFILE', None) # this is used by the AWS CLI
    if not aws_profile_name:  # if you dont want to override global aws profile, you can also use this:
        aws_profile_name = os.environ.get('LY_AWS_PROFILE', None)

    bucket_name = os.environ.get('PACKAGE_bucket_name', None)

    if not aws_profile_name: 
        aws_profile_name = None # this will turn '' into None

    @staticmethod
    def FindPackageOnServer(package_name, server_urls, aws_profile_name):
        ''' given a public server URL list (semicolon-seperated), 
            makes sure the package is not already there
            Note that this essentially mimics the server urls protocol used by cmake on the client
            side and thus will also check buckets if s3:// urls are given
            and will stop at the first one it finds.

            Returns the server it was found at, or the empty string.
         '''
        # make sure a package with that name is not already present:
        if not server_urls:
            print(f"Server url list is empty - will always build all packages.  Consider setting server_urls")
        package_found_on_servers = []
        session = None
        server_list = server_urls.split(';')
        for package_server in server_list:
            if not package_server:
                continue
            print(f"    - Searching for package '{package_name}' on server '{package_server}'...")
            package_metadata_url = package_server + "/" + package_name + CommonUtils.package_content_hash_extension
            try:
                if package_server.startswith("s3://"):
                    # its an s3 url, we'll use boto to fetch
                    # s3 urls are s3://bucket-name/key-name
                    if not session:
                        session = boto3.session.Session(profile_name=aws_profile_name)

                    bucket_name = package_server[len("s3://"):]
                    slash_pos = bucket_name.find('/')
                    if slash_pos != -1:
                        bucket_name = bucket_name[:slash_pos]
                    
                    if FindPackageUtils.IsPackageAlreadyInS3Bucket(package_name, session, bucket_name):
                        package_found_on_servers.append(package_metadata_url)
                else:
                    context = ssl.create_default_context(cafile=certifi.where())
                    with urllib.request.urlopen(package_metadata_url, context=context):
                        # it will throw a URLError (below) if the server does not have it
                        # so if we get here, we have found it.
                        package_found_on_servers.append(package_metadata_url)
            except urllib.error.URLError:
                pass
            
            if package_found_on_servers:
                break

        return ";".join(package_found_on_servers)

    @staticmethod
    def IsPackageAlreadyInS3Bucket(package_name, session, bucket_name):
        ''' given a Boto3 session, make sure the package is not there.  Note that we always assume
        that the final file uploaded is the packagename + . + package_descriptor_name so its the marker! '''
        paginator = session.client('s3').get_paginator('list_objects_v2')
    
        for page in paginator.paginate(Bucket=bucket_name, Prefix=package_name + '.' + CommonUtils.package_descriptor_name):
            try:
                contents = page["Contents"]
                for obj in contents:
                    key = obj["Key"]
                    print(f"    - Package '{package_name}' is in bucket '{bucket_name}' as '{key}'")
                    return True
                    
            except KeyError:
                break

        return False

    @staticmethod
    def AddServerArgs(argparser):
        argparser.add_argument('-u', '--server_urls', action='store',
                                default=FindPackageUtils.package_server_urls,
                                help='(optional) Semi-colon-delimited server list of server URLs to search.  Can also use LY_PACKAGE_SERVER_URLS env var')
        argparser.add_argument('-p', '--profile_name', 
                action='store', default = FindPackageUtils.aws_profile_name, 
                help='(optional) The AWS Profile to run under, you can also set the env var AWS_PROFILE or LY_AWS_PROFILE')
        argparser.add_argument('-b', '--bucket_name',
                action='store', default = FindPackageUtils.bucket_name, 
                help='(optional) The S3 Bucket where packages live.  You can also use env var PACKAGE_bucket_name')


