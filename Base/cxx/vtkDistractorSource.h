/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDistractorSource.h,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkDistractorSource - generate a distractor
// .SECTION Description
// vtkDistractorSource creates a polygonal distractor

#ifndef __vtkDistractorSource_h
#define __vtkDistractorSource_h

#include "vtkPolyDataSource.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkDistractorSource : public vtkPolyDataSource 
{
public:
  vtkDistractorSource(int res=6);
  static vtkDistractorSource *New() {return new vtkDistractorSource;};
  const char *GetClassName() {return "vtkDistractorSource";};
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Set the angle of rotation
  vtkSetClampMacro(Angle,float,0.0,VTK_LARGE_FLOAT)
  vtkGetMacro(Angle,float);

  // Description:
  // Set the distance of translation
  vtkSetClampMacro(Distance,float,0.0,VTK_LARGE_FLOAT)
  vtkGetMacro(Distance,float);

  // Description:
  // Set the width
  vtkSetClampMacro(Width,float,0.0,VTK_LARGE_FLOAT)
  vtkGetMacro(Width,float);

  // Description:
  // Set the footprint size
  vtkSetClampMacro(FootWidth,float,0.0,VTK_LARGE_FLOAT)
  vtkGetMacro(FootWidth,float);

  // Description:
  // Set/Get rotation center
  vtkSetVector3Macro(Center,float);
  vtkGetVectorMacro(Center,float,3);

  // Description:
  // Set/Get distractor rotation axis
  vtkSetVector3Macro(Axis,float);
  vtkGetVectorMacro(Axis,float,3);

  // Description:
  // Set/Get distractor start point
  vtkSetVector3Macro(Start,float);
  vtkGetVectorMacro(Start,float,3);

  // Description:
  // Set the number of facets used to define distractor.
  vtkSetClampMacro(Resolution,int,0,VTK_CELL_SIZE)
  vtkGetMacro(Resolution,int);

  // Description:
  // Set/Get foot normal
  vtkSetVector3Macro(FootNormal,float);
  vtkGetVectorMacro(FootNormal,float,3);

protected:
  void Execute();
  float Angle;
  float Distance;
  float Width;
  float FootWidth;
  float Center[3];
  float Axis[3];
  float Start[3];
  float FootNormal[3];
  int Resolution;

};

#endif


