/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

// test that the TIFF library imports correctly
// Doesn't test much else about it.  Can be expanded if this becomes a problem in the
// future.

#include <expat.h>
#include <stdio.h>

int main()
{
    FILE* xmlfile = fopen("example_file.xml", "rb");
    if (!xmlfile)
    {
      printf("Failed to open example_file.xml\n");
      return 1;
    }
    fseek(xmlfile, 0, SEEK_END);
    int bytes_to_read = (int)ftell(xmlfile);
    fseek(xmlfile, 0, SEEK_SET);
    printf("Reading %i bytes from file...\n", bytes_to_read);

    char* databuf = (char*)malloc(bytes_to_read + 1);
    if (fread(databuf, 1, bytes_to_read, xmlfile) != bytes_to_read)
    {
      printf("Could not read entire example_file.xml");
      return 0;
    }
    databuf[bytes_to_read] = 0;
    fclose(xmlfile);

    printf("invoking EXPAT to parse\n");
    XML_Parser parser = XML_ParserCreate(0);
    if (XML_Parse(parser, databuf, bytes_to_read, 1) == XML_STATUS_ERROR) 
    {
      printf("Error during reading: %s!\n", XML_ErrorString(XML_GetErrorCode(parser)));
      return 1;
    }

    XML_ParserFree(parser);

    printf("Trivial self test SUCCEEDED - no errors from parse.\n");

    return 0;

}