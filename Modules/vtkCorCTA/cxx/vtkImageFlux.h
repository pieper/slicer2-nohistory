/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageFlux.h,v $
  Date:      $Date: 2006/03/17 14:51:10 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkImageFlux.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkImageFlux - Divergence of a vector field.
// .SECTION Description
// vtkImageFlux takes a 3D vector field 
// and creates a scalar field which 
// which represents the rate of change of the vector field.
// The definition of Flux is:
// Given F = \sum < N, \nabla D>
// where N is the normals of a sphere center in the voxel with radius equal 1 pixel and
// \nabla D is the gradient of a potential field D.

#ifndef __vtkImageFlux_h
#define __vtkImageFlux_h

#include "vtkImageToImageFilter.h"

#include "vtkCorCTAConfigure.h"

class VTK_CORCTA_EXPORT vtkImageFlux : public vtkImageToImageFilter
{
public:
  static vtkImageFlux *New();
  vtkTypeRevisionMacro(vtkImageFlux,vtkImageToImageFilter);

protected:
  vtkImageFlux() {};
  ~vtkImageFlux() {};

  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  void ExecuteInformation(vtkImageData *inData, vtkImageData *outData);
  void ExecuteInformation(){this->vtkImageToImageFilter::ExecuteInformation();}
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
                       int ext[6], int id);

private:
  vtkImageFlux(const vtkImageFlux&);  // Not implemented.
  void operator=(const vtkImageFlux&);  // Not implemented.
};

#endif



