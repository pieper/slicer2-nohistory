/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelNode.cxx,v $
  Date:      $Date: 2006/03/08 14:54:58 $
  Version:   $Revision: 1.23 $

=========================================================================auto=*/
#include "vtkMrmlModelNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlModelNode* vtkMrmlModelNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlModelNode");
  if(ret)
  {
    return (vtkMrmlModelNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlModelNode;
}

//----------------------------------------------------------------------------
vtkMrmlModelNode::vtkMrmlModelNode()
{
  // Strings
  this->ModelID = NULL;
  this->FileName = NULL;
  this->Color = NULL;
  this->FullFileName = NULL;

  // Numbers
  this->Opacity = 1.0;
  this->Visibility = 1;
  this->Clipping = 0;
  this->BackfaceCulling = 1;
  this->ScalarVisibility = 0;
  this->VectorVisibility = 0;
  this->TensorVisibility = 0;
  
  // Arrays
  this->ScalarRange[0] = 0;
  this->ScalarRange[1] = 100;

  this->RasToWld = vtkMatrix4x4::New();

  // Scalars
  this->LUTName = -1;
  this->ScalarFileNamesVec.clear();
  
}

//----------------------------------------------------------------------------
vtkMrmlModelNode::~vtkMrmlModelNode()
{
  this->RasToWld->Delete();

  if (this->ModelID)
    {
    delete [] this->ModelID;
    this->ModelID = NULL;
    }
  if (this->FileName)
    {
    delete [] this->FileName;
    this->FileName = NULL;
    }
  if (this->FullFileName)
    {
    delete [] this->FullFileName;
    this->FullFileName = NULL;
    }
  if (this->Color)
    {
    delete [] this->Color;
    this->Color = NULL;
    }
}

//----------------------------------------------------------------------------
void vtkMrmlModelNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  
  vtkIndent i1(nIndent);

  of << i1 << "<Model";

  // Strings
  if (this->ModelID && strcmp(this->ModelID, ""))
  {
    of << " id='" << this->ModelID << "'";
  }
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->FileName && strcmp(this->FileName, "")) 
  {
    of << " fileName='" << this->FileName << "'";
  }
  if (this->Color && strcmp(this->Color, "")) 
  {
    of << " color='" << this->Color << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }

  //if (this->LUTName && strcmp(this->LUTName,""))
  if (this->LUTName != -1)
  {
      of << " lutName='" << this->LUTName << "'";
  }
  
  // Numbers
  if (this->Opacity != 1.0)
  {
    of << " opacity='" << this->Opacity << "'";
  }
  if (this->Visibility != 1)
  {
    of << " visibility='" << (this->Visibility ? "true" : "false") << "'";
  }
  if (this->Clipping != 0)
  {
    of << " clipping='" << (this->Clipping ? "true" : "false") << "'";
  }
  if (this->BackfaceCulling != 1)
  {
    of << " backfaceCulling='" << (this->BackfaceCulling ? "true" : "false") << "'";
  }
  if (this->ScalarVisibility != 0)
  {
    of << " scalarVisibility='" << (this->ScalarVisibility ? "true" : "false") << "'";
  }

  // Arrays
  if (this->ScalarRange[0] != 0 || this->ScalarRange[1] != 100)
  {
    of << " scalarRange='" << this->ScalarRange[0] << " "
       << this->ScalarRange[1] << "'";
  }

  // Scalars
  if (this->ScalarFileNamesVec.size() > 0)
  {
      of << " scalarFiles='";
      for (unsigned int idx = 0; idx < this->ScalarFileNamesVec.size(); idx++)
      {
          of << this->GetScalarFileName(idx);
          if (idx+1 < this->ScalarFileNamesVec.size())
          {
              of << " ";
          }
      }
      of << "'";
  }
  of << "></Model>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name, ModelID
void vtkMrmlModelNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlModelNode *node = (vtkMrmlModelNode *) anode;

  // Strings
  this->SetFileName(node->FileName);
  this->SetFullFileName(node->FullFileName);
  this->SetColor(node->Color);

  // Vectors
  this->SetScalarRange(node->ScalarRange);
  
  // Numbers
  this->SetOpacity(node->Opacity);
  this->SetVisibility(node->Visibility);
  this->SetScalarVisibility(node->ScalarVisibility);
  this->SetBackfaceCulling(node->BackfaceCulling);
  this->SetClipping(node->Clipping);

  // Matrices
  this->SetRasToWld(node->RasToWld);

  // Scalars

}

//----------------------------------------------------------------------------
void vtkMrmlModelNode::SetRasToWld(vtkMatrix4x4 *rasToWld)
{
  this->RasToWld->DeepCopy(rasToWld);
}

//----------------------------------------------------------------------------
void vtkMrmlModelNode::PrintSelf(ostream& os, vtkIndent indent)
{
  int idx;
  
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "ModelID: " <<
    (this->ModelID ? this->ModelID : "(none)") << "\n";
  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";
  os << indent << "FileName: " <<
    (this->FileName ? this->FileName : "(none)") << "\n";
  os << indent << "FullFileName: " <<
    (this->FullFileName ? this->FullFileName : "(none)") << "\n";
  os << indent << "Color: " <<
    (this->Color ? this->Color : "(none)") << "\n";

  os << indent << "Opacity:           " << this->Opacity << "\n";
  os << indent << "Visibility:        " << this->Visibility << "\n";
  os << indent << "ScalarVisibility:  " << this->ScalarVisibility << "\n";
  os << indent << "BackfaceCulling:   " << this->BackfaceCulling << "\n";
  os << indent << "Clipping:          " << this->Clipping << "\n";

  os << "ScalarRange:\n";
  for (idx = 0; idx < 2; ++idx)
    {
    os << indent << ", " << this->ScalarRange[idx];
    }
  os << ")\n";

  // Matrices
  os << indent << "RasToWld:\n";

  this->RasToWld->PrintSelf(os, indent.GetNextIndent());

  os << indent << "Look up table ID: " << this->LUTName << endl;

  // Scalars
  os << indent << "Number of scalar file names: " << this->ScalarFileNamesVec.size() << endl;
  if (this->ScalarFileNamesVec.size() > 0)
    {
    for (unsigned int i = 0; i < this->ScalarFileNamesVec.size(); i++)
      {
      os << indent << indent << "Scalar File " << i << ": " 
        << this->ScalarFileNamesVec[i].c_str() << endl;
      }
    }
}

//----------------------------------------------------------------------------
int vtkMrmlModelNode::GetNumberOfScalarFileNames ()
{
    return this->ScalarFileNamesVec.size();
}

//----------------------------------------------------------------------------
void vtkMrmlModelNode::AddScalarFileName(const char *newFileName)
{
  unsigned int i;
  int found = 0;
  vtkstd::string val = newFileName;
  // check that it's not there already
  for (i=0; i<this->ScalarFileNamesVec.size(); i++)
    {
    // Do string comparison and not cstring
    if (this->ScalarFileNamesVec[i] == val)
      {
      found++;
      break; // do not need to go any further
      }
    }
  if (found == 0)
    {
    this->ScalarFileNamesVec.push_back(val);
    vtkDebugMacro(<<"Added scalar file " << newFileName);
    }
  else
    {
    vtkDebugMacro(<<"Didn't add scalar file name, found in list already: " << newFileName);
    }

}

//----------------------------------------------------------------------------
const char *vtkMrmlModelNode::GetScalarFileName(int idx)
{
  return this->ScalarFileNamesVec[idx].c_str();
}

//----------------------------------------------------------------------------
void vtkMrmlModelNode::DeleteScalarFileNames()
{
  this->ScalarFileNamesVec.clear();
}

