/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.

 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <stdio.h>
#include <string.h>

#include <aws/gamelift/server/GameLiftServerAPI.h>

int main(int argc, char* argv[])
{
    printf("Testing AWSGameliftServerSDK package...\n");

    auto serverVersionResult = Aws::GameLift::Server::GetSdkVersion();
    if (!serverVersionResult.IsSuccess())
    {
        printf("Failed to get AWSGameliftServerSDK version\n");
        return 1;
    }

    auto game_lift_version = serverVersionResult.GetResult();
    printf("AWSGameLiftSDK version %s\n", game_lift_version);

    return 0;
}
