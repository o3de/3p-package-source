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
#include <openssl/sha.h>
#include <openssl/evp.h>
#include <openssl/crypto.h>

int main(int argc, char* argv[])
{
    if (argc<3)
    {
        printf("Not enough arguments: %s [SSL Version Text] [SSL Version Text SHA256 Hash]", argv[0]);
        return 1;
    }

    const char* inputOpenSSLVersionText = argv[1];
    printf("Validating version text '%s': ", inputOpenSSLVersionText);

    if (strcmp(OPENSSL_VERSION_TEXT, inputOpenSSLVersionText) != 0)
    {
        printf("FAILURE!\n OpenSSL OPENSSL_VERSION_TEXT returned invalid text '%s'. Expecting '%s'.\n", OPENSSL_VERSION_TEXT, inputOpenSSLVersionText);
        return 1;
    }
    else
    {
        printf("OK\n");
    }

    if (OPENSSL_init_crypto(0, NULL) == 0)
    {
        printf("FAILURE! OPENSSL failed call to OPENSSL_init_ssl!\n");
        return 1;
    }

    // Compute a sha-1 hash
    unsigned char hash[SHA_DIGEST_LENGTH];
    SHA1(inputOpenSSLVersionText, strlen(inputOpenSSLVersionText), hash);

    // Generate a sha1sum string from the hash
    char sha1_hex[SHA_DIGEST_LENGTH*2+1] = {'\0'};
    char* p = sha1_hex;
    for (int i=0; i<SHA_DIGEST_LENGTH;i++, p+=2)
    {
        sprintf(p,"%.2x",hash[i]);
    }

    // Compare against the expected sha1sum (lower) 
    const char* inputOpenSSLVersionTextHash = argv[2];
    printf("Validating version text sha1sum '%s': ", inputOpenSSLVersionTextHash);

    if (strcmp(sha1_hex, inputOpenSSLVersionTextHash) != 0)
    {
        printf("FAILURE!\n OpenSSL failed sha1 sum comparison (%s != %s)\n", sha1_hex, inputOpenSSLVersionTextHash);
        return 1;
    }
    else
    {
        printf("OK\n");
    }

    printf("Success: All is ok!\n");

    OPENSSL_cleanup();

    return 0;
}
