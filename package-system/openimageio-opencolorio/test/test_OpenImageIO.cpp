/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

// this is mainly to make sure linkage is ok!  Call some random function.
#include <stdio.h>
#include <vector>

#include <OpenImageIO/imageio.h>
#include <OpenImageIO/imagebufalgo.h>

int main()
{
    using namespace OIIO;
    printf("All is ok\n");
    const char* filename = "base_Log2-48nits_16_LUT.exr";
    auto inp = ImageInput::open(filename);
    if (!inp)
    {
        printf("Was unable to read 48nits_16_LUT.exr\n");
        return -1;
    }
    if (inp->has_error())
    {
        printf("Error during read of 48nits_16_LUT.exr\n");
        return -1;
    }

    const ImageSpec &spec = inp->spec();
    int xres = spec.width;
    int yres = spec.height;
    int channels = spec.nchannels;

    printf("Name: %s\n", filename);
    printf("xres: %i\n", xres);
    printf("yres: %i\n", yres);
    printf("channels: %i\n", channels);
    printf("element type: %s\n", spec.format.c_str());

    if ((xres != 256) || (yres != 16) || (channels != 3))
    {
        printf("Invalid data.  Expected 256, 16, 3");
        return -1;
    }

    std::vector<unsigned char> pixels(xres * yres * channels);

    // note that this not only reads the image but converts it to UINT8
    if (!inp->read_image(0,0, 0, 0, TypeDesc::UINT8, &pixels[0]))
    {
        printf("Unable to read pixels from image.\n");
        return -1;    
    
    }

    inp->close();
    return 0;

}