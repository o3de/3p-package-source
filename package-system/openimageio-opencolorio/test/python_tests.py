#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Verify the Python API for OpenImageIO

import os

import OpenImageIO as oiio
import PyOpenColorIO as ocio

def test_OpenImageIO():
    print("All is ok")
    test_directory = os.path.dirname(__file__)
    filename = os.path.join(test_directory, "base_Log2-48nits_16_LUT.exr")
    input_handle = oiio.ImageInput.open(filename)
    if input_handle is None:
        print(f"Was unable to read {filename}")
        return False

    if input_handle.has_error:
        print(f"Error during read of {filename}")
        return False

    spec = input_handle.spec()
    xres = spec.width
    yres = spec.height
    channels = spec.nchannels

    print(f"Name: {filename}")
    print(f"xres: {xres}")
    print(f"yres: {yres}")
    print(f"channels: {channels}")
    print(f"element type: {spec.format}")

    if (xres != 256) or (yres != 16) or (channels != 3):
        print("Invalid data.  Expected 256, 16, 3")
        return False

    pixels = input_handle.read_image("uint8")
    if pixels is None:
        print("Unable to read pixels from image.")
        return False

    expected_pixel_size = xres * yres * channels
    actual_pixel_size = pixels.size
    if actual_pixel_size != expected_pixel_size:
        print(f"Actual pixel size ({actual_pixel_size}) did not match expected pixel size ({expected_pixel_size})")
        return False

    if not input_handle.close():
        print(f"Error closing file handle: {input_handle.geterror()}")
        return False

    # Test success!
    return True

def test_OpenColorIO():
    # Quick test of the OCIO API to make sure we can retrieve the global config
    config = ocio.GetCurrentConfig()

    return config is not None
