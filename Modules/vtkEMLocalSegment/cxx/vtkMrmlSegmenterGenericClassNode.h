/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterGenericClassNode.h,v $
  Date:      $Date: 2007/03/06 22:41:46 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/
// .NAME vtkMrmlSegmenterClassNode - MRML node to represent transformation matrices.
// .SECTION Description
// The output of a rigid-body registration is a rotation and translation 
// expressed mathematically as a transformation matrix.  These transforms 
// can be inserted into MRML files as Segmenter nodes.  Each matrix 
// affects volumes and models that appear below it in the MRML file.  
// Multiple matrices can be concatenated together. 

#ifndef __vtkMrmlSegmenterGenericClassNode_h
#define __vtkMrmlSegmenterGenericClassNode_h

#include <vtkEMLocalSegmentConfigure.h>
#include "vtkMrmlSegmenterAtlasGenericClassNode.h"

// For the first stage super class is just a hirachical element, where we just define the name
// Extensions for later are planned
// Kilian 07-Oct-02

class VTK_EMLOCALSEGMENT_EXPORT vtkMrmlSegmenterGenericClassNode : public vtkMrmlSegmenterAtlasGenericClassNode
{
public:
  static vtkMrmlSegmenterGenericClassNode *New();
  vtkTypeMacro(vtkMrmlSegmenterGenericClassNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

  // Description:  
  // Translation from patient case to atlas space   
  vtkGetVector3Macro(RegistrationTranslation, double);
  vtkSetVector3Macro(RegistrationTranslation, double);

  // Description:
  // Rotation from patient case to atlas space   
  vtkGetVector3Macro(RegistrationRotation, double);
  vtkSetVector3Macro(RegistrationRotation, double);

  // Description:
  // Scale from patient case to atlas space   
  vtkGetVector3Macro(RegistrationScale, double);
  vtkSetVector3Macro(RegistrationScale, double);

  // Description:
  // Diagonal Covariance Matrix (describing the zero Mean Gaussian distribution of the class registration parameters 
  vtkGetVectorMacro(RegistrationCovariance,double,9); 
  vtkSetVectorMacro(RegistrationCovariance,double,9);

  // Description:
  // Prints out the registration parameters translation - rotation -scaling 
  vtkGetMacro(PrintRegistrationParameters, int);
  vtkSetMacro(PrintRegistrationParameters, int);

  // Description:
  // Prints out the registration cost at each voxel 
  vtkGetMacro(PrintRegistrationSimularityMeasure, int);
  vtkSetMacro(PrintRegistrationSimularityMeasure, int);
  
  // Description:
  // If the class specific registration is activated by the superclass should this structure be optimizaed or ignored !
  // By default it is ignored (set to 0)
  vtkGetMacro(RegistrationClassSpecificRegistrationFlag,int); 
  vtkSetMacro(RegistrationClassSpecificRegistrationFlag,int); 
  vtkBooleanMacro(RegistrationClassSpecificRegistrationFlag,int); 
  // Description:
  // If you eant to include a class just being set via its intensity value than set this flag
  vtkGetMacro(ExcludeFromIncompleteEStepFlag,int);
  vtkSetMacro(ExcludeFromIncompleteEStepFlag,int);
  vtkBooleanMacro(ExcludeFromIncompleteEStepFlag,int);

  vtkGetMacro(PCARegistrationFlag,int);
  vtkSetMacro(PCARegistrationFlag,int);

protected:
  vtkMrmlSegmenterGenericClassNode();
  ~vtkMrmlSegmenterGenericClassNode(){};

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of);

  int    PrintRegistrationParameters;
  int    PrintRegistrationSimularityMeasure;

  char   *LocalPriorName;

  double RegistrationTranslation[3];
  double RegistrationRotation[3];
  double RegistrationScale[3];
  double RegistrationCovariance[9];
  int    RegistrationClassSpecificRegistrationFlag; 
  int    ExcludeFromIncompleteEStepFlag;
  int    PCARegistrationFlag;

private:
  vtkMrmlSegmenterGenericClassNode(const vtkMrmlSegmenterGenericClassNode&);
  void operator=(const vtkMrmlSegmenterGenericClassNode&);
};

#endif

