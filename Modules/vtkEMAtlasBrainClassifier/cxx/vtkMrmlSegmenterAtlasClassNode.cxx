/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSegmenterAtlasClassNode.cxx,v $
  Date:      $Date: 2006/01/06 17:57:30 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlSegmenterAtlasClassNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlSegmenterAtlasClassNode* vtkMrmlSegmenterAtlasClassNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSegmenterAtlasClassNode");
  if(ret)
  {
    return (vtkMrmlSegmenterAtlasClassNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSegmenterAtlasClassNode;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasClassNode::vtkMrmlSegmenterAtlasClassNode()
{
  // vtkMrmlNode's attributes => Tabs following sub classes  
  this->Label            = 0;

  this->LogMean          = NULL;
  this->LogCovariance    = NULL;

  this->ReferenceStandardFileName     = NULL; 
  
  this->PrintQuality        = 0;
}

//----------------------------------------------------------------------------
vtkMrmlSegmenterAtlasClassNode::~vtkMrmlSegmenterAtlasClassNode()
{
  if (this->LogMean)
  {
    delete [] this->LogMean;
    this->LogMean = NULL;
  }
  if (this->LogCovariance)
  {
    delete [] this->LogCovariance;
    this->LogCovariance = NULL;
  }
  
   if (this->ReferenceStandardFileName)
  {
    delete [] this->ReferenceStandardFileName;
    this->ReferenceStandardFileName = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasClassNode::Write(ofstream& of)
{
  // Write all attributes not equal to their defaults
  
  of << " Label='" << this->Label << "'";

  if (this->LogMean && strcmp(this->LogMean, "")) 
  {
    of << " LogMean='" << this->LogMean << "'";
  }
  if (this->LogCovariance && strcmp(this->LogCovariance, "")) 
  {
    of << " LogCovariance='" << this->LogCovariance << "'";
  }

  if (this->ReferenceStandardFileName && strcmp(this->ReferenceStandardFileName, "")) 
  {
    of << " ReferenceStandardFileName='" << this->ReferenceStandardFileName << "'";
  }

  of << " PrintQuality='" << this->PrintQuality << "'";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, Name
void vtkMrmlSegmenterAtlasClassNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlSegmenterAtlasClassNode *node = (vtkMrmlSegmenterAtlasClassNode *) anode;
  this->SetLabel(node->Label);
  this->SetLogMean(node->LogMean);
  this->SetLogCovariance(node->LogCovariance);
  this->SetReferenceStandardFileName(node->ReferenceStandardFileName);

  this->SetPrintQuality(node->PrintQuality);
}

//----------------------------------------------------------------------------
void vtkMrmlSegmenterAtlasClassNode::PrintSelf(ostream& os, vtkIndent indent)
{
   os << indent << "Label: " << this->Label << "\n";
   os << indent << "LogMean: " <<
    (this->LogMean ? this->LogMean : "(none)") << "\n";
   os << indent << "LogCovariance: " <<
    (this->LogCovariance ? this->LogCovariance : "(none)") << "\n";

   os << indent << "ReferenceStandardFileName: " <<  (this->ReferenceStandardFileName ? this->ReferenceStandardFileName : "(none)") << "\n"; 
   os << indent << "PrintQuality:              " << this->PrintQuality << "\n";
}
/*
  this->Indent     = 1;
  this->ShapeParameter   = 0.0;
  this->PCAMeanName      = NULL; 

  this->PCALogisticSlope = 1.0;
  this->PCALogisticMin   = 0.0;
  this->PCALogisticMax   = 20.0;
  this->PCALogisticBoundary = 9.5;

  this->PrintPCA            = 0;

 if (this->PCAMeanName)
  {
    delete [] this->PCAMeanName;
    this->PCAMeanName = NULL;
  }

  vtkIndent i1(nIndent);

  of << i1 << "<SegmenterClass";
  if (this->Name && strcmp(this->Name, ""))  {
    of << " name ='" << this->Name << "'";
  }

  this->vtkMrmlSegmenterGenericClassNode::Write(of);
  of << " ShapeParameter='" << this->ShapeParameter << "'";

  if (this->PCAMeanName && strcmp( this->PCAMeanName, "")) 
  {
    of << " PCAMeanName='" << this->PCAMeanName << "'";
  }

  of << " PCALogisticSlope ='" << this->PCALogisticSlope << "'"; 
  of << " PCALogisticMin ='" << this->PCALogisticMin << "'"; 
  of << " PCALogisticMax ='" << this->PCALogisticMax << "'"; 
  of << " PCALogisticBoundary ='" << this->PCALogisticBoundary << "'"; 
  of << " PrintPCA='" << this->PrintPCA << "'";
  of << ">\n";

  
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlSegmenterAtlasGenericClassNode::Copy(anode);

  this->SetShapeParameter(node->ShapeParameter);
  this->SetPCAMeanName(node->PCAMeanName);

  this->SetPCALogisticSlope(node->PCALogisticSlope);
  this->SetPCALogisticMin(node->PCALogisticMin);
  this->SetPCALogisticMax(node->PCALogisticMax);
  this->SetPCALogisticBoundary(node->PCALogisticBoundary);

  this->SetPrintPCA(node->PrintPCA);

  vtkMrmlNode::PrintSelf(os,indent);

   os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  this->vtkMrmlSegmenterAtlasGenericClassNode::PrintSelf(os, indent);
  os << indent << "ShapeParameter: " << this->ShapeParameter << "\n";

  os << indent << "PCAMeanName:               " <<  (this->PCAMeanName ? this->PCAMeanName : "(none)") << "\n"; 
  os << indent << "PCALogisticSlope:          " << this->PCALogisticSlope << "\n"; 
  os << indent << "PCALogisticMin:            " << this->PCALogisticMin << "\n"; 
  os << indent << "PCALogisticMax:            " << this->PCALogisticMax << "\n"; 
  os << indent << "PCALogisticBoundary:       " << this->PCALogisticBoundary << "\n"; 
   os << indent << "PrintPCA:                  " << this->PrintPCA << "\n";



 */
