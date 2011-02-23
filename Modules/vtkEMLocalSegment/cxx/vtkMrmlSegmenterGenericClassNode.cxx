/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterGenericClassNode.cxx,v $
  Date:      $Date: 2007/03/06 22:41:45 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterGenericClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterGenericClassNode* vtkMrmlSegmenterGenericClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterGenericClassNode");
  if(ret)
  {
    return (vtkMrmlSegmenterGenericClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterGenericClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterGenericClassNode::vtkMrmlSegmenterGenericClassNode() { 
  // vtkMrmlNode's attributes => Tabs following sub classes  

  this->PrintRegistrationParameters = 0;
  this->PrintRegistrationSimularityMeasure = 0;

  memset(this->RegistrationTranslation,0,3*sizeof(double));
  memset(this->RegistrationRotation,0,3*sizeof(double));
  int i;
  for (i = 0; i < 3; i++) RegistrationScale[i]= 1.0;
  for (i = 0; i < 6; i++) this->RegistrationCovariance[i] = 1.0;
  this->RegistrationCovariance[6] = this->RegistrationCovariance[7] = this->RegistrationCovariance[8] = 0.1;

  this->RegistrationClassSpecificRegistrationFlag = 0;
  this->ExcludeFromIncompleteEStepFlag = 0;
 
  this->PCARegistrationFlag = 0;

}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterGenericClassNode::Write(ofstream& of)
{
  // Write all attributes not equal to their defaults
  vtkMrmlSegmenterAtlasGenericClassNode::Write(of);

  if (this->PrintRegistrationParameters) of << " PrintRegistrationParameters='" << this->PrintRegistrationParameters << "'";
  if (this->PrintRegistrationSimularityMeasure) of << " PrintRegistrationSimularityMeasure='" << this->PrintRegistrationSimularityMeasure << "'";

  if  (this->RegistrationTranslation[0] || this->RegistrationTranslation[1] || this->RegistrationTranslation[2]) 
    of << " RegistrationTranslation='" << this->RegistrationTranslation[0] << " " << this->RegistrationTranslation[1] << " " << this->RegistrationTranslation[2] << "'";
  if  (this->RegistrationRotation[0] || this->RegistrationRotation[1] || this->RegistrationRotation[2]) 
    of << " RegistrationRotation='" << this->RegistrationRotation[0] << " " << this->RegistrationRotation[1] << " " << this->RegistrationRotation[2] << "'";
  if  ((this->RegistrationScale[0] != 1) || (this->RegistrationScale[1] != 1) || (this->RegistrationScale[2] != 1)) 
    of << " RegistrationScale='" << this->RegistrationScale[0] << " " << this->RegistrationScale[1] << " " << this->RegistrationScale[2] << "'";

  of << " RegistrationCovariance='";
  for(int i=0; i < 9; i++)  of << this->RegistrationCovariance[i] << " ";
  of << "'"; 
  if (this->RegistrationClassSpecificRegistrationFlag) of << " RegistrationClassSpecificRegistrationFlag='" << this->RegistrationClassSpecificRegistrationFlag << "'";
  if (this->ExcludeFromIncompleteEStepFlag) of << " ExcludeFromIncompleteEStepFlag='" << this->ExcludeFromIncompleteEStepFlag << "'";
  if (this->PCARegistrationFlag) of << " PCARegistrationFlag='" << this->PCARegistrationFlag << "'";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterGenericClassNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterAtlasGenericClassNode::Copy(anode);
  vtkMrmlSegmenterGenericClassNode *node = (vtkMrmlSegmenterGenericClassNode *) anode;

  this->PrintRegistrationParameters   = node->PrintRegistrationParameters;
  this->PrintRegistrationSimularityMeasure         = node->PrintRegistrationSimularityMeasure;
  this->RegistrationClassSpecificRegistrationFlag = node->RegistrationClassSpecificRegistrationFlag;
  this->ExcludeFromIncompleteEStepFlag = node->ExcludeFromIncompleteEStepFlag;
  this->PCARegistrationFlag = node->PCARegistrationFlag;
 
  memcpy(this->RegistrationTranslation,node->RegistrationTranslation,3*sizeof(double));
  memcpy(this->RegistrationRotation, node->RegistrationRotation,3*sizeof(double));
  memcpy(this->RegistrationScale,node->RegistrationScale,3*sizeof(double));
  memcpy(this->RegistrationCovariance,node->RegistrationCovariance,9*sizeof(double));

}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterGenericClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkMrmlSegmenterAtlasGenericClassNode::PrintSelf(os,indent);
  os << indent << "PrintRegistrationParameters:        " << this->PrintRegistrationParameters << "\n";
  os << indent << "PrintRegistrationSimularityMeasure: " << this->PrintRegistrationSimularityMeasure << "\n";
  os << indent << "RegistrationTranslation:            " << this->RegistrationTranslation[0] << ", " << this->RegistrationTranslation[1] << ", " << this->RegistrationTranslation[2] << "\n" ;
  os << indent << "RegistrationRotation:               " << this->RegistrationRotation[0] << ", " << this->RegistrationRotation[1] << ", " << this->RegistrationRotation[2] << "\n" ;
  os << indent << "RegistrationScale:                  " << this->RegistrationScale[0] << ", " << this->RegistrationScale[1] << ", " << this->RegistrationScale[2] << "\n" ;
  os << indent << "RegistrationCovariance:             " ;
  for (int i = 0 ; i < 9 ; i++)  os << RegistrationCovariance[i] << " "; 
  os << "\n" ;
  os << indent << "RegistrationClassSpecificRegistrationFlag: " << this->RegistrationClassSpecificRegistrationFlag << "\n" ;
  os << indent << "ExcludeFromIncompleteEStepFlag:     " << this->ExcludeFromIncompleteEStepFlag << "\n" ;
  os << indent << "PCARegistrationFlag:                " << this->PCARegistrationFlag << "\n" ; 
}
