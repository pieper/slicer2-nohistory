/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPelvisMetric.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#ifndef __vtk_pelvis_metric_h
#define __vtk_pelvis_metric_h
#include "vtkMorphometricsConfigure.h"
#include <vtkObject.h>
#include <vtkPlaneSource.h>
#include <vtkPolyData.h>
#include "vtkAxisSource.h"
//---------------------------------------------------------
// Author: Axel Krauth
//
// This class represents the basic and derived geometric
// properties of a hip. The basic properties are the acetabular
// plane as well as a coordinate system. The derived properties
// are the anteversion and inclination, which are the angles of the 
// acetabular plane in the coordinate system.
//
// The anteversion and inclination are dependend on a hip coordinate
// system since without they would be dependend how the image was acquired.
//
// The user has three options for coordinate systems within anteversion and
// inclination are computed:
//  - the global coordinate system (== world coordinate system)
//  - the object coordinate system ( determined by the principal axes). This
//    is the only csys which yields the same results under translation and
//    rotation of the same hip.
//  - a symmetry adapted coordinate system. This is what an physician uses on an x-ray:
//    connect two symmetric points on the hip and compute the inclination
//    based on that line. the x-axis of this csys is the symmetry axis of
//    the hip. Basically this corrects rotation along the y-axis in the way
//    a physician corrects it. Use this one. 
//
//
// One thing is clearly missing: A way to compute the z-axis (== body axis)
// solely based on the hip. That would allow to define a csys which is on the
// one hand acceptable for a physician and on the other hand rotational and
// translational invariant.

class VTK_MORPHOMETRICS_EXPORT vtkPelvisMetric : public vtkObject
{
 public:
  static vtkPelvisMetric* New();
  void Delete();
  vtkTypeMacro(vtkPelvisMetric,vtkObject);
  void PrintSelf();

  vtkGetMacro(InclinationAngle,vtkFloatingPointType);
  vtkGetMacro(AnteversionAngle,vtkFloatingPointType);

  void SetPelvis(vtkPolyData*);
  vtkGetObjectMacro(Pelvis,vtkPolyData);
  vtkGetObjectMacro(WorldToObject,vtkTransform);

 // center of gravity of the member Pelvis
  vtkGetVector3Macro(Center,vtkFloatingPointType);

  vtkGetObjectMacro(AcetabularPlane,vtkPlaneSource);

  // Update the members so that they fulfill some properties as well as 
  // computes the derived values.
  void Normalize();

 // the following three functions set the coordinate system in which the inclination and the anteversion are
 // computed. The ObjectCsys is the only one which computes the same results if the pelvis is rotated. But 
 // the coordinate system is not necessarily the same a physician uses. WorldCsys does not adjustment, while
 // the SymmetryAdaptedWorldCsys adjusts is x-axis (in vtk this is from left to right from a patient POV) to
 // be the symmetry axis. This adjustment is done by a physician by connecting two symmetric points of the 
 // pelvis in a x-ray. 
  void WorldCsys(void);
  void ObjectCsys(void);
  void SymmetryAdaptedWorldCsys(void);

 protected:
  vtkPelvisMetric();
  ~vtkPelvisMetric();

 private:
  vtkPelvisMetric(vtkPelvisMetric&);
  void operator=(const vtkPelvisMetric);

 // representation of the acetabular plane
  vtkPlaneSource* AcetabularPlane;

 // model representing the pelvis
  vtkPolyData* Pelvis;

 // center of gravity of Pelvis
  vtkFloatingPointType* Center;

  vtkFloatingPointType InclinationAngle;
  vtkFloatingPointType AnteversionAngle;

  // recompute the angles
  void UpdateAngles();
  vtkFloatingPointType Angle(vtkFloatingPointType* Direction,vtkFloatingPointType* n);

  void NormalizeXAxis(vtkFloatingPointType* n);

  // transformation matrix from world coordinates to current object coordinate system
  vtkTransform* WorldToObject;

};

#endif
