/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageEuclideanDistanceTransformation.h,v $
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkImageEuclideanDistanceTransformation.h,v $
  Language:  C++
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.11 $
  Thanks:    Olivier Cuisenaire who developed this class
             URL: http://ltswww.epfl.ch/~cuisenai
         Email: Olivier.Cuisenaire@epfl.ch

Copyright (c) Olivier Cuisenaire.

The authors hereby grant permission to use, copy, and distribute this
software and its documentation for any purpose, provided that existing
copyright notices are retained in all copies and that this notice is included
verbatim in any distributions. Additionally, the authors grant permission to
modify this software and its documentation for any purpose, provided that
such modifications are not distributed without the explicit consent of the
authors and that existing copyright notices are retained in all copies. Some
of the algorithms implemented by this software are patented, observe all
applicable patent law.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON AN
"AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=============================================================

This was "lent" to us by Olivier Cuisenaire and is copywrite to
him. He has a new version which is faster and better which is not yet
fully tested that he intends to check into the vtk in the near
future. It will have a different name (vtkImageEuclidianDistance).

When the new version is available, this version should dissapear.
However, for the time being, it exists and works. Note that this file
is not copyright MIT.

=========================================================================*/
// .NAME vtkImageEuclideanDistanceTransformation - computes 3D Euclidean DT 
// .SECTION Description
// vtkImageEuclideanDistanceTransformation implements the Euclidean DT using
// Saito's algorithm. The distance map produced contains the square of the
// Euclidean distance values. 
//
// The algorithm has a o(n^(D+1)) complexity over nxnx...xn images in D 
// dimensions. It is very efficient on relatively small images. Cuisenaire's
// algorithms should be used instead if n >> 500. A lot of the complexity
// is hidden by the multi-threading anyway.   
//
// References:
//
// T. Saito and J.I. Toriwaki. New algorithms for Euclidean distance 
// transformations of an n-dimensional digitised picture with applications.
// Pattern Recognition, 27(11). pp. 1551--1565, 1994. 
// 
// O.Cuisenaire. Memory-complexity and cache-efficiency of distance 
// transformation algorithms. Submitted to ICIP01. 
//
// O. Cuisenaire. Distance Transformation: fast algorithms and applications
// to medical image processing. PhD Thesis, Universite catholique de Louvain,
// October 1999. http://ltswww.epfl.ch/~cuisenai/papers/oc_thesis.pdf 
 

#ifndef __vtkImageEuclideanDistanceTransformation_h
#define __vtkImageEuclideanDistanceTransformation_h

#include "../imaging/vtkImageDecomposeFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageEuclideanDistanceTransformation : public vtkImageDecomposeFilter
{
public:
  vtkImageEuclideanDistanceTransformation();
  static vtkImageEuclideanDistanceTransformation *New() {return new vtkImageEuclideanDistanceTransformation;};
  const char *GetClassName() {return "vtkImageEuclideanDistanceTransformation";};

  // Description:
  // Used internally for streaming and threads.  
  // Splits output update extent into num pieces.
  // This method needs to be called num times.  Results must not overlap for
  // consistent starting extent.  Subclass can override this method.
  // This method returns the number of peices resulting from a
  // successful split.  This can be from 1 to "total".  
  // If 1 is returned, the extent cannot be split.
  int SplitExtent(int splitExt[6], int startExt[6], 
          int num, int total);

  // Description:
  // Used to set all non-zero voxels to MaximumDistance before starting
  // the distance transformation. Setting Initialize off keeps the current 
  // value in the input image as starting point. This allows to superimpose 
  // several distance maps. 
  vtkSetMacro(Initialize, int);
  vtkGetMacro(Initialize, int);
  vtkBooleanMacro(Initialize, int);
  
  // Description:
  // Used to define whether Spacing should be used in the computation of the
  // distances 
  vtkSetMacro(ConsiderAnisotropy, int);
  vtkGetMacro(ConsiderAnisotropy, int);
  vtkBooleanMacro(ConsiderAnisotropy, int);
  
  // Description:
  // Any distance bigger than this->MaximumDistance will not ne computed but
  // set to this->MaximumDistance instead. 
  vtkSetMacro(MaximumDistance, float);
  vtkGetMacro(MaximumDistance, float);

protected:
  float MaximumDistance;
  int Initialize;
  int ConsiderAnisotropy;

  void ExecuteInformation(vtkImageData *input, vtkImageData *output);
  void ExecuteInformation(){this->Subclass::ExecuteInformation();};

  void ComputeInputUpdateExtent(int inExt[6], int outExt[6]);
  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData,
               int outExt[6], int threadId);
};

#endif










