/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterClassNode.h,v $
  Date:      $Date: 2007/03/14 01:45:21 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterClassNode_h
#define __vtkMrmlSegmenterClassNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlSegmenterGenericClassNode.h"
#include "vtkSlicer.h"
#include <vtkEMLocalSegmentConfigure.h>
#include "vtkMrmlSegmenterAtlasClassNode.h"

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterClassNode : public vtkMrmlSegmenterGenericClassNode
{
public:
  static vtkMrmlSegmenterClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterClassNode,vtkMrmlNode);
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

  // Description:
  // Get/Set for SegmenterClass
  vtkSetStringMacro(PCAMeanName);
  vtkGetStringMacro(PCAMeanName);

  // Description:
  // Variance to maximum distance in the signed label map  
  vtkGetMacro(PCALogisticSlope,float);
  vtkSetMacro(PCALogisticSlope,float);

  vtkGetMacro(PCALogisticMin,float);
  vtkSetMacro(PCALogisticMin,float);

  vtkGetMacro(PCALogisticMax,float);
  vtkSetMacro(PCALogisticMax,float);

  vtkGetMacro(PCALogisticBoundary,float);
  vtkSetMacro(PCALogisticBoundary,float);
  
  vtkSetMacro(PrintPCA,int);
  vtkGetMacro(PrintPCA,int);

  int GetLabel() {return AtlasClassNode->GetLabel();}
  void SetLabel(int init) {AtlasClassNode->SetLabel(init);}

  char* GetLogMean()  {return AtlasClassNode->GetLogMean();}
  void SetLogMean(char* init) {AtlasClassNode->SetLogMean(init);}

  char* GetLogCovariance()  {return AtlasClassNode->GetLogCovariance();}
  void SetLogCovariance(char* init) {AtlasClassNode->SetLogCovariance(init);}

  char* GetReferenceStandardFileName()  {return AtlasClassNode->GetReferenceStandardFileName();}
  void SetReferenceStandardFileName(char* init) {AtlasClassNode->SetReferenceStandardFileName(init);}

  int GetPrintQuality()  {return AtlasClassNode->GetPrintQuality();}
  void SetPrintQuality(int init) {AtlasClassNode->SetPrintQuality(init);}


  // Description:
  // Get/Set mean log intensities generated by auto sampling 
  vtkSetStringMacro(SamplingLogMean);
  vtkGetStringMacro(SamplingLogMean);

  // Description:
  // Get/Set variance of log intensities generated by auto sampling  
  vtkSetStringMacro(SamplingLogCovariance);
  vtkGetStringMacro(SamplingLogCovariance);

  //Description: 
  // For MICCAI 2007 - Weights can be loaded from outside and be fixed 
  vtkSetStringMacro(FixedWeightsName);
  vtkGetStringMacro(FixedWeightsName);
  
protected:
  vtkMrmlSegmenterClassNode();
  ~vtkMrmlSegmenterClassNode();

  vtkMrmlSegmenterAtlasClassNode *AtlasClassNode;

  char  *PCAMeanName;
  float PCALogisticSlope;
  float PCALogisticMin;
  float PCALogisticMax;
  float PCALogisticBoundary;
  int   PrintPCA;            // Print out PCA Parameters at each step 

  char   *SamplingLogMean;
  char   *SamplingLogCovariance;

  char *FixedWeightsName;

private:
  vtkMrmlSegmenterClassNode(const vtkMrmlSegmenterClassNode&);
  void operator=(const vtkMrmlSegmenterClassNode&);
};

#endif

