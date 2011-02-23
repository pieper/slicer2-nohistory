/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkFog.h,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

#ifndef __vtkFog_h
#define __vtkFog_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkRenderer.h"
#include "vtkSlicer.h"


class VTK_SLICER_BASE_EXPORT vtkFog : public vtkObject
{
public:

  vtkTypeMacro(vtkFog,vtkObject);
  //  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Create Fog Effect
  static vtkFog *New();

  // Description:
  // Turn on/off fog. 
  vtkSetMacro(    FogEnabled,int);
  vtkGetMacro(    FogEnabled,int);
  vtkBooleanMacro(FogEnabled,int);




  // Description:
  //   GL_FOG_START        params is a single integer or  floating-
  //                       point  value  that  specifies start, the
  //                       near distance used  in  the  linear  fog
  //                       equation.   The initial near distance is
  //                       0.
  //  for more details, try man glFog
  // Set/Get the parameter FogStart
  vtkSetMacro(FogStart, float);
  vtkGetMacro(FogStart, float);

  // Description:
  //   GL_FOG_END          params is a single integer or  floating-
  //                       point  value that specifies end, the far
  //                       distance used in the  linear  fog  equa-
  //                       tion.  The initial far distance is 1.
  //  for more details, try man glFog
  // Set/Get the parameter FogEnd
  vtkSetMacro(FogEnd, float);
  vtkGetMacro(FogEnd, float);

  // Description:
  // Set the fog parameter to the specified Renderer
  // 
  void Render(vtkRenderer *);


protected:
  vtkFog();

  int   FogEnabled;
  float FogStart;
  float FogEnd;

};



#endif //  __vtkFog_h
