/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterClassNode.cxx,v $
  Date:      $Date: 2007/03/14 01:45:15 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterClassNode* vtkMrmlSegmenterClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterClassNode");
  if(ret)
  {
    return (vtkMrmlSegmenterClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterClassNode::vtkMrmlSegmenterClassNode()
{
  // vtkMrmlNode's attributes => Tabs following sub classes  
  this->Indent     = 1;
  this->FixedWeightsName = NULL;
  this->PCAMeanName      = NULL; 
  this->PCALogisticSlope = 1.0;
  this->PCALogisticMin   = 0.0;
  this->PCALogisticMax   = 20.0;
  this->PCALogisticBoundary = 9.5;
  this->PrintPCA            = 0;

  this->SamplingLogMean          = NULL;
  this->SamplingLogCovariance    = NULL;

  this->AtlasClassNode = vtkMrmlSegmenterAtlasClassNode::New();

}

//----------------------------------------------------------------------------
vtkMrmlSegmenterClassNode::~vtkMrmlSegmenterClassNode()
{
  if (this->FixedWeightsName) {
    delete[] this->FixedWeightsName;
    this->FixedWeightsName = NULL;
  }
  if (this->PCAMeanName)
  {
    delete [] this->PCAMeanName;
    this->PCAMeanName = NULL;
  }
 
  if (this->SamplingLogMean)
  {
    delete [] this->SamplingLogMean;
    this->SamplingLogMean = NULL;
  }
  if (this->SamplingLogCovariance)
  {
    delete [] this->SamplingLogCovariance;
    this->SamplingLogCovariance = NULL;
  }

  this->AtlasClassNode->Delete();
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterClassNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterClass";
  this->vtkMrmlSegmenterGenericClassNode::Write(of);
  this->AtlasClassNode->Write(of);

  if (this->FixedWeightsName && strcmp(this->FixedWeightsName, "")) {
    of << " FixedWeightsName ='"<< this->FixedWeightsName << "'";
  }

  if (this->PCAMeanName && strcmp( this->PCAMeanName, "")) 
  {
    of << " PCAMeanName='" << this->PCAMeanName << "'";
  }

  of << " PCALogisticSlope ='" << this->PCALogisticSlope << "'"; 
  of << " PCALogisticMin ='" << this->PCALogisticMin << "'"; 
  of << " PCALogisticMax ='" << this->PCALogisticMax << "'"; 
  of << " PCALogisticBoundary ='" << this->PCALogisticBoundary << "'"; 
  of << " PrintPCA='" << this->PrintPCA << "'";

  if (this->SamplingLogMean && strcmp(this->SamplingLogMean, "")) of << " SamplingLogMean='" << this->SamplingLogMean << "'";
  if (this->SamplingLogCovariance && strcmp(this->SamplingLogCovariance, ""))  of << " SamplingLogCovariance='" << this->SamplingLogCovariance << "'";

  of << ">\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterClassNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterGenericClassNode::Copy(anode);
  vtkMrmlSegmenterClassNode *node = (vtkMrmlSegmenterClassNode *) anode;

  this->AtlasClassNode->Copy(node->AtlasClassNode);
  this->SetFixedWeightsName(node->FixedWeightsName);
  this->SetPCAMeanName(node->PCAMeanName);
  this->SetPCALogisticSlope(node->PCALogisticSlope);
  this->SetPCALogisticMin(node->PCALogisticMin);
  this->SetPCALogisticMax(node->PCALogisticMax);
  this->SetPCALogisticBoundary(node->PCALogisticBoundary);
  this->SetPrintPCA(node->PrintPCA);

  this->SetSamplingLogMean(node->SamplingLogMean);
  this->SetSamplingLogCovariance(node->SamplingLogCovariance);

}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
   this->vtkMrmlSegmenterGenericClassNode::PrintSelf(os, indent);
   this->AtlasClassNode->PrintSelf(os,indent);
   os << indent << "FixedWeightsName:          " << (this->FixedWeightsName ? this->FixedWeightsName : "(none)") << "\n";  
   os << indent << "PCAMeanName:               " <<  (this->PCAMeanName ? this->PCAMeanName : "(none)") << "\n"; 
   os << indent << "PrintPCA:                  " << this->PrintPCA << "\n";
   os << indent << "PCALogisticSlope:          " << this->PCALogisticSlope << "\n"; 
   os << indent << "PCALogisticMin:            " << this->PCALogisticMin << "\n"; 
   os << indent << "PCALogisticMax:            " << this->PCALogisticMax << "\n"; 
   os << indent << "PCALogisticBoundary:       " << this->PCALogisticBoundary << "\n"; 
   os << indent << "SamplingLogMean:           " << (this->SamplingLogMean ? this->SamplingLogMean : "(none)") << "\n";
   os << indent << "SamplingLogCovariance:     " << (this->SamplingLogCovariance ? this->SamplingLogCovariance : "(none)") << "\n";
}
