/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <stdio.h>

// this is just a super basic include and compile and link test
// it doesn't exercise the library much, but if this compiles and links
// its likely that further testing needs to be done in a real full project
// rather than artificially

// test whether a header is found
#include <freetype/freetype.h>

int main()
{
    FT_Library lib;
    if (FT_Init_FreeType(&lib) != 0)
    {
        printf("FAILURE! Freetype failed call to FT_Init_FreeType!\n");
        return 1;
    }
        
    FT_Int major = 0;
    FT_Int minor = 0;
    FT_Int patch = 0;
    FT_Library_Version(lib, &major, &minor, &patch);
    if (major == 0)
    {
        printf("FAILURE! Freetype FT_Library_Version returned invalid major version (%i)!\n", (int)major);
        return 1;
    }
    printf("Freetype Version: %i.%i.%i\n", (int)major, (int)minor, (int)patch );

    if (FT_Done_FreeType(lib) != 0)
    {
        printf("FAILURE! Freetype failed call to FT_Done_FreeType!\n");
        return 1;
    }
    printf("Success: All is ok!\n");
    return 0;
}
