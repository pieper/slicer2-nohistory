/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterSuperClassNode.h,v $
  Date:      $Date: 2007/03/14 01:45:21 $
  Version:   $Revision: 1.23 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

//                                                                    vtkMrmlSegmenterAtlasClassNode
//                                                                                  ||
//                                                                                  \/
//                                                                   |-> vtkMrmlSegmenterClassNode
//                                                                   |
//  vtkMrmlNode -> vtkMrmlSegmenterAtlasGenericClassNode -> vtkMrmlSegmenterGenericClassNode
//                                                                   |
//                                                                   |-> vtkMrmlSegmenterSuperClassNode
//                                                                                  /\
//                                                                                  ||
//                                                                   vtkMrmlSegmenterAtlasSuperClassNode

#ifndef __vtkMrmlSegmenterSuperClassNode_h
#define __vtkMrmlSegmenterSuperClassNode_h

#include "vtkMrmlSegmenterGenericClassNode.h"
#include "vtkSlicer.h"
#include <vtkEMLocalSegmentConfigure.h>
#include "vtkMrmlSegmenterAtlasSuperClassNode.h"

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterSuperClassNode : public vtkMrmlSegmenterGenericClassNode
{
public:
  static vtkMrmlSegmenterSuperClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterSuperClassNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  int  GetNumClasses() {return AtlasNode->GetNumClasses();}
  void SetNumClasses(int init) {AtlasNode->SetNumClasses(init);}

  // Description:
  // Print out the result after how many steps  (-1 == just last result, 0 = No Printing, i> 0 => every i-th slice )
  int  GetPrintFrequency() {return AtlasNode->GetPrintFrequency();}
  void SetPrintFrequency(int init) {AtlasNode->SetPrintFrequency(init);}

  int  GetPrintBias() {return AtlasNode->GetPrintBias();}
  void SetPrintBias(int init) {AtlasNode->SetPrintBias(init);}

  int  GetPrintLabelMap() {return AtlasNode->GetPrintLabelMap();}
  void SetPrintLabelMap(int init) {AtlasNode->SetPrintLabelMap(init);}

 // Description:
  // Prints out the shape  cost at each voxel 
  vtkGetMacro(PrintShapeSimularityMeasure, int);
  vtkSetMacro(PrintShapeSimularityMeasure, int);

  // Description:
  // Prints out the number of voxels changed from last to this EM iteration
  vtkGetMacro(PrintEMLabelMapConvergence, int);  
  vtkSetMacro(PrintEMLabelMapConvergence, int);  

  // Description:
  // Prints out the difference in percent 
  vtkGetMacro(PrintEMWeightsConvergence, int);
  vtkSetMacro(PrintEMWeightsConvergence, int);

 // Description:
  // Prints out the number of voxels changed from last to this MFA iteration
  vtkGetMacro(PrintMFALabelMapConvergence, int);  
  vtkSetMacro(PrintMFALabelMapConvergence, int);  

  // Description:
  // Prints out the difference in percent 
  vtkGetMacro(PrintMFAWeightsConvergence, int);
  vtkSetMacro(PrintMFAWeightsConvergence, int);

  // Description:  
  // After which criteria should be stopped   
  // 0 = fixed iterations 
  // 1 = Absolut measure 
  // 2 = Relative measure 
  int  GetStopEMType() {return AtlasNode->GetStopEMType();}
  void SetStopEMType(int init) {AtlasNode->SetStopEMType(init);}
  
  // Description:  
  // What is the obundary value, note if the number of iterations 
  // extend EMiter than stops than
  float GetStopEMValue() {return AtlasNode->GetStopEMValue();}
  void SetStopEMValue(float init) {AtlasNode->SetStopEMValue(init);}

  int  GetStopEMMaxIter() {return AtlasNode->GetStopEMMaxIter();}
  void SetStopEMMaxIter(int init) {AtlasNode->SetStopEMMaxIter(init);}

  // Description:  
  // After which criteria should be stopped   
  // 0 = fixed iterations 
  // 1 = Absolut measure 
  // 2 = Relative measure 
  int  GetStopMFAType() {return AtlasNode->GetStopMFAType();}
  void SetStopMFAType(int init) {AtlasNode->SetStopMFAType(init);}

  // Description:  
  // What is the obundary value, note if the number of iterations 
  // extend MFAiter than stops than
  float  GetStopMFAValue() {return AtlasNode->GetStopMFAValue();}
  void SetStopMFAValue(float init) {AtlasNode->SetStopMFAValue(init);}

  int  GetStopMFAMaxIter() {return AtlasNode->GetStopMFAMaxIter();}
  void SetStopMFAMaxIter(int init) {AtlasNode->SetStopMFAMaxIter(init);}

  // Description:
  // Kilian: Jan06: InitialBias_FilePrefix allows initializing a bias field with a precomputed one 
  // - carefull Bias Field has to be in little Endian  - needed it for debugging
  char* GetInitialBiasFilePrefix() {return AtlasNode->GetInitialBiasFilePrefix();}
  void  SetInitialBiasFilePrefix(char* init) { AtlasNode->SetInitialBiasFilePrefix(init);}

  // Description:
  // Kilian April 06: Initialize the segmentation of all subclasses with the same parameter settting (that of this superclass). The following types are available: 
  // 0 = disable initialization     - be carefull parallel subtrees can influence each other
  // 1 = save to/load from file     - reading from file can slow down segmentation slightly
  // 2 = write to/read from memory  - make sure you have enough mem as this can eat up a lot of memory 
  vtkSetMacro(ParameterInitSubClass,int); 
  vtkGetMacro(ParameterInitSubClass,int); 

  // Description:
  // Save all parameters after segmenting the super class to a file (bias and labelmap)  
  vtkSetMacro(ParameterSaveToFile,int); 
  vtkGetMacro(ParameterSaveToFile,int); 

  // Description:
  // Instead of segmenting the superclass we load them from a file (see also ParameterSaveToFile) 
  vtkSetMacro(ParameterSetFromFile,int); 
  vtkGetMacro(ParameterSetFromFile,int); 

  // Description:
  // Kilian: Jan06: This allows you to "jump" over the hirarchical segmentation level by providing an already existing 
  // labelmap of the region of interes 
  char* GetPredefinedLabelMapPrefix() {return AtlasNode->GetPredefinedLabelMapPrefix();}
  void  SetPredefinedLabelMapPrefix(char* init) { AtlasNode->SetPredefinedLabelMapPrefix(init);}

  // Description:
  // You can stop the bias calculation after a certain number of iterations
  // By default it is set to -1 which means it never stops
  vtkGetMacro(StopBiasCalculation,int); 
  vtkSetMacro(StopBiasCalculation,int); 

  // Description:
  // Activation of Registration within EM algorithm of atlas to image space 
  vtkGetMacro(RegistrationType, int);
  vtkSetMacro(RegistrationType, int);

  // Description:
  // If the flag is defined the spatial distribution of the first class will be automatically generated. 
  // In specifics the spatial distribution at voxel x is defined as 
  // spd(x) = NumberOfTrainingSamples - sum_{all other srructures dependent on the supercals} spd_struct(x) 
  vtkGetMacro(GenerateBackgroundProbability,int);      
  vtkSetMacro(GenerateBackgroundProbability,int);      


  // Description:
  // This variable can have three settings :
  // 0 = The PCA Model is generated over all structures together
  // 1 = Each structure has its own PCA model defined 
  // 2 = Do not maximize over the shape setting  - just use the current setting 
  vtkGetMacro(PCAShapeModelType,int); 
  vtkSetMacro(PCAShapeModelType,int); 

  // Desciption:
  // This flag is for the registration cost function. By default all subclasses are seen as one. 
  // In some cases this causes a loss of contrast within the cost function so that the registration is not as reliable, 
  // e.g. when we define two SuperClasses (FG and BG) which are defined as outside the brain as BG and everything inside the brain as FG, 
  // than we cannot use the ventricles wont be used for the alignment. Hoewever in many cases this structure drives the registration soley so that 
  /// our method is not as rebust. For this specific case we would set the flag for FG and do not set it for BG !
  vtkGetMacro(RegistrationIndependentSubClassFlag,int);      
  vtkSetMacro(RegistrationIndependentSubClassFlag,int);      

  // Description:
  // Kilian: Jan06: Gives superclass the predefined ID , make sure that no other class has that label/ID - this simplifies 
  // using PredefinedLabelMapPrefix with different structure settings
  vtkGetMacro(PredefinedLabelID,int); 
  vtkSetMacro(PredefinedLabelID,int); 

  vtkSetMacro(PCARegistrationNumOfPCAParameters,int);
  vtkGetMacro(PCARegistrationNumOfPCAParameters,int);
  vtkSetMacro(PCARegistrationVectorDimension,int);
  vtkGetMacro(PCARegistrationVectorDimension,int);
  vtkSetStringMacro(PCARegistrationMean);
  vtkGetStringMacro(PCARegistrationMean);
  vtkSetStringMacro(PCARegistrationEigenMatrix);
  vtkGetStringMacro(PCARegistrationEigenMatrix);
  vtkSetStringMacro(PCARegistrationEigenValues);
  vtkGetStringMacro(PCARegistrationEigenValues);

  vtkGetStringMacro(InhomogeneityInitialDataNames);
  vtkSetStringMacro(InhomogeneityInitialDataNames);

protected:
  vtkMrmlSegmenterSuperClassNode();
  ~vtkMrmlSegmenterSuperClassNode();

  vtkMrmlSegmenterAtlasSuperClassNode *AtlasNode;

  int PrintShapeSimularityMeasure; // Prints out the shape cost at each voxel 
  int PrintEMLabelMapConvergence;  // Prints out the number of voxels changed from last to this iteration
  int PrintEMWeightsConvergence;   // Prints out the difference in percent 
  int PrintMFALabelMapConvergence;  
  int PrintMFAWeightsConvergence; 

  int StopBiasCalculation;
  int RegistrationType; 
  int GenerateBackgroundProbability;
  int PCAShapeModelType;
  int RegistrationIndependentSubClassFlag;
  int PredefinedLabelID;

  int ParameterInitSubClass;
  int ParameterSaveToFile; 
  int ParameterSetFromFile; 

  // MICCAI 2007
  int   PCARegistrationNumOfPCAParameters;
  int   PCARegistrationVectorDimension;
  char *PCARegistrationMean;
  char *PCARegistrationEigenMatrix; 
  char *PCARegistrationEigenValues;

  char *InhomogeneityInitialDataNames; 

private:
  vtkMrmlSegmenterSuperClassNode(const vtkMrmlSegmenterSuperClassNode&);
  void operator=(const vtkMrmlSegmenterSuperClassNode&);
};

#endif

