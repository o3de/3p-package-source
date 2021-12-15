OpenImageIO and OpenColorIO

These packages are lumped together because they are interdependent - to build a python-supported OpenColorIO 
and OpenImageIO you need both of them already compiled and they have circular depdencies on each other.

Thus, they are placed in the same package.  To build them we'll do the following
1. build OpenImageIO without OpenColorIO or python
2. build OpenColorIO without python
3. (re)build OpenImageIO with python and OpenColorIO dependency
4. (re)build OpenColorIO with python and OpenImageIO dependency
5. Copy to temp dir and finish
