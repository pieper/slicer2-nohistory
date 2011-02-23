/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAnisoGaussSeidel.h,v $
  Date:      $Date: 2006/01/06 17:57:40 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
/*  ==================================================
    Module: vtkFluxDiffusion
    Author: Karl Krissian
    Email:  karl@bwh.harvard.edu

    This module implements a version of anisotropic diffusion published in 
    
    "Flux-Based Anisotropic Diffusion Applied to Enhancement of 3D Angiographiam"
    Karl Krissian
    IEEE Trans. Medical Imaging, 21(11), pp 1440-1442, nov 2002.
    
    It aims at restoring 2D and 3D images with the ability to preserve
    small and elongated structures.
    It comes with a Tcl/Tk interface for the '3D Slicer'.
    ==================================================
    Copyright (C) 2002  Karl Krissian

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    ================================================== 
    The full GNU Lesser General Public License file is in vtkFluxDiffusion/LesserGPL_license.txt
*/

/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkAnisoGaussSeidel.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:40 $
  Version:   $Revision: 1.9 $
  Author:    Karl Krissian

=========================================================================*/
// .NAME vtkFastMarching - short description

#ifndef __vtkAnisoGaussSeidel_h
#define __vtkAnisoGaussSeidel_h

// Author Karl Krissian
//
// .SECTION Description
// vtkAnisoGaussSeidel 
// Applied an anisotropic diffusion to the data
// using the principal curvatures to lead the diffusion.
//  
//
//#include "vtkStructuredPointsToStructuredPointsFilter.h"

#include <vtkFluxDiffusionConfigure.h>

#include "vtkImageToImageFilter.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkImageGaussianSmooth.h"

#define DER_DISCR 1
#define DER_GAUSS 2

#define MODE_2D 2
#define MODE_3D 3



//----------------------------------------------------------------------
class VTK_FLUXDIFFUSION_EXPORT vtkAnisoGaussSeidel 
           : public vtkImageToImageFilter
{
public:
  vtkTypeMacro(vtkAnisoGaussSeidel,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Construct object to extract all of the input data.
  static vtkAnisoGaussSeidel *New();

  // current iteration number
  //
  vtkSetMacro(iteration,int);
  vtkGetMacro(iteration,int);

  // Dimensionality 2 for 2D, 3 for 3D
  vtkSetMacro(mode,int);
  vtkGetMacro(mode,int);

  // 0 or 1, if 1 set negatives values to 0
  vtkSetMacro(TruncNegValues,int);
  vtkGetMacro(TruncNegValues,int);

  // 
  vtkSetMacro(NumberOfIterations,int);
  vtkGetMacro(NumberOfIterations,int);

  // IsotropicCoeff*k is a threshold on the gradient norm
  // under which we apply isotropic diffusion
  vtkSetMacro(IsoCoeff,float);
  vtkGetMacro(IsoCoeff,float);

  // Standard deviation of the Gaussian kernel
  vtkSetMacro(sigma,float);
  vtkGetMacro(sigma,float);

  // Threshold on the gradient norm
  vtkSetMacro(k,float);
  vtkGetMacro(k,float);

  // data attachment coefficient
  vtkSetMacro(beta,float);
  vtkGetMacro(beta,float);

  // data attachment coefficient
  vtkSetMacro(TangCoeff,float);
  vtkGetMacro(TangCoeff,float);

  // data attachment coefficient
  vtkSetMacro(MincurvCoeff,float);
  vtkGetMacro(MincurvCoeff,float);

  // data attachment coefficient
  vtkSetMacro(MaxcurvCoeff,float);
  vtkGetMacro(MaxcurvCoeff,float);

  float Iterate2D();

  float Iterate3D();

  float Iterate3D( vtkImageData *tmpData, int tmpExt[6],
           vtkImageData *resData, int resExt[6], int threadId);

  float Iterate();

  void Init( );

  void ComputeInputUpdateExtent(int inExt[6], 
                int outExt[6]);

  void ThreadedExecute(vtkImageData *inData, 
               vtkImageData *outData,
               int extent[6], int threadId);

protected:

  vtkAnisoGaussSeidel();
  ~vtkAnisoGaussSeidel();

  // Allocate the coefficients alpha and gamma for each direction
  void InitCoefficients();

  //
  void InitCoefficients(float& alpha_x, float*& alpha_y, float**& alpha_z,
            float& gamma_x, float*& gamma_y, float**& gamma_z,
            int sx, int sy);

  // Reset the coefficients to 0
  void ResetCoefficients();

  // Reset the coefficients to 0
  void ResetCoefficients(float& alpha_x, float* alpha_y, float** alpha_z,
               float& gamma_x, float* gamma_y, float** gamma_z,
               int sx, int sy);

  // Free the memory allocated for the coefficients
    void DeleteCoefficients();

  // 
  void DeleteCoefficients( float*& alpha_y, float**& alpha_z,
               float*& gamma_y, float**& gamma_z,
               int sx);
    
    //
    //  void ThreadedExecute(vtkImageData *inData, 
    //               vtkImageData *outData, int outExt[6], int id);
    void ExecuteData(vtkDataObject *out);

//BTX
  //
  vtkImageGaussianSmooth* filter;

  vtkImageData*   image_entree ; 
  vtkImageData*   image_resultat;
  vtkImageData*   image_lissee  ;
  vtkImageData*   im_tmp1       ;
  vtkImageData*   im_tmp2       ;

  unsigned char   image_entree_allouee;

  float           _alpha_x;
  float           _gamma_x;
  float*          _alpha_y;
  float*          _gamma_y;
  float**         _alpha_z;
  float**         _gamma_z;
  
  int             mode;
  int             TruncNegValues;

  //  unsigned char   use_filtre_rec;
  unsigned char   opt_mem;
  float           sigma;
  float           beta;
  int             iteration;
  float           k;

  // IsoCoeff*k is a threshold on the gradient norm
  // under which we apply isotropic diffusion
  float           IsoCoeff;

  float           epsilon;
  int             tx,ty,tz,txy;

  int             NumberOfIterations;

  float           TangCoeff;
  float           MaxcurvCoeff;
  float           MincurvCoeff;

  unsigned char   SmoothedParam;

  float           progress;
  float           partial_progress;
  float           target,total;
  unsigned char   update_busy;

//ETX
}; // vtkAnisoGaussSeidel()

#endif // __vtkAnisoGaussSeidel_h
