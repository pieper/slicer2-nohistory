/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: GeneralLinearModel.h,v $
  Date:      $Date: 2006/01/06 17:57:35 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/

// .NAME GeneralLinearModel - Computes voxel activation based on general linear model.
// .SECTION Description
// The general linear model that is currently used is an external library, which is
// part of Gnu Scientific Library (http://sources.redhat.com/gsl/).


#ifndef __GeneralLinearModel_h
#define __GeneralLinearModel_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkFloatArray.h"

class VTK_FMRIENGINE_EXPORT GeneralLinearModel
{
    public:
    // Description:
    // Sets the design matrix 
    // It returns 0 if successful; 1 otherwise.
    static int SetDesignMatrix(vtkFloatArray *designMatrix);
    static int SetAR1DesignMatrix(vtkFloatArray *AR1designMatrix);
    static int SetWhitening (int status);

    // Description:
    // Fits the linear model, with the following inputs:
    // designMatrix - glm design matrix
    // dims - dimensions of the design matrix (dims[0]: number of rows; dims[1]: number of cols)
    // timeCourse - voxel time course
    // beta - array of beta coefficients (output)
    // chisq - the sum of squares of the residuals from the best-fit (output)
    // It returns 0 if successful; 1 otherwise.
    static int FitModel(float *timeCourse, float *beta, float *chisq);

    // Description:
    // Frees the allocated momery 
    static void Free();


private:
    // returns chisq (sum of squares of residuals from best fit of data to linear model) for each voxel
    static float ComputeResiduals (float *timeCourse, float *beta, int numSamples, int numRegressors);
    static int *Dimensions;
    static int *whitening;
    static float **DesignMatrix;
    static float **AR1DesignMatrix;

};


#endif

