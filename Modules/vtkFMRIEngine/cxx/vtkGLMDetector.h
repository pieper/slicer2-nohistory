/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGLMDetector.h,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

// .NAME vtkGLMDetector - Computes voxel activation   
// .SECTION Description
// vtkGLMDetector is used to compute voxel activation based on
// paradigm and detection method (GLM or MI).


#ifndef __vtkGLMDetector_h
#define __vtkGLMDetector_h


#include <vtkFMRIEngineConfigure.h>
#include "vtkActivationDetector.h"
#include "vtkFloatArray.h"
#include <iostream>
#include <fstream>
using namespace std;

class VTK_FMRIENGINE_EXPORT vtkGLMDetector : public vtkActivationDetector 
{
    public:
    static vtkGLMDetector *New();
    vtkTypeMacro(vtkGLMDetector, vtkActivationDetector);

    vtkGLMDetector();
    ~vtkGLMDetector();

    // Description:
    // Gets the design matrix 
    vtkFloatArray *GetDesignMatrix();

    // Description:
    // Sets the design matrix 
    void SetDesignMatrix(vtkFloatArray *designMat);
    void SetAR1DesignMatrix ( );
    vtkFloatArray *GetAR1DesignMatrix ( );
    vtkFloatArray *GetResiduals ( );
    
    // Description:
    // Fits linear model (voxel by voxel) 
    void FitModel(vtkFloatArray *timeCourse, float *beta, float *chisq ); 

    // This uses the first estimated beta to subtract
    // the model from the data to compute errors like so:
    // Y = XB + e --> e = Y-XB_hat
    void ComputeResiduals ( vtkFloatArray *timeCourse, float *beta );
    // Description::
    // This uses the residuals to compute the correlation coefficient
    // at lag 1 used in pre-whitening for data and residuals.
    float ComputeCorrelationCoefficient ( );
    // Description:
    // This whitens the DesignMatrix and timeCourse.
    // Saves the whitened design matrix in AR1DesignMatrix,
    // and replaces the extracted timecourse by new values.
    void PreWhitenDataAndResiduals (vtkFloatArray *timeCourse, float corrCoeff);
    // Description:
    // Sets the AR1DesignMatrix
    // and turns on the whitening flag.
    void EnableAR1Modeling ( );
    // Description:
    // This sets the AR1DesignMatrix to NULL,
    // sets the WhiteningMatrix to NULL,
    // and turns off the whitening flag.
    void DisableAR1Modeling ( );


    private:

    ofstream logfile;
    int NoOfRegressors;
    vtkFloatArray *DesignMatrix;
    // pre-whitened design matrix
    vtkFloatArray *AR1DesignMatrix;
    vtkFloatArray *residuals;
    
};


#endif
