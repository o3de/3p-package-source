## OpenEXR from ASWF

The PATCH file (o3de-oexr.patch) just renames a single file in the vendored openjph library, 
to make it so that the object file name does not collide, and trigger 
https://github.com/AcademySoftwareFoundation/openexr/issues/2596
