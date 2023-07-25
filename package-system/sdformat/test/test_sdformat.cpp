/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.

 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <cstdio>
#include <string_view>

// This is just a basic include and compile test

#include <sdformat.hh>

int main(int argc, char** argv)
{
    if (argc < 2)
    {
        printf("Usage: %s [SDF VERSION_FULL]\n", argv[0]);
        return 1;
    }

    std::string_view sdfVersionFull = argv[1];
    printf(R"(Validating SDF version "%.*s": )", sdfVersionFull.size(), sdfVersionFull.data());

    if (sdfVersionFull != SDF_VERSION_FULL)
    {
        printf("Failure\n"
            R"(SDformat SDF_VERSION_FULL returned a version of "%s". Expecting "%.*s".)" "\n",
            SDF_VERSION_FULL, sdfVersionFull.size(), sdfVersionFull.data());
        return 1;
    }
    else
    {
        printf("OK\n");
    }

    sdf::SDF defaultSdf;
    const std::string& sdfVersion = defaultSdf.Version();

    printf(R"(Validating new SDF object has a non-empty version string: )");
    if (sdfVersion.empty())
    {
        printf("Failure\n" "SDF object version string is empty\n");
        return 1;
    }
    else
    {
        printf("OK\n");
    }

    return 0;
}
