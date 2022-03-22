/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

// test that the PNG library imports correctly
// Doesn't test much else about it.  Can be expanded if this becomes a problem in the
// future.

#include <png.h>
#include <stdio.h>

int main()
{
    if (png_get_header_ver(0))
    {
        printf("png header version: %s\n", png_get_header_ver(0));
        printf("test_png: All is OK!\n");
        return 0;
    }
    printf("Failed to call png_get_header_ver(), error!\n");
    return 1;
}
