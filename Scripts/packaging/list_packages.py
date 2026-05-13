#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

import argparse

from common import CommonUtils

"""A CLI utility to print the list of packages in the config files."""

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Lists all packages in the package manifest files')
    CommonUtils.AddCommonArgs(parser)
    args = parser.parse_args()
    CommonUtils.PostArgParse(args)

    data = CommonUtils.LoadPackageLists(args.search_path)

    CommonUtils.PrintPackageList(data)
    
