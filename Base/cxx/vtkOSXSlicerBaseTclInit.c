//-----  This hack needed to compile using gcc3 on OSX until new stdc++.dylib
// grabbed from vtk4.2 Rendering
#include <stdio.h>
void oft_initSlicerBaseOSXInit() 
{
#if __GNUC__ < 4
  extern void _ZNSt8ios_base4InitC4Ev();
  _ZNSt8ios_base4InitC4Ev();
#endif
}

