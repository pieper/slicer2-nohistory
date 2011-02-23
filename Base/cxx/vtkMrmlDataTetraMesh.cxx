/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataTetraMesh.cxx,v $
  Date:      $Date: 2006/02/27 19:21:51 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include "vtkMrmlDataTetraMesh.h"

#include "vtkObjectFactory.h"
#include "vtkCallbackCommand.h"
#include "vtkMrmlTetraMeshNode.h"
#include "vtkUnstructuredGridReader.h"
#include "vtkUnstructuredGridWriter.h"
#include "vtkCommand.h"

//------------------------------------------------------------------------------
  vtkMrmlDataTetraMesh* vtkMrmlDataTetraMesh::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlDataTetraMesh");
  if(ret)
  {
  return (vtkMrmlDataTetraMesh*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlDataTetraMesh;
}

//----------------------------------------------------------------------------
vtkMrmlDataTetraMesh::vtkMrmlDataTetraMesh()
{
  // Allocate VTK objects
  this->TheMesh = NULL;

  // Setup a callback for the internal writer to report progress.
  this->ProgressObserver = vtkCallbackCommand::New();
  this->ProgressObserver->SetCallback(&vtkMrmlData::ProgressCallbackFunction);
  this->ProgressObserver->SetClientData(this);
}

//----------------------------------------------------------------------------
vtkMrmlDataTetraMesh::~vtkMrmlDataTetraMesh()
{
  // Delete if self-created or if no one else is using it
  if (this->TheMesh != NULL) 
    {
    this->TheMesh->UnRegister(this);
    }

}

//----------------------------------------------------------------------------
void vtkMrmlDataTetraMesh::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlData::PrintSelf(os, indent);

  os << indent << "Volume Mesh: " << this->TheMesh << "\n";
  if (this->TheMesh)
    {
    this->TheMesh->PrintSelf(os,indent.GetNextIndent());
    }
}

//----------------------------------------------------------------------------
// Determine the modified time of this object
unsigned long int vtkMrmlDataTetraMesh::GetMTime()
{
  unsigned long result, t;

  result = vtkMrmlData::GetMTime();
 
  // The Mesh
  if (this->TheMesh)
    {
    t = this->TheMesh->GetMTime(); 
    result = (t > result) ? t : result;
    }

  return result;
}

//----------------------------------------------------------------------------
void vtkMrmlDataTetraMesh::CheckMrmlNode()
{
  // If the user has not set the ImageData, then create it.
  // The key is to perform: New(), Register(), Delete().
  // Then we can call UnRegister() in the destructor, and it will delete
  // the object if no one else is using it.  We don't have to distinguish
  // between whether we created the object, or someone else did!

  if (this->MrmlNode == NULL)
    {
    this->MrmlNode = (vtkMrmlNode*) vtkMrmlTetraMeshNode::New();
    this->MrmlNode->Register(this);
    this->MrmlNode->Delete();
    }
}

//----------------------------------------------------------------------------
void vtkMrmlDataTetraMesh::Update()
{
  this->vtkMrmlData::Update();
  
  // We really should have an Update time that we compare with the
  // MTime, but since the other objects inside this class do this, 
  // its alright.


}

//----------------------------------------------------------------------------
vtkUnstructuredGrid* vtkMrmlDataTetraMesh::GetOutput()
{
  this->Update();
  return this->TheMesh;
}

//----------------------------------------------------------------------------
int vtkMrmlDataTetraMesh::Read()
{
  vtkMrmlTetraMeshNode *node = (vtkMrmlTetraMeshNode*) this->MrmlNode;

  vtkUnstructuredGridReader *reader = vtkUnstructuredGridReader::New();
  reader->SetFileName(node->GetFileName());
  reader->Update();

  // Detach image data from reader
  this->SetTheMesh(reader->GetOutput());
  reader->SetOutput(NULL);
  this->ProcessObject = NULL;
  reader->Delete();

  // End progress reporting
  this->InvokeEvent(vtkCommand::EndEvent,NULL);

  // Update W/L
  this->Update();

  // Right now how no way to deal with failure
  return 1;
}


//----------------------------------------------------------------------------
int vtkMrmlDataTetraMesh::Write()
{

  this->CheckMrmlNode();
  vtkMrmlTetraMeshNode *node = (vtkMrmlTetraMeshNode*) this->MrmlNode;
  
  // Start progress reporting
  this->InvokeEvent(vtkCommand::StartEvent,NULL);

  // Set up the image writer
  vtkUnstructuredGridWriter *writer = vtkUnstructuredGridWriter::New();
  writer->SetFileName(node->GetFileName());
  writer->SetInput(this->TheMesh);
  
//#ifndef SLICER_VTK5
    // TODO -- need fix for vtk 5
  // Progress callback
  writer->AddObserver (vtkCommand::ProgressEvent,
                       this->ProgressObserver);
  // The progress callback function needs a handle to the writer 
  this->ProcessObject = writer;
//#endif
 
  // Write it
  writer->Write();

  writer->SetInput(NULL);
  writer->Delete();

  // End progress reporting
  this->InvokeEvent(vtkCommand::EndEvent,NULL);

  // Right now how no way to deal with failure
  return 1;
}
