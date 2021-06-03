# 3p-package-source repo

This is where the "sources" (ie, build scripts which make packages) for the O3DE package system are located.

Note that the "sources" of most packages are not acutally stored here, most "package sources" actually just consist of a script which fetches the source code (or prebuilt packages) from somewhere else, constructs a temporary folder image for it, and then lets the package system pack that folder up as the package.

In general
 * Add your new pacakge to the appropriate package_build_list_host_xxxx file
 * Put the scripts or instructions to construct the package image folder into the package-system subfolder

Recommendation would be to make any temp packing in a folder called **/temp/** so as to use the current git ignores.

Some notable examples
 * xxhash - a tiny header-only library that is just committed-as-is since it fits in git.  No build scripts.
 * OpenSSL - this one uses vcpkg to build the package image.
 * Lua - this one uses a script called pull_and_build_from_git.py (in Scripts/extras) to build the package image.

 See the documentation (README.md in the main package scripts repo for a full description of how to author packages.)
 