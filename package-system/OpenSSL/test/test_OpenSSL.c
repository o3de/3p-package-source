/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.

 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <stdio.h>
#include <string.h>

// this is just a super basic include and compile and link test
// it doesn't exercise the library much, but if this compiles and links
// its likely that further testing needs to be done in a real full project
// rather than artificially

// test whether a header is found
#include <openssl/ssl.h>

int main()
{
    if (OPENSSL_init_ssl(0, NULL) == 0)
    {
        printf("FAILURE! OPENSSL failed call to OPENSSL_init_ssl!\n");
        return 1;
    }

    if (strcmp(OPENSSL_VERSION_TEXT, "OpenSSL 1.1.1m  14 Dec 2021") != 0)
    {
        printf("FAILURE! OpenSSL OPENSSL_VERSION_TEXT returned invalid text (%s)!\n", OPENSSL_VERSION_TEXT);
        return 1;
    }

    printf("Success: All is ok!\n");
    return 0;
}
