/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasClassNode.h,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterAtlasClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterAtlasClassNode_h
#define __vtkMrmlSegmenterAtlasClassNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMAtlasBrainClassifierConfigure.h>

// This is just the shell to archieve attributes that are holy to this verision 
class VTK_EMATLASBRAINCLASSIFIER_EXPORT vtkMrmlSegmenterAtlasClassNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterAtlasClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterAtlasClassNode,vtkMrmlNode);

  void PrintSelf(ostream& os,vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *anode);

  // Description:
  // Get/Set for SegmenterClass
  vtkGetMacro(Label, int);
  vtkSetMacro(Label, int);

  // Description:
  // Get/Set for SegmenterClass
  vtkSetStringMacro(LogMean);
  vtkGetStringMacro(LogMean);

  // Description:
  // Get/Set for SegmenterClass
  vtkSetStringMacro(LogCovariance);
  vtkGetStringMacro(LogCovariance);

  // Description:
  // Get/Set for SegmenterClass
  vtkSetStringMacro(ReferenceStandardFileName);
  vtkGetStringMacro(ReferenceStandardFileName);

  // Description:
  // Currenly only the following values defined 
  // 0 = Do not Print out any print quality 
  // 1 = Do a DICE comparison
  vtkSetMacro(PrintQuality,int);
  vtkGetMacro(PrintQuality,int);
  
protected:
  vtkMrmlSegmenterAtlasClassNode();
  ~vtkMrmlSegmenterAtlasClassNode();
  vtkMrmlSegmenterAtlasClassNode(const vtkMrmlSegmenterAtlasClassNode&) {};
  void operator=(const vtkMrmlSegmenterAtlasClassNode&) {};

  // I do not know how to better Identify my Images
  int    Label;

  char   *LogMean;
  char   *LogCovariance;
  float  LocalPriorWeight;

  char   *ReferenceStandardFileName;

  int    PrintQuality;        // Prints out a quality measure of the current result ( 1=  Dice )
};

#endif

/*

  // Description:
  // Get/Set for SegmenterClass
  vtkGetMacro(ShapeParameter, float);
  vtkSetMacro(ShapeParameter, float);


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

  float  ShapeParameter;
  char   *PCAMeanName;

  float PCALogisticSlope;
  float PCALogisticMin;
  float PCALogisticMax;
  float PCALogisticBoundary;
  int    PrintPCA;            // Print out PCA Parameters at each step 

 */
