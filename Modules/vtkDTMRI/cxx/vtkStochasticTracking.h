/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStochasticTracking.h,v $
  Date:      $Date: 2006/02/14 20:57:41 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkStochasticTracking - 
// .SECTION Description

#ifndef __vtkStochasticTracking_h
#define __vtkStochasticTracking_h

#include "vtkDTMRIConfigure.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkVectorToOuterProductDualBasis.h"
#include "vtkCollection.h"
#include "vtkDoubleArray.h"
#include "vtkIntArray.h"
#include "vtkTransform.h"

class vtkDiffusionModelParameters;


class VTK_DTMRI_EXPORT vtkStochasticTracking : public vtkImageMultipleInputFilter
{
 public:
  static vtkStochasticTracking *New();
  vtkTypeMacro(vtkStochasticTracking,vtkImageMultipleInputFilter);

  // Description:
  // Set the image created without diffusion gradients
  void SetNoDiffusionImage(vtkImageData *img) 
    {this->SetInput(0,img);}

  // Description:
  // Set the image corresponding to diffusion gradient number num
  void SetDiffusionImage(int num, vtkImageData *img) 
    {this->SetInput(num+1,img);}
  
  // Description:
  // Set the seed point (in scale ijk coordinates) where to start 
  // the tracking.
  // scaleijk[] = origin[] + spacing[]*ijk;
  void SetSeedPoint(double x, double y, double z)
    { this->SeedPoint[0]=x; this->SeedPoint[1]=y; this->SeedPoint[2]=z;
    };

  vtkGetVector3Macro(SeedPoint,double);

  // Description
  vtkSetObjectMacro(SphereDirections,vtkDoubleArray);
  vtkGetObjectMacro(SphereDirections,vtkDoubleArray);
  
  // Description
  // Step lenght for the tracking
  vtkSetMacro(StepLength,double);
  vtkGetMacro(StepLength,double);

 // Description
 vtkSetMacro(StoppingThreshold,double);
 vtkGetMacro(StoppingThreshold,double);

 // Description
 vtkSetMacro(MaxPathLength,double);
 vtkGetMacro(MaxPathLength,double);

 // Description
 vtkSetMacro(NumberOfPaths,int);
 vtkGetMacro(NumberOfPaths,int);


 //Description
 vtkGetMacro(WeightedFitting,int);
 vtkSetMacro(WeightedFitting,int);
 vtkBooleanMacro(WeightedFitting,int);

 //Description
 vtkGetMacro(ActiveCache,int);
 vtkSetMacro(ActiveCache,int);
 vtkBooleanMacro(ActiveCache,int);

 //Description:
 // Shape parameter for the prior: the higher, the pointier
 vtkSetMacro(Gamma,double);
 vtkGetMacro(Gamma,double);

 //Description:
 // Get the paths from the tracking execution
 vtkGetObjectMacro(Paths,vtkCollection);

 // Description
 // Access functions to the LS problem matrices
 double ** GetA() 
   { return this->A;}
 double ** GetAT()
   { return this->AT;}
 double ** GetPinvA()
   {return this->PinvA;}

  vtkGetMacro(ScaleFactor,double);
 
  // Description:
  // The number of gradients is the same as the number of input
  // diffusion ImageDatas this filter will require.
  void SetNumberOfGradients(int num);
  vtkGetMacro(NumberOfGradients,int);

  // Description:
  // Set the 3-vectors describing the gradient directions
  void SetDiffusionGradient(int num, vtkFloatingPointType gradient[3])
    {this->DualBasis->SetInputVector(num,gradient);}
  void SetDiffusionGradient(int num, vtkFloatingPointType g0, vtkFloatingPointType g1, vtkFloatingPointType g2)
    {this->DualBasis->SetInputVector(num,g0,g1,g2);}

  // Description:
  // Get the 3-vectors describing the gradient directions
  //  vtkFloatingPointType *GetDiffusionGradient(int num)
   // {return this->DualBasis->GetInputVector(num);}
  // the following look messy but are copied from vtkSetGet.h,
  // just adding the num parameter we need.

  virtual vtkFloatingPointType *GetDiffusionGradient(int num)
    { 
      vtkDebugMacro(<< this->GetClassName() << " (" << this << "): returning " << "DiffusionGradient pointer " << num << " " << this->DualBasis->GetInputVector(num)); 
      return this->DualBasis->GetInputVector(num);
    }

  // Description:
  // This is cheating since I don't know how to wrap this in tcl.
  //  First call SelectDiffusionGradient num
  //  Then GetSelectedDiffusionGradient to receive it as a string
  vtkGetVector3Macro(SelectedDiffusionGradient,vtkFloatingPointType);
  void SelectDiffusionGradient (int num)
    {
      this->SetSelectedDiffusionGradient(this->DualBasis->GetInputVector(num));
    }
  
  // Description:
  // Scale factor for parameters of gradient fields
  // (LeBihan's b factor for physical MR gradient parameters)
  vtkGetObjectMacro(B,vtkDoubleArray);
  vtkSetObjectMacro(B,vtkDoubleArray);


  // Description
  // Transformation of the tensors (for RAS coords, for example)
  // The gradient vectors are multiplied by this matrix
  vtkSetObjectMacro(Transform, vtkTransform);
  vtkGetObjectMacro(Transform, vtkTransform);

  // Description:
  // Internal class use only
  vtkFloatingPointType** GetG() {return this->G;}
  
  // Description:
  // Internal class use only
  vtkGetObjectMacro(DualBasis,vtkVectorToOuterProductDualBasis);

  vtkGetObjectMacro(SDMatchList,vtkIntArray);

  // Description:
  // Internal class use only
  //BTX
  void TransformDiffusionGradients();
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
        int range[2], int id);
  //ETX

 protected:
  vtkStochasticTracking();
  ~vtkStochasticTracking();
  vtkStochasticTracking(const vtkStochasticTracking&);
  void operator=(const vtkStochasticTracking&);
  void PrintSelf(ostream& os, vtkIndent indent);


  static void EstimateTensorModel (vtkStochasticTracking *self, vtkDiffusionModelParameters *diffparams, double **PinvA, double **ATW2);

  static void EstimateConstrainedModel (vtkStochasticTracking *self, vtkDiffusionModelParameters *diffparams);

  static void CalculateLikelihood (vtkStochasticTracking *self,  const vtkDiffusionModelParameters *diffparams,int NSamples, double *flatSD, double *likelihood);
 
  static void CalculatePrior (vtkStochasticTracking *self,  double vprev[3], double gamma, int NSamples, double *flatSD,double *prior);

  static void CalculatePosterior(int NSamples, const double *likelihood, const double *prior, double *posterior);

  int DrawRandomDirection(vtkStochasticTracking *self, const double *posterior);

  
  double StepLength;  

  double StoppingThreshold;

  double MaxPathLength;

  int NumberOfPaths;
    
  vtkCollection *Paths;

  int NumberOfGradients;

  int WeightedFitting;

  double Gamma;

  //Turn on and off the cache of the likelihood.
  int ActiveCache;

  // Lauren remove this factor?
  vtkDoubleArray *B;

  //MapType *LikelihoodCache;
  vtkCollection *LikelihoodCache;
  vtkIntArray *CacheId;

  // Matrices for LS fitting
  double **A;
  double **AT;
  double **PinvA;
  double ScaleFactor;
  
  double SeedPoint[3];


  double * FlatSD;
  vtkDoubleArray *SphereDirections;

  // for transforming tensors
  vtkTransform *Transform;

  vtkVectorToOuterProductDualBasis *DualBasis;
  // this is ~G 
  vtkFloatingPointType **G;


  // Array for sphere directions match list
  vtkIntArray *SDMatchList;

  void AllocatePaths();
  void DeallocatePaths();

  double **AllocateMatrix(int r, int c);
  void DeallocateMatrix(double **M,int r, int c);
  void CreateLSMatrix();


  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ExecuteInformation(){this->vtkImageMultipleInputFilter::ExecuteInformation();};

  void MultiThread(vtkImageData **inputs, vtkImageData *output);

  // We override this in order to allocate output tensors
  // before threading happens.  This replaces the superclass 
  // vtkImageMultipleInputFilter's Execute function.
  void ExecuteData(vtkDataObject *out);

  void CreateSphereDirectionsMatchList(void);

  // just for tcl wrapping
  vtkFloatingPointType SelectedDiffusionGradient[3];
  vtkSetVector3Macro(SelectedDiffusionGradient,vtkFloatingPointType);

};

#endif




