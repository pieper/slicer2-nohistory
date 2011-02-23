/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkFemurMetric.h,v $
  Date:      $Date: 2006/04/13 14:02:15 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#ifndef __vtk_femur_metric_h
#define __vtk_femur_metric_h

#include <vtkMorphometricsConfigure.h>

#include "vtkDataSetToLabelMap.h" // for inline
#include "vtkStructuredPoints.h" // for inline

//---------------------------------------------------------
// Author: Axel Krauth
//
// This class represents the basic and derived geometric
// properties of a thigh bone. The basic properties are
// an approximating sphere for the head, an axis for the
// neck as well as for the shaft. The only derived property
// at the moment is the angle between the neck and the shaft axis
//
// To be able to compute the basic properties, a distance-to-surface
// map is computed.

class vtkPolyData;
class vtkSphereSource;
class vtkAxisSource;
class vtkDataSetTriangleFilter;
class vtkImageEuclideanDistance;
class vtkImageDijkstra;
class VTK_MORPHOMETRICS_EXPORT vtkFemurMetric : public vtkObject
{
 public:
  static vtkFemurMetric* New();
  void Delete();
  vtkTypeMacro(vtkFemurMetric,vtkObject);
  void PrintSelf();

  vtkGetObjectMacro(Femur,vtkPolyData);
  void SetFemur(vtkPolyData*);

  vtkGetMacro(NeckShaftAngle,vtkFloatingPointType);

 // representation of the approximation of the head sphere
  vtkGetObjectMacro(HeadSphere,vtkSphereSource);

  vtkGetObjectMacro(NeckAxis,vtkAxisSource);

  vtkGetObjectMacro(ShaftAxis,vtkAxisSource);

  vtkGetVector3Macro(HeadCenter,vtkFloatingPointType);
  vtkSetVector3Macro(HeadCenter,vtkFloatingPointType);

  vtkGetVector3Macro(NeckShaftCenter,vtkFloatingPointType);
  vtkSetVector3Macro(NeckShaftCenter,vtkFloatingPointType);

  vtkGetVector3Macro(DistalPoint,vtkFloatingPointType);
  vtkSetVector3Macro(DistalPoint,vtkFloatingPointType);
 
 // ensure that the geometry fulfills some properties, i.e. the head
 // of femur is in the halfspace specified by the NeckShaftPlane
  void Normalize();

  void ComputeNeckShaftAngle();

  void Precompute();

  void FittNeckAxis() {FittAxis(NeckAxis,HeadCenter,NeckShaftCenter);};

  void FittShaftAxis(){FittAxis(ShaftAxis,NeckShaftCenter,DistalPoint);};
 protected:
  vtkFemurMetric();
  ~vtkFemurMetric();

 private:
  vtkFemurMetric(vtkFemurMetric&);
  void operator=(const vtkFemurMetric);

  vtkSphereSource* HeadSphere;
  
  vtkAxisSource* NeckAxis;

  vtkAxisSource* ShaftAxis;

  vtkPolyData* Femur;

  vtkFloatingPointType NeckShaftAngle;

  vtkFloatingPointType* HeadCenter;
 
  vtkFloatingPointType* NeckShaftCenter;

  vtkFloatingPointType* DistalPoint;

  vtkDataSetTriangleFilter* TriangledFemur;

  vtkDataSetToLabelMap* Volume;

  vtkImageEuclideanDistance* DepthAnnotatedVolume;

  vtkImageDijkstra* Dijkstra;

  void FittAxis(vtkAxisSource*,vtkFloatingPointType* source,vtkFloatingPointType* sink);
  void FindPoints();
  void FindDeepestPoint(vtkFloatingPointType*);
  void FindNearestInside(int* p);

  bool IsInsideVolume(int* p){return IsInsideVolume(p[0],p[1],p[2]);};
#if (VTK_MAJOR_VERSION == 4 && VTK_MINOR_VERSION >= 3)
  bool IsInsideVolume(int x,int y, int z){return 2== ((int)(Volume->GetOutput()->GetScalarComponentAsDouble(x,y,z,0)));};
#else
  bool IsInsideVolume(int x,int y, int z){return 2== ((int)(Volume->GetOutput()->GetScalarComponentAsFloat(x,y,z,0)));};
#endif
};

#endif
