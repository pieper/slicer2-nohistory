/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGLMVolumeGenerator.h,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/

#ifndef __vtkGLMVolumeGenerator_h
#define __vtkGLMVolumeGenerator_h


#include <vtkFMRIEngineConfigure.h>
#include <vtkActivationVolumeGenerator.h>
#include "vtkIntArray.h"
#include "vtkFloatArray.h"

class  VTK_FMRIENGINE_EXPORT vtkGLMVolumeGenerator : public vtkActivationVolumeGenerator
{
    public:
    static vtkGLMVolumeGenerator *New();
    vtkTypeMacro(vtkGLMVolumeGenerator, vtkActivationVolumeGenerator);

    vtkGetMacro(PreWhitening, int);
    vtkSetMacro(PreWhitening, int);
    
    // Description:
    // Sets the contrast vector. 
    void SetContrastVector(vtkIntArray *vec);

    // Description:
    // Sets the design matrix 
    void SetDesignMatrix(vtkFloatArray *designMat);

    protected:
    vtkGLMVolumeGenerator();
    ~vtkGLMVolumeGenerator();

    void ComputeStandardError(float rss, float corrCoeff);
    void SimpleExecute(vtkImageData *input,vtkImageData *output);

    vtkIntArray *ContrastVector;
    vtkFloatArray *DesignMatrix;
    
    int PreWhitening;
    float StandardError;
    int SizeOfContrastVector;
    float *beta;

    // X and C will be objects of vnl_matrix<float>
    // Since vnl_matrix is a class template, which can only be
    // declared in cxx file, we make X and C a void pointer here.
    // design matrix
    void *X;
    // pre-whitened design matrix;
    void *WX;
    // contrast vector
    void *C;
    
};


#endif
