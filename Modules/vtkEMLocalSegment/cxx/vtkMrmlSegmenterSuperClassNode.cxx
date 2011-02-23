/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterSuperClassNode.cxx,v $
  Date:      $Date: 2007/03/14 02:01:27 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/
//#include <stdio.h>
//#include <ctype.h>
//#include <string.h>
//#include <math.h>
#include "vtkMrmlSegmenterSuperClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterSuperClassNode* vtkMrmlSegmenterSuperClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterSuperClassNode");
  if(ret)
  {
    return (vtkMrmlSegmenterSuperClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterSuperClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterSuperClassNode::vtkMrmlSegmenterSuperClassNode() { 
  // vtkMrmlNode's attributes => Tabs following sub classes  
  this->Indent     = 1;

  this->PrintEMLabelMapConvergence  = 0;
  this->PrintEMWeightsConvergence = 0;
  this->PrintShapeSimularityMeasure = 0;
  this->PrintMFALabelMapConvergence  = 0;
  this->PrintMFAWeightsConvergence = 0;

  this->StopBiasCalculation = -1;
  this->RegistrationType    = 0;
  this->GenerateBackgroundProbability = 0;
  this->PCAShapeModelType = 0;
  this->RegistrationIndependentSubClassFlag = 0;
  this->AtlasNode = vtkMrmlSegmenterAtlasSuperClassNode::New();

  this->ParameterInitSubClass =  0;
  this->ParameterSaveToFile   =  0;
  this->ParameterSetFromFile  =  0;

  this->PredefinedLabelID = -1;

  this->PCARegistrationNumOfPCAParameters = -1;
  this->PCARegistrationVectorDimension = -1;
  this->PCARegistrationMean = NULL;
  this->PCARegistrationEigenMatrix = NULL; 
  this->PCARegistrationEigenValues = NULL;

  this->InhomogeneityInitialDataNames = NULL;

}

vtkMrmlSegmenterSuperClassNode::~vtkMrmlSegmenterSuperClassNode() {
  this->AtlasNode->Delete();
  if (this->PCARegistrationMean) {
    delete[] this->PCARegistrationMean;
    this->PCARegistrationMean = NULL;
  }

  if (this->PCARegistrationEigenMatrix) {
    delete[] this->PCARegistrationEigenMatrix;
    this->PCARegistrationEigenMatrix = NULL; 
  }
  if (this->PCARegistrationEigenValues) {
    delete[] this->PCARegistrationEigenValues;
    this->PCARegistrationEigenValues = NULL;
  }

  if (this->InhomogeneityInitialDataNames) {
    delete[] InhomogeneityInitialDataNames;
    this->InhomogeneityInitialDataNames = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterSuperClassNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their default
  vtkIndent i1(nIndent);
  of << i1 << "<SegmenterSuperClass";
  this->vtkMrmlSegmenterGenericClassNode::Write(of);
  this->AtlasNode->Write(of);

  if (this->PrintEMLabelMapConvergence)  of << " PrintEMLabelMapConvergence='" << this->PrintEMLabelMapConvergence <<  "'";
  if (this->PrintEMWeightsConvergence)   of << " PrintEMWeightsConvergence='" << this->PrintEMWeightsConvergence  <<  "'";
  if (this->PrintMFALabelMapConvergence) of << " PrintMFALabelMapConvergence='" << this->PrintMFALabelMapConvergence <<  "'";
  if (this->PrintMFAWeightsConvergence)   of << " PrintMFAWeightsConvergence='" << this->PrintMFAWeightsConvergence  <<  "'";

  if (this->RegistrationType)                    of << " RegistrationType='" << this->RegistrationType << "' ";
  if (this->StopBiasCalculation > -1)            of << " StopStopBiasCalculation='" << this->StopBiasCalculation <<  "'";
  if (this->GenerateBackgroundProbability)       of << " GenerateBackgroundProbability='" << this->GenerateBackgroundProbability <<  "'";
  if (this->PrintShapeSimularityMeasure)          of << " PrintShapeSimularityMeasure='" << this->PrintShapeSimularityMeasure << "'";
  if (this->PCAShapeModelType)                   of << " PCAShapeModelType='" << this->PCAShapeModelType << "'";
  if (this->RegistrationIndependentSubClassFlag) of << " RegistrationIndependentSubClassFlag='" << this->RegistrationIndependentSubClassFlag << "'";
  if (this->PredefinedLabelID > -1) of << " PredefinedLabelID ='" << this->PredefinedLabelID << "'";
  if (this->ParameterInitSubClass)  of << " ParameterInitSubClass='"<< this->ParameterInitSubClass << "'";
  if (this->ParameterSaveToFile)    of << " ParameterSaveToFile='"<< this->ParameterSaveToFile << "'";
  if (this->ParameterSetFromFile)   of << " ParameterSetFromFile='"<< this->ParameterSetFromFile << "'";

  if (this->PCARegistrationNumOfPCAParameters > 0) of << " PCARegistrationNumOfPCAParameters ='" << this->PCARegistrationNumOfPCAParameters << "'";
  if (this->PCARegistrationVectorDimension > 0) of << " PCARegistrationVectorDimension ='" << this->PCARegistrationVectorDimension << "'";
  if (this->PCARegistrationMean        && strcmp(this->PCARegistrationMean, "")) of << " PCARegistrationMean ='" << this->PCARegistrationMean << "'";
  if (this->PCARegistrationEigenMatrix && strcmp(this->PCARegistrationEigenMatrix, "")) of << " PCARegistrationEigenMatrix ='" << this->PCARegistrationEigenMatrix << "'";
  if (this->PCARegistrationEigenValues && strcmp(this->PCARegistrationEigenValues, "")) of << " PCARegistrationEigenValues ='" << this->PCARegistrationEigenValues << "'";
 
  if (this->InhomogeneityInitialDataNames &&  strcmp(this->InhomogeneityInitialDataNames, "")) of << " InhomogeneityInitialDataNames ='" << this->InhomogeneityInitialDataNames << "'";
  of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterSuperClassNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterGenericClassNode::Copy(anode);
  vtkMrmlSegmenterSuperClassNode *node = (vtkMrmlSegmenterSuperClassNode *) anode;
  this->AtlasNode->Copy(node);

  this->PrintEMLabelMapConvergence    = node->PrintEMLabelMapConvergence;
  this->PrintEMWeightsConvergence     = node->PrintEMWeightsConvergence;
  this->PrintMFALabelMapConvergence   = node->PrintMFALabelMapConvergence;
  this->PrintMFAWeightsConvergence    = node->PrintMFAWeightsConvergence;

  this->StopBiasCalculation   = node->StopBiasCalculation;
  this->RegistrationType              = node->RegistrationType;
  this->GenerateBackgroundProbability = node->GenerateBackgroundProbability;
  this->PrintShapeSimularityMeasure   = node->PrintShapeSimularityMeasure;
  this->PCAShapeModelType             = node->PCAShapeModelType;
  this->RegistrationIndependentSubClassFlag = node->RegistrationIndependentSubClassFlag;
  this->PredefinedLabelID             = node->PredefinedLabelID;
  this->ParameterInitSubClass         = node->ParameterInitSubClass;
  this->ParameterSaveToFile           = node->ParameterSaveToFile;
  this->ParameterSetFromFile          = node->ParameterSetFromFile;

  this->PCARegistrationNumOfPCAParameters = node->PCARegistrationNumOfPCAParameters;
  this->PCARegistrationVectorDimension    = node->PCARegistrationVectorDimension;
  this->SetPCARegistrationMean(node->PCARegistrationMean);
  this->SetPCARegistrationEigenMatrix(node->PCARegistrationEigenMatrix); 
  this->SetPCARegistrationEigenValues(node->PCARegistrationEigenValues);
  this->SetInhomogeneityInitialDataNames(node->InhomogeneityInitialDataNames);
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterSuperClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkMrmlSegmenterGenericClassNode::PrintSelf(os, indent);
  this->AtlasNode->PrintSelf(os,indent);
  os << indent << "RegistrationType:              " << this->RegistrationType<< "\n" ;
  os << indent << "PrintEMLabelMapConvergence:    " << this->PrintEMLabelMapConvergence << "\n";
  os << indent << "PrintEMWeightsConvergence:     " << this->PrintEMWeightsConvergence << "\n";

  os << indent << "PrintMFALabelMapConvergence:   " << this->PrintMFALabelMapConvergence << "\n";
  os << indent << "PrintMFAWeightsConvergence:    " << this->PrintMFAWeightsConvergence << "\n";
  os << indent << "StopBiasCalculation:           " << this->StopBiasCalculation << "\n";

  os << indent << "GenerateBackgroundProbability: " << this->GenerateBackgroundProbability << "\n";
  os << indent << "PrintShapeSimularityMeasure:   " << this->PrintShapeSimularityMeasure << "\n";
  os << indent << "PCAShapeModelType:             " << this->PCAShapeModelType << "\n";
  os << indent << "RegistrationIndependentSubClassFlag: " << this->RegistrationIndependentSubClassFlag << "\n";
  os << indent << "PredefinedLabelID:             " << this->PredefinedLabelID << "\n";
  os << indent << "ParameterInitSubClass:         " << this->ParameterInitSubClass << "\n";
  os << indent << "ParameterSaveToFile:           " << this->ParameterSaveToFile << "\n";
  os << indent << "ParameterSetFromFile:          " << this->ParameterSetFromFile << "\n";

  os << indent << "PCARegistrationNumOfPCAParameters: " << this->PCARegistrationNumOfPCAParameters << "\n";
  os << indent << "PCARegistrationVectorDimension:    " << this->PCARegistrationVectorDimension << "\n";
  os << indent << "PCARegistrationMean:               " << (this->PCARegistrationMean ? this->PCARegistrationMean : "(none)" ) << "\n";
  os << indent << "PCARegistrationEigenMatrix:        " << (this->PCARegistrationEigenMatrix ? this->PCARegistrationEigenMatrix :"(none)" ) << "\n";
  os << indent << "PCARegistrationEigenValues:        " << (this->PCARegistrationEigenValues ? this->PCARegistrationEigenValues : "(none)" ) << "\n";
  os << indent << "InhomogeneityInitialDataNames:     " << (this->InhomogeneityInitialDataNames ? this->InhomogeneityInitialDataNames : "(none)") << "\n";
}
