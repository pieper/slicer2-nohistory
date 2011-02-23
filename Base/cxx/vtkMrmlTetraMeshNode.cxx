/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlTetraMeshNode.cxx,v $
  Date:      $Date: 2006/01/06 17:56:49 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlTetraMeshNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlTetraMeshNode* vtkMrmlTetraMeshNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlTetraMeshNode");
  if(ret)
  {
    return (vtkMrmlTetraMeshNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlTetraMeshNode;
}

//----------------------------------------------------------------------------
vtkMrmlTetraMeshNode::vtkMrmlTetraMeshNode()
{
  // Strings
  this->TetraMeshID = NULL;
  this->FileName = NULL;

  // DisplayTypes
  this->Clipping = 0;
  this->Opacity  = 1.0;

  // Defaults are don't display anything
  this->DisplaySurfaces = 0;
    this->SurfacesUseCellData = 1; // default, use cell data
    this->SurfacesSmoothNormals = 0; // default, don't smooth normals
  this->DisplayEdges    = 0;
  this->DisplayNodes    = 0;
    this->NodeScaling     = 9.5;
    this->NodeSkip        = 2;
  this->DisplayScalars  = 0;
    this->ScalarScaling   = 9.5;
    this->ScalarSkip      = 2;
  this->DisplayVectors  = 0;
    this->VectorScaling   = 9.5;
    this->VectorSkip      = 2;
}

//----------------------------------------------------------------------------
vtkMrmlTetraMeshNode::~vtkMrmlTetraMeshNode()
{
 if (this->TetraMeshID)
  {
    delete [] this->TetraMeshID;
    this->TetraMeshID = NULL;
  }
  if (this->FileName)
  {
    delete [] this->FileName;
    this->FileName = NULL;
  }
}

//----------------------------------------------------------------------------
void vtkMrmlTetraMeshNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  const char y[] = "yes";
  const char n[] = "no";

  vtkIndent i1(nIndent);

  of << i1 << "<TetraMesh";
  
  // Strings
  if (this->TetraMeshID && strcmp(this->TetraMeshID,""))
  {
    of << " id='" << this->TetraMeshID << "'";
  }
  if (this->Name && strcmp(this->Name, "")) 
  {
    of << " name='" << this->Name << "'";
  }
  if (this->FileName && strcmp(this->FileName, "")) 
  {
    of << " FileName='" << this->FileName << "'";
  }
  if (this->Description && strcmp(this->Description, "")) 
  {
    of << " description='" << this->Description << "'";
  }

  // Numbers

  if (this->Clipping != 0)
  {
    of << " Clipping='" << (this->Clipping ? y : n) << "'";
  }
  if (this->Opacity != 1.0)
  {
    of << " Opacity='" << this->Opacity << "'";
  }

  // Defaults are don't display anything


  if (this->DisplaySurfaces != 0)
  {
    of << " DisplaySurfaces='" << (this->DisplaySurfaces ? y : n) << "'";
  }
  if (this->SurfacesUseCellData != 1)
  {
    of << " SurfacesUseCellData'" << (this->SurfacesUseCellData ? y : n)<< "'";
  }
  if (this->SurfacesSmoothNormals != 0)
  {
   of << " SurfacesSmoothNormals'" << (this->SurfacesSmoothNormals ? y : n)<< "'";
  }
  if (this->DisplayEdges != 0)
  {
    of << " DisplayEdges='" << (this->DisplayEdges ? y : n) << "'";
  }
  if (this->DisplayNodes != 0)
  {
    of << " DisplayNodes='" << (this->DisplayNodes ? y : n) << "'";
  }
  if (this->NodeSkip != 2)
  {
    of << " NodeSkip='" << this->NodeSkip << "'";
  }
  if (this->NodeScaling != 9.5)
  {
    of << " NodeScaling='" << this->NodeScaling << "'";
  }
  if (this->DisplayScalars != 0)
  {
    of << " DisplayScalars='" << (this->DisplayScalars ? y : n) << "'";
  }
  if (this->ScalarSkip != 2)
  {
    of << " ScalarSkip='" << this->ScalarSkip << "'";
  }
  if (this->ScalarScaling != 9.5)
  {
    of << " ScalarScaling='" << this->ScalarScaling << "'";
  }
  if (this->DisplayVectors != 0)
  {
    of << " DisplayVectors='" << (this->DisplayVectors ? y : n) << "'";
  }
  if (this->VectorSkip != 2)
  {
    of << " VectorSkip='" << this->VectorSkip << "'";
  }
  if (this->VectorScaling != 9.5)
  {
    of << " VectorScaling='" << this->VectorScaling << "'";
  }

  //End
  of << "></TetraMesh>\n";;
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name, TetraMeshID
void vtkMrmlTetraMeshNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlTetraMeshNode *node = (vtkMrmlTetraMeshNode *) anode;
  
  this->Clipping        = node->Clipping;
  this->Opacity         = node->Opacity;

  this->DisplaySurfaces = node->DisplaySurfaces;
    this->SurfacesUseCellData = node->SurfacesUseCellData;
    this->SurfacesSmoothNormals = node->SurfacesSmoothNormals;
  this->DisplayEdges    = node->DisplayEdges;
  this->DisplayNodes    = node->DisplayNodes;
    this->NodeScaling     = node->NodeScaling;
    this->NodeSkip        = node->NodeSkip;
  this->DisplayScalars  = node->DisplayScalars;
    this->ScalarScaling   = node->ScalarScaling;
    this->ScalarSkip      = node->ScalarSkip;
  this->DisplayVectors  = node->DisplayVectors;
    this->VectorScaling   = node->VectorScaling;
    this->VectorSkip      = node->VectorSkip;
}


//----------------------------------------------------------------------------

void vtkMrmlTetraMeshNode::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlNode::PrintSelf(os,indent);

  os << indent << "TetraMeshID: " <<
    (this->TetraMeshID ? this->TetraMeshID : "(none)") << "\n";
  os << indent << "Name: " <<
    (this->Name ? this->Name : "(none)") << "\n";

  os << indent << "Clipping: " << this->Clipping << "\n";
  os << indent << "Opacity: " << this->Opacity << "\n";
  os << indent << "DisplaySurfaces: " << this->DisplaySurfaces << "\n";
  os << indent << "  SurfacesUseCellData: "<< this->SurfacesUseCellData<<"\n";
  os << indent << "  SurfacesSmoothNormals: "<< this->SurfacesSmoothNormals<<"\n";
  os << indent << "DisplayEdges: " << this->DisplayEdges << "\n";
  os << indent << "DisplayNodes: " << this->DisplayNodes << "\n";
  os << indent << "  NodeScaling: " << this->NodeScaling << "\n";
  os << indent << "  NodeSkip: " << this->NodeSkip << "\n";
  os << indent << "DisplayScalars: " << this->DisplayScalars << "\n";
  os << indent << "  ScalarScaling: " << this->ScalarScaling << "\n";
  os << indent << "  ScalarSkip: " << this->ScalarSkip << "\n";
  os << indent << "DisplayVectors: " << this->DisplayVectors << "\n";
  os << indent << "  VectorScaling: " << this->VectorScaling << "\n";
  os << indent << "  VectorSkip: " << this->VectorSkip << "\n";
}

