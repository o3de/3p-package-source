set(VCPKG_TARGET_ARCHITECTURE x64)
# We link to the dynamic CRT (build with /MD) even when making static libs
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

