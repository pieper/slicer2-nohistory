/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasSuperClassNode.h,v $
  Date:      $Date: 2006/01/06 17:57:31 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterAtlasClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterAtlasSuperClassNode_h
#define __vtkMrmlSegmenterAtlasSuperClassNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMAtlasBrainClassifierConfigure.h>

class VTK_EMATLASBRAINCLASSIFIER_EXPORT vtkMrmlSegmenterAtlasSuperClassNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterAtlasSuperClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterAtlasSuperClassNode,vtkMrmlNode);

  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *anode);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(NumClasses, int);
  vtkGetMacro(NumClasses, int);

  // Description:
  // Print out the result after how many steps  (-1 == just last result, 0 = No Printing, i> 0 => every i-th slice )
  vtkGetMacro(PrintFrequency, int);
  vtkSetMacro(PrintFrequency, int);

  vtkGetMacro(PrintBias, int);
  vtkSetMacro(PrintBias, int);

  vtkGetMacro(PrintLabelMap, int);
  vtkSetMacro(PrintLabelMap, int);  

  // Description:  
  // After which criteria should be stopped   
  // 0 = fixed iterations 
  // 1 = Absolut measure 
  // 2 = Relative measure 
  vtkGetMacro(StopEMType,int); 
  vtkSetMacro(StopEMType,int); 
  
  // Description:  
  // What is the obundary value, note if the number of iterations 
  // extend EMiter than stops than
  vtkGetMacro(StopEMValue,float);      
  vtkSetMacro(StopEMValue,float); 

  vtkGetMacro(StopEMMaxIter,int); 
  vtkSetMacro(StopEMMaxIter,int); 


  // Description:  
  // After which criteria should be stopped   
  // 0 = fixed iterations 
  // 1 = Absolut measure 
  // 2 = Relative measure 
  vtkGetMacro(StopMFAType,int); 
  vtkSetMacro(StopMFAType,int); 
  
  // Description:  
  // What is the obundary value, note if the number of iterations 
  // extend MFAiter than stops than
  vtkGetMacro(StopMFAValue,float);      
  vtkSetMacro(StopMFAValue,float); 

  vtkGetMacro(StopMFAMaxIter,int); 
  vtkSetMacro(StopMFAMaxIter,int); 


  // Description:
  // Kilian: Jan06: InitialBias_FilePrefix allows initializing a bias field with a precomputed one 
  // - carefull Bias Field has to be in little Endian  - needed it for debugging
  vtkSetStringMacro(InitialBiasFilePrefix);
  vtkGetStringMacro(InitialBiasFilePrefix);

  // Description:
  // Kilian: Jan06: This allows you to "jump" over the hirarchical segmentation level by providing an already existing 
  // labelmap of the region of interes 
  vtkSetStringMacro(PredefinedLabelMapPrefix); 
  vtkGetStringMacro(PredefinedLabelMapPrefix); 

  // When adding new variables do not forget to add them also to vtkMrmlSegmenterSuperClass in the appropriate way  
protected:
  vtkMrmlSegmenterAtlasSuperClassNode();
  ~vtkMrmlSegmenterAtlasSuperClassNode();
  vtkMrmlSegmenterAtlasSuperClassNode(const vtkMrmlSegmenterAtlasSuperClassNode&) {};
  void operator=(const vtkMrmlSegmenterAtlasSuperClassNode&) {};

  int NumClasses;

  int PrintFrequency;
  int PrintBias;
  int PrintLabelMap;

  int StopEMType;       // After which criteria should be stopped   
                                // 0 = fixed iterations 
                                // 1 = Absolut measure 
                                // 2 = Relative measure
  float StopEMValue;    // What is the obundary value, note if the number of iterations 
                                // extend EMiter than stops than
                                // if (StopEMType = 1) than it is percent

  int StopEMMaxIter;

  int StopMFAType;       
  float StopMFAValue;    
  int StopMFAMaxIter;

  char* InitialBiasFilePrefix;  
  char* PredefinedLabelMapPrefix; 

};

#endif

/*
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
 

  int PrintShapeSimularityMeasure; // Prints out the shape cost at each voxel 
  int PrintEMLabelMapConvergence;  // Prints out the number of voxels changed from last to this iteration
  int PrintEMWeightsConvergence;   // Prints out the difference in percent 

  int PrintMFALabelMapConvergence;  
  int PrintMFAWeightsConvergence; 

  int StopBiasCalculation;

  int    RegistrationType; 
  int GenerateBackgroundProbability;

  int PCAShapeModelType;

  int RegistrationIndependentSubClassFlag;

 */
