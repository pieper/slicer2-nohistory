/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEstimateDiffusionTensor.h,v $
  Date:      $Date: 2006/02/14 20:57:40 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkEstimateDiffusionTensor - 
// .SECTION Description

#ifndef __vtkEstimateDiffusionTensor_h
#define __vtkEstimateDiffusionTensor_h

#include "vtkDTMRIConfigure.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkDoubleArray.h"
#include "vtkTransform.h"

class VTK_DTMRI_EXPORT vtkEstimateDiffusionTensor : public vtkImageMultipleInputFilter
{
 public:
  static vtkEstimateDiffusionTensor *New();
  vtkTypeMacro(vtkEstimateDiffusionTensor,vtkImageMultipleInputFilter);

  // Description:
  // Set the image created without diffusion gradients as gradient {0 0 0}.
  // WARNING: This is a deprecetead method to keep compatibility with
  // vtkImageDiffusionTensor.  Use instead SetInput.
  void SetNoDiffusionImage(vtkImageData *img) 
    {this->SetInput(0,img);
     double grad[3];
     grad[0]=0.0;
     grad[1]=0.0;
     grad[2]=0.0;
     this->SetDiffusionGradient(0,grad);
    }

  // Description:
  // Set the image corresponding to diffusion gradient number num
  // WARNING: This is a deprecetead method to keep compatibility with
  // vtkImageDiffusionTensor.  Use instead SetInput.
  void SetDiffusionImage(int num, vtkImageData *img) 
    {this->SetInput(num+1,img);}

  // Description:
  // The number of gradients is the same as the number of input
  // diffusion ImageDatas this filter will require.
  void SetNumberOfGradients(int num);
  vtkGetMacro(NumberOfGradients,int);

  // Description:
  // Set the 3-vectors describing the gradient directions
  void SetDiffusionGradient(int num, vtkFloatingPointType gradient[3])
    {this->DiffusionGradient->SetTuple(num,gradient);}
  void SetDiffusionGradient(int num, vtkFloatingPointType g0, vtkFloatingPointType g1, vtkFloatingPointType g2)
    {this->DiffusionGradient->SetComponent(num,0,g0);
      this->DiffusionGradient->SetComponent(num,1,g1);
      this->DiffusionGradient->SetComponent(num,2,g2);}

  // Description:
  // Get the 3-vectors describing the gradient directions
  void GetDiffusionGradient(int num,double grad[3])
  { grad[0]=this->DiffusionGradient->GetComponent(num,0);
     grad[1]=this->DiffusionGradient->GetComponent(num,1);
     grad[2]=this->DiffusionGradient->GetComponent(num,2);
  }
  // the following look messy but are copied from vtkSetGet.h,
  // just adding the num parameter we need.


  void SetB(int num,double b)
   {
     this->B->SetValue(num,b);
    } 
  
  
   //Description
  vtkGetMacro(WeightedFitting,int);
  vtkSetMacro(WeightedFitting,int);
  vtkBooleanMacro(WeightedFitting,int);
  
  vtkGetMacro(ScaleFactor,double);
  
  // Description
  // Transformation of the tensors (for RAS coords, for example)
  // The gradient vectors are multiplied by this matrix
  vtkSetObjectMacro(Transform, vtkTransform);
  vtkGetObjectMacro(Transform, vtkTransform);

  // Description:
  // Internal class use only
  vtkFloatingPointType** GetPinvA() {return this->PinvA;}
  double **GetA(){return this->A;}
  
  // Description:
  // Internal class use only
  //BTX
  void TransformDiffusionGradients();
  
  void EstimateLSTensorModel(double *dwi,double **PinvA, double D[3][3],
  double &B0);
  void EstimateWLSTensorModel(double *dwi,double **AT, double D[3][3],
  double &B0);
  
  //ETX

 protected:
  vtkEstimateDiffusionTensor();
  ~vtkEstimateDiffusionTensor();
  vtkEstimateDiffusionTensor(const vtkEstimateDiffusionTensor&);
  void operator=(const vtkEstimateDiffusionTensor&);
  void PrintSelf(ostream& os, vtkIndent indent);

  int NumberOfGradients;

  vtkDoubleArray *B;
  vtkDoubleArray *DiffusionGradient;

  int WeightedFitting;

  // for transforming tensors
  vtkTransform *Transform;

  // Matrices for LS fitting
  double **A;
  double **PinvA;
  double ScaleFactor;
  
  void CalculatePseudoInverse();
  void CalculateA();
  double **AllocateMatrix(int rows, int columns);
  void DeallocateMatrix(double **M,int rows, int columns);

  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ExecuteInformation(){this->vtkImageMultipleInputFilter::ExecuteInformation();};
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
        int extent[6], int id);

  // We override this in order to allocate output tensors
  // before threading happens.  This replaces the superclass 
  // vtkImageMultipleInputFilter's Execute function.
  void ExecuteData(vtkDataObject *out);



};

#endif




