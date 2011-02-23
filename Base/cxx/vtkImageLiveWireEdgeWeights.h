/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireEdgeWeights.h,v $
  Date:      $Date: 2006/01/06 17:56:42 $
  Version:   $Revision: 1.26 $

=========================================================================auto=*/
// .NAME vtkImageLiveWireEdgeWeights -  Computes edge weights for input
// to vtkImageLiveWire.
// .SECTION Description
//  
// This filter takes a grayscale image as input and outputs
// edge costs in one direction (up, down, etc.).  These edge cost
// images form the weighted graph for input to vtkImageLiveWire, which 
// finds shortest paths in the graph (to aid image segmentation).
//
// The filter can also train based on an input labeled image.
//
// This version of the filter aligns the weighted graph with the
// "cracks" between pixels; another version that does not
// do this is under construction.
//

#ifndef __vtkImageLiveWireEdgeWeights_h
#define __vtkImageLiveWireEdgeWeights_h

//  #define LIVEWIRE_TRAINING_EXPERIMENT

#include "vtkImageData.h"
#include "vtkImageMultipleInputFilter.h"
#include "vtkSlicer.h"

//BTX

// This class contains all info necessary to use a computed feature
class featureProperties
{
 public:
  // pointer to member function to  convert image feature to cost (0<=cost<=1)
  float (featureProperties:: * Transform)(float val); 
  // parameters of this transform function
  float * TransformParams;
  int NumberOfParams;
  // weight, or importance, of this feature in the overall edge cost
  float Weight;
  featureProperties();
  ~featureProperties();

 protected:
  float GaussianCost(float x);

};

//ETX

class VTK_SLICER_BASE_EXPORT vtkImageLiveWireEdgeWeights : public vtkImageMultipleInputFilter
{
public:
  static vtkImageLiveWireEdgeWeights *New();
  vtkTypeMacro(vtkImageLiveWireEdgeWeights,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // grayscale ImageData for creating edge weight map
  void SetOriginalImage(vtkImageData *image) {this->SetInput(0,image);}
  vtkImageData *GetOriginalImage() {return this->GetInput(0);}

  // Description:
  // colormap with points of interest marked for training
  void SetTrainingPointsImage(vtkImageData *image) {this->SetInput(1,image);}
  vtkImageData *GetTrainingPointsImage() {return this->GetInput(1);}

  // Description:
  // colormap with previous (2D) image's contour drawn
  // not yet used.
  void SetPreviousContourImage(vtkImageData *image) {this->SetInput(2,image);}
  vtkImageData *GetPreviousContourImage() {return this->GetInput(2);}

  // Description:
  // Maximum edge weight that this filter will output
  vtkGetMacro(MaxEdgeWeight, int);
  vtkSetMacro(MaxEdgeWeight, int);

  // Description:
  // Direction of edges to compute
#define UP_EDGE 0
#define DOWN_EDGE 1
#define LEFT_EDGE 2
#define RIGHT_EDGE 3
  vtkGetMacro(EdgeDirection, int);
  void SetEdgeDirection(int edge);

  // Description: 
  // Set/Get the filename where the feature values will be written
  // Used for feature training experiments
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

  // Description:
  // Number of features computed per voxel
  vtkGetMacro(NumberOfFeatures, int);
  //vtkSetMacro(NumberOfFeatures, int);

  // Description:
  // Width of neighborhood to compute features in
  vtkGetMacro(Neighborhood, int);
  //vtkSetMacro(Neighborhood, int);

  // Description:
  // Set/Gets are for access from tcl
  // Lauren check bounds!!!!!!!!!!
  // Set a parameter used to compute this feature
  // Note that a variance of 0 should NOT be used.
  void SetParamForFeature(int featureNum, int paramNum, float param) 
    {this->FeatureSettings[featureNum].TransformParams[paramNum] = param;
    this->Modified();};
  // Get total number of parameters used to compute this feature
  int GetNumberOfParamsForFeature(int f) 
    {return this->FeatureSettings[f].NumberOfParams;};
  // Get value of a parameter
  float GetParamForFeature(int f, int p_)
    {return this->FeatureSettings[f].TransformParams[p_];};
  float GetWeightForFeature(int f)
    {return this->FeatureSettings[f].Weight;};
  void SetWeightForFeature(int f, float w_)
    {this->FeatureSettings[f].Weight = w_;
    this->Modified();};

  // Description:
  // Get all parameters used to compute the ith feature
  featureProperties *GetFeatureSettings(int f) {return &this->FeatureSettings[f];};

  // Description:
  // Turn on training mode, where means and variances are calculated
  // for all features
  void TrainingModeOn();
  void TrainingModeOff();
  vtkGetMacro(TrainingMode, int);

  // Description:
  // Multi-slice training mode, where means and variances are
  // calculated across many slices
  vtkBooleanMacro(TrainingComputeRunningTotals, int);
  vtkSetMacro(TrainingComputeRunningTotals, int);
  vtkGetMacro(TrainingComputeRunningTotals, int);

  // Description: 
  // The file where the feature means and variances will be written
  // Use this to save training information
  vtkSetStringMacro(TrainingFileName);
  vtkGetStringMacro(TrainingFileName);

  // Description: 
  // Write feature means and variances to the training file
  void WriteFeatureSettings();
  void AppendFeatureSettings(ofstream& of);
  void GetFeatureSettingsString(char *);

  // Description:
  // internal access from Execute: don't call this
  vtkSetMacro(RunningNumberOfTrainingPoints, int);
  vtkGetMacro(RunningNumberOfTrainingPoints, int);

  // Description:
  // internal access from Execute: don't call this
  float *GetTrainingAverages(){return this->TrainingAverages;};

  // Description:
  // internal access from Execute: don't call this
  float *GetTrainingVariances(){return this->TrainingVariances;};

  // Description:
  // internal access from Execute: don't call this
  vtkSetMacro(NumberOfTrainingPoints,int);

  // Description:
  // internal access from Execute: don't call this
  void GetKernelIndices(int &t, int &u, int &p, int &q, int &v, int &w);

protected:
  vtkImageLiveWireEdgeWeights();
  ~vtkImageLiveWireEdgeWeights();

  int MaxEdgeWeight;

  // What type of edges to compute (controls orientation of filter kernel)
  int EdgeDirection;

  // Total number of features to compute
  int NumberOfFeatures;

  // Neighborhood to compute features in
  int Neighborhood;

  // Array containing all settings for each feature
  // The intention is to make adding new features simple and general
  featureProperties *FeatureSettings;

  // for testing
  char *FileName;

  char *TrainingFileName;
  int TrainingMode;
  int TrainingComputeRunningTotals;
  // Description:
  // sum of number of points drawn on all training slices so far
  int RunningNumberOfTrainingPoints;
  // Description:
  // average of each feature
  float *TrainingAverages;
  // Description:
  // variance of each feature
  float *TrainingVariances;
  // Description:
  // total number of points used in computing averages/variances
  int NumberOfTrainingPoints;

  //BTX
  int t,u,p,q,v,w;
  //ETX

  void ExecuteInformation(vtkImageData **inputs, vtkImageData *output); 

  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData, 
    int extent[6], int id);
};

#endif

