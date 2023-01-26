/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

// this is mainly to make sure linkage is ok!  Call some random function.
#include <stdio.h>
#include <vector>
#include <memory>

#include <OpenImageIO/imageio.h>
#include <OpenImageIO/imagebufalgo.h>

// Test include for OpenColorIO as well
#include <OpenColorIO/OpenColorIO.h>

bool testReadingImage()
{
    using namespace OIIO;
    namespace OCIO = OCIO_NAMESPACE;

    // Try retrieving the OCIO global config
    auto config = OCIO::GetCurrentConfig();

    printf("All is ok\n");
    const char* filename = "base_Log2-48nits_16_LUT.exr";
    auto inp = ImageInput::open(filename);
    if (!inp)
    {
        printf("Was unable to read 48nits_16_LUT.exr\n");
        return false;
    }
    if (inp->has_error())
    {
        printf("Error during read of 48nits_16_LUT.exr\n");
        return false;
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
        return false;
    }

    std::vector<unsigned char> pixels(xres * yres * channels);

    // note that this not only reads the image but converts it to UINT8
    if (!inp->read_image(0,0, 0, 0, TypeDesc::UINT8, &pixels[0]))
    {
        printf("Unable to read pixels from image.\n");
        return false;
    }

    inp->close();
    return true;
}

bool testWritingImage()
{
    using namespace OIIO;
     OIIO::TypeDesc pixelFormat = OIIO::TypeDesc::UINT8;
    std::unique_ptr<OIIO::ImageOutput> outputImage = OIIO::ImageOutput::create("temp_save_image.png");
    if (!outputImage)
    {
        printf("Failed to create the OIIO::ImageOutput.\n");
        return false;
    }

    OIIO::ImageSpec spec(1024, 1024, 4, pixelFormat);
    if (!outputImage->open("temp_save_image.png", spec))
    {
        printf("Failed to open temp_save_image.png\n");
        return false;
    }

    std::vector<unsigned char> pixelBuffer;
    pixelBuffer.resize(1024 * 1024 * 4);
    memset(pixelBuffer.data(), 0, 1024 * 1024 * 4);
    if (!outputImage->write_image(pixelFormat, pixelBuffer.data()))
    {
        printf("Failed to write temp_save_image.png\n");
        return false;
    }

    outputImage->close();

    remove("temp_save_image.png");

    return true;
}


bool testWritingImage_tif_float() // one channel 32-bit-float (4 bytes per channel)
{
    using namespace OIIO;
     OIIO::TypeDesc pixelFormat = OIIO::TypeDesc::FLOAT;
    std::unique_ptr<OIIO::ImageOutput> outputImage = OIIO::ImageOutput::create("temp_save_image.tif");
    if (!outputImage)
    {
        printf("Failed to create the OIIO::ImageOutput.\n");
        return false;
    }

    OIIO::ImageSpec spec(1024, 1024, 1, pixelFormat);
    if (!outputImage->open("temp_save_image.tif", spec))
    {
        printf("Failed to open temp_save_image.tif\n");
        return false;
    }

    std::vector<unsigned char> pixelBuffer;
    pixelBuffer.resize(1024 * 1024 * 4);
    memset(pixelBuffer.data(), 0, 1024 * 1024 * 4);
    if (!outputImage->write_image(pixelFormat, pixelBuffer.data()))
    {
        printf("Failed to write temp_save_image.tif\n");
        return false;
    }

    outputImage->close();

    remove("temp_save_image.tif");

    return true;
}


int main()
{
    if (!testReadingImage())
    {
        return 1;
    }

    if (!testWritingImage())
    {
        return 1;
    }

    if (!testWritingImage_tif_float())
    {
        return 1;
    }

    
    return 0;
}
