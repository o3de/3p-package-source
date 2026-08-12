/*
 Copyright (c) Contributors to the Open 3D Engine Project.
 For complete copyright and license terms please see the LICENSE at the root of this distribution.
 
 SPDX-License-Identifier: Apache-2.0 OR MIT
*/

#include <yaml-cpp/yaml.h>
#include <sstream>

int main()
{
    // Really just an ultra basic test to make sure the includes and linkage works.

    // copied from the YAML tutorial
    YAML::Node node;  
    node["key"] = "value"; 
    node["seq"].push_back("first element"); 
    node["seq"].push_back("second element");

    node["mirror"] = node["seq"][0];  
    node["seq"][0] = "1st element";  
    node["mirror"] = "element #1";  

    std::stringstream fout;
    fout << node;
    printf("YAML output:\n%s\n", fout.str().c_str());

    // If we get here, then the test passed for now - we've established
    // that the library can find its includes, link, run, etc.
    printf("All is OK!");
    return 0;
}
