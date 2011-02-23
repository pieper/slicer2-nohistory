/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasNode.h,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterAtlasNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterAtlasNode_h
#define __vtkMrmlSegmenterAtlasNode_h

#include "vtkMrmlNode.h"
#include "vtkSlicer.h"
#include <vtkEMAtlasBrainClassifierConfigure.h>

class VTK_EMATLASBRAINCLASSIFIER_EXPORT vtkMrmlSegmenterAtlasNode : public vtkMrmlNode
{
public:
  static vtkMrmlSegmenterAtlasNode *New();
  vtkTypeMacro(vtkMrmlSegmenterAtlasNode,vtkMrmlNode);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(AlreadyRead, int);
  vtkGetMacro(AlreadyRead, int);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(MaxInputChannelDef, int);
  vtkGetMacro(MaxInputChannelDef, int);

  // Description:
  // Get/Set for Segmenter
  void SetEMiteration(int init) {
    // the public version still works that way  - later do it 
    //vtkWarningMacro(<<"You have an older XML Version for EMSegmenter - EMiteration is not defined anymore as part of vtMRMLSegmenterNode"<< endl 
    //                <<"We still read in values but update your XML File to new structure to erase this error message" );
    this->EMiteration  = init;
  }

  vtkGetMacro(EMiteration, int);

  // Description:
  // Get/Set for Segmenter
  void SetMFAiteration(int init) {
    // the public version still works that way  -later uncomment it 
    //vtkWarningMacro(<<"You have an older XML Version for EMSegmenter - MFAiteration is not defined anymore as part of vtMRMLSegmenterNode"<< endl 
    //                <<"We still read in values but update your XML File to new structure to erase this error message" );
    this->MFAiteration  = init;
  }
  vtkGetMacro(MFAiteration, int);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(Alpha, double);
  vtkGetMacro(Alpha, double);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(SmWidth, int);
  vtkGetMacro(SmWidth, int);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(SmSigma, int);
  vtkGetMacro(SmSigma, int);

  // Description:
  // Replacement for Start - EndSlice Bounding Box can be 3D
  vtkSetVector3Macro(SegmentationBoundaryMin, int);
  vtkGetVector3Macro(SegmentationBoundaryMin,int);

  vtkSetVector3Macro(SegmentationBoundaryMax,int);
  vtkGetVector3Macro(SegmentationBoundaryMax,int);

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(NumberOfTrainingSamples, int);
  vtkGetMacro(NumberOfTrainingSamples, int);

  // Description:
  // The work directory for this segmentation 
  // Necessarry for EM to spid out intermediate results 
  // it will generate the necessary subdirectories from here 
  // e.g. weights 
  vtkGetStringMacro(PrintDir);
  vtkSetStringMacro(PrintDir);


  // Legacy Variables : 
  // The tree is a 1D list of nodes, it does not know anything about hireachies 
  //  => Never delete variables from vtkMrml..Node.h if for some XML files you use them 
  // and you cannot update them easily in LoadMRML

  // Description:
  // Get/Set for Segmenter
  void SetNumClasses(int init) {
    vtkWarningMacro(<<"You have an older XML Version for EMSegmenter - NumClasses is not defined anymore as part of vtMRMLSegmenterNode"<< endl 
                    <<"We still read in values but update your XML File to new structure to erase this error message" );
    this->NumClasses  = init;
  }
  vtkGetMacro(NumClasses, int);

protected:
  vtkMrmlSegmenterAtlasNode();
  ~vtkMrmlSegmenterAtlasNode();
  vtkMrmlSegmenterAtlasNode(const vtkMrmlSegmenterAtlasNode&) {};
  void operator=(const vtkMrmlSegmenterAtlasNode&) {};

  void PrintSelf(ostream& os,vtkIndent indent);
  
  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  int    AlreadyRead; 
  int    MaxInputChannelDef;
  int    EMiteration;
  int    MFAiteration;
  double Alpha;
  int    SmWidth;
  int    SmSigma;
  int    NumberOfTrainingSamples;
  char*  PrintDir;
  int    SegmentationBoundaryMin[3];
  int    SegmentationBoundaryMax[3];

  // These are legacy definitions - we leave them in so we keep compatibility with older versions
  int    NumClasses; //  From July 04 the HeadClass will be defined seperatly from SegmenterNode so that there is no overlap anymore between SuperClassNode and SegmenterNode

};

#endif

/*

  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(DisplayProb, int);
  vtkGetMacro(DisplayProb, int);
 
  // Description:
  // Get/Set for Segmenter
  // vtkSetMacro(IntensityAvgClass, int);
  // vtkGetMacro(IntensityAvgClass, int);

  // Should be deleted 
  // Description:
  // Get/Set for Segmenter
  vtkSetMacro(EMShapeIter, int);
  vtkGetMacro(EMShapeIter, int);

  // Description:
  // Define what kind of interpolation you want for the registration function - 
  // 1 = Linear Affine Registration 
  // 2 = Nearest Neighbour Affine Registration
   vtkSetMacro(RegistrationInterpolationType, int);
   vtkGetMacro(RegistrationInterpolationType, int);

  int    DisplayProb;  // Should the probability displayed in the graph - left it in bc it is more work to take it out - should not be defined here but in GraphNode 
  int    EMShapeIter;
  int    RegistrationInterpolationType;
  int    IntensityAvgClass;

*/
