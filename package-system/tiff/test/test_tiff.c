/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

// test that the TIFF library imports correctly
// Doesn't test much else about it.  Can be expanded if this becomes a problem in the
// future.

#include <tiffio.h>
#include <stdio.h>

int main()
{
    printf("Tiff Version: %s\n", TIFFGetVersion());
    if (TIFFGetVersion())
    {
        return 0;
    }
    return 1;
}