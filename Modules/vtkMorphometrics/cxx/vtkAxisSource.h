/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAxisSource.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_axis_source_h
#define __vtk_axis_source_h
#include <vtkMorphometricsConfigure.h>
#include <vtkObject.h>
#include <vtkPolyDataSource.h>
#include <vtkCylinderSource.h>
#include <vtkTransformPolyDataFilter.h>
#include <vtkTransform.h>
#include <vtkPolyData.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Representation of an axis as a transformed cylinder.

class VTK_MORPHOMETRICS_EXPORT vtkAxisSource : public vtkPolyDataSource
{
 public:
  static vtkAxisSource* New();
  void Delete();
  vtkTypeMacro(vtkAxisSource,vtkPolyDataSource);
  void PrintSelf();

  vtkGetVector3Macro(Center,vtkFloatingPointType);
  vtkGetVector3Macro(Direction,vtkFloatingPointType);

  void SetDirection(vtkFloatingPointType,vtkFloatingPointType,vtkFloatingPointType);
  void SetDirection(vtkFloatingPointType*);

  void SetCenter(vtkFloatingPointType,vtkFloatingPointType,vtkFloatingPointType);
  void SetCenter(vtkFloatingPointType*);
 
 // compute the angle between the direction of the argument axis or vector
 // returns degrees
 vtkFloatingPointType Angle(vtkFloatingPointType*);
 vtkFloatingPointType Angle(vtkAxisSource* right) {return Angle(right->Direction);};

 protected:
  vtkAxisSource();
  ~vtkAxisSource();

  void Execute();
 private:
  vtkAxisSource(vtkAxisSource&);
  void operator=(const vtkAxisSource);

 // visualization representation
  vtkCylinderSource* AxisSource;
  vtkTransformPolyDataFilter* AxisFilter;
  vtkTransform* AxisTransform;

 // internal representation
  vtkFloatingPointType* Direction;
  vtkFloatingPointType* Center;

 // two functions for making both representations consistent with each other.
 // the new values for the visualization variables or representation variables
 // are based on the not updated variables
 void UpdateVisualization();
 void UpdateRepresentation();
};

#endif
