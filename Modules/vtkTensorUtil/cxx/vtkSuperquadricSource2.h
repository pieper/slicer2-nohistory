/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSuperquadricSource2.h,v $
  Date:      $Date: 2006/06/27 20:50:51 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkSuperquadricSource2 - create a polygonal superquadric centered 
// at the origin
// .SECTION Description
// vtkSuperquadricSource2 creates a superquadric (represented by polygons) 
// of specified
// size centered at the origin. The resolution (polygonal discretization)
// in both the latitude (phi) and longitude (theta) directions can be
// specified. Roundness parameters (PhiRoundness and ThetaRoundness) control
// the shape of the superquadric.  The Scale parameters allow 
// the superquadric to be scaled in x, y, and z (normal vectors are correctly
// generated in any case).  The Size parameter controls size of the 
// superquadric.
//
// This code is based on "Rigid physically based superquadrics", A. H. Barr,
// in "Graphics Gems III", David Kirk, ed., Academic Press, 1992.
//
// .SECTION Caveats
// Resolution means the number of latitude or longitude lines for a complete
// superquadric. The resolution parameters are rounded to the nearest 4
// in phi and 8 in theta.
//
// Texture coordinates are not equally distributed around all superquadrics.
//
// The Size and Thickness parameters control coefficients of superquadric
// generation, and may do not exactly describe the size of the superquadric.
//

#ifndef __vtkSuperquadricSource2_h
#define __vtkSuperquadricSource2_h

#include "vtkTensorUtilConfigure.h"
#include "vtkPolyDataSource.h"

#define VTK_MAX_SUPERQUADRIC_RESOLUTION 1024
#define VTK_MIN_SUPERQUADRIC_THICKNESS  1e-4
#define VTK_MIN_SUPERQUADRIC_ROUNDNESS  1e-24

class VTK_TENSORUTIL_EXPORT vtkSuperquadricSource2 : public vtkPolyDataSource 
{
public:
  // Description:
  // Create a default superquadric with a radius of 0.5, non-toroidal,
  // spherical, and centered at the origin.
  static vtkSuperquadricSource2 *New();

  vtkTypeRevisionMacro(vtkSuperquadricSource2,vtkPolyDataSource);
  void PrintSelf(ostream& os, vtkIndent indent);

  //Description:
  //Axis of symmetry
  vtkSetMacro(AxisOfSymmetry,int);
  vtkGetMacro(AxisOfSymmetry,int);

  // Description:
  // Set the center of the superquadric. Default is 0,0,0.
  vtkSetVector3Macro(Center,double);
  vtkGetVectorMacro(Center,double,3);

  // Description:
  // Set the scale factors of the superquadric. Default is 1,1,1.
  vtkSetVector3Macro(Scale,double);
  vtkGetVectorMacro(Scale,double,3);

  // Description:
  // Set the number of points in the longitude direction.
  vtkGetMacro(ThetaResolution,int);
  void SetThetaResolution(int i);

  // Description:
  // Set the number of points in the latitude direction.
  vtkGetMacro(PhiResolution,int);
  void SetPhiResolution(int i);

  // Description:
  // Set/Get Superquadric ring thickness (toroids only).
  // Changing thickness maintains the outside diameter of the toroid.
  vtkGetMacro(Thickness,double);
  vtkSetClampMacro(Thickness,double,VTK_MIN_SUPERQUADRIC_THICKNESS,1.0);

  // Description:
  // Set/Get Superquadric north/south roundness.
  // Values range from 0 (rectangular) to 1 (circular) to higher orders.
  vtkGetMacro(PhiRoundness,double);
  void SetPhiRoundness(double e);

  // Description:
  // Set/Get Superquadric east/west roundness.
  // Values range from 0 (rectangular) to 1 (circular) to higher orders.
  vtkGetMacro(ThetaRoundness,double);
  void SetThetaRoundness(double e);

  // Description:
  // Set/Get Superquadric isotropic size.
  vtkSetMacro(Size,double);
  vtkGetMacro(Size,double);

  // Description:
  // Set/Get whether or not the superquadric is toroidal (1) or ellipsoidal (0).
  vtkBooleanMacro(Toroidal,int);
  vtkGetMacro(Toroidal,int);
  vtkSetMacro(Toroidal,int);

protected:
  vtkSuperquadricSource2(int res=16);
  ~vtkSuperquadricSource2() {};

  int Toroidal;
  int AxisOfSymmetry;
  double Thickness;
  double Size;
  double PhiRoundness;
  double ThetaRoundness;
  void Execute();
  double Center[3];
  double Scale[3];
  int ThetaResolution;
  int PhiResolution;

private:
  vtkSuperquadricSource2(const vtkSuperquadricSource2&);  // Not implemented.
  void operator=(const vtkSuperquadricSource2&);  // Not implemented.
};

#endif

