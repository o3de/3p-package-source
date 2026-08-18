/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <Imath/ImathConfig.h>
#include <Imath/ImathMatrix.h>
#include <Imath/half.h>

// Some libraries also include <ImathConfig.h> without the prefix
// Make sure we're compatible.
#include <ImathConfig.h>
#include <half.h>

#include <math.h>

using namespace Imath;

int main()
{
    // Really just an ultra basic test to make sure the includes and linkage works.

    Imath::M44f m;
    m.makeIdentity();
    m *= 4.0f;
    if (fabs(4.0f - m[0][0]) > 0.01f)
    {
        printf("Test failed - expected 4.0f, got %f\n", m[0][0]);
        return 1;
    }
    printf("Sanity test pass for Imath::M44f\n");
    Imath::half h(1.0f);
    float hValue = h;

    if (fabs(1.0f - hValue) > 0.01f)
    {
        printf("Test failed - expected 1.0f, got %f\n", hValue);
        return 1;
    }
    printf("Sanity test pass for Imath::half\n");
    printf("All is ok\n");
    
    return 0;
}