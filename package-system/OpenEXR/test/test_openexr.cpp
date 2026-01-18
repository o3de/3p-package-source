/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <ImfRgbaFile.h>
#include <ImfHeader.h>
#include <ImfChannelList.h>

#if defined(OPENEXR_TEST_VER_3_4)
using namespace Imf_3_4;
using namespace Imath_3_2;
#else
using namespace Imf_3_1;
using namespace Imath_3_1;
#endif

int
readHeader(const char fileName[],
     int &width, int &height, RgbaChannels& channels)
{
    RgbaInputFile inputFile(fileName);
    
    int num_channels = 0;
    const Header& header = inputFile.header();
   
    Box2i dw = header.dataWindow();
    width  = dw.max.x - dw.min.x + 1;
    height = dw.max.y - dw.min.y + 1;
    channels = inputFile.channels();

    return 0;
}

int CheckFile(const char fileName[], int expectedWidth, int expectedHeight, RgbaChannels expectedChannels)
{
    int w = 0;
    int h = 0;
    RgbaChannels channels = {};
    printf("verifying '%s' ...\n", fileName);
    readHeader (fileName, w, h, channels);
    if ( (w != expectedWidth) || (h != expectedHeight) || (channels != expectedChannels) )
    {
        printf("ERROR!\nEXPECTED: w = %i, h = %i, channels=0x%02x", expectedWidth, expectedHeight, expectedChannels);
        printf("ACTUAL  : w = %i, h = %i, channels=0x%02x\n", w, h, channels);
        return 1;
    }
    return 0;
}

int main()
{
    if (int resultCode = CheckFile("test/base_Log2-48nits_16_LUT.exr", 256, 16, WRITE_RGB) != 0)
    {
        return resultCode;
    }
    
    if (int resultCode = CheckFile("test/atom_brdf.exr", 256, 256,  WRITE_RGB) != 0)
    {
        return resultCode;
    }

    printf("All is ok\n");
    
    return 0;
}