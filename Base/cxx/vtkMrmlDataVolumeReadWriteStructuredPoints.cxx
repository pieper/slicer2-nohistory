/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolumeReadWriteStructuredPoints.cxx,v $
  Date:      $Date: 2006/01/12 00:08:00 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
#include "vtkPointData.h"
#include "vtkMrmlDataVolumeReadWriteStructuredPoints.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkStructuredPointsReader.h"
#include "vtkStructuredPointsWriter.h"
#include "vtkDataArray.h"

  //------------------------------------------------------------------------------
  vtkMrmlDataVolumeReadWriteStructuredPoints* vtkMrmlDataVolumeReadWriteStructuredPoints::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlDataVolumeReadWriteStructuredPoints");
  if(ret)
  {
    return (vtkMrmlDataVolumeReadWriteStructuredPoints*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlDataVolumeReadWriteStructuredPoints;
}

//----------------------------------------------------------------------------
vtkMrmlDataVolumeReadWriteStructuredPoints::vtkMrmlDataVolumeReadWriteStructuredPoints()
{
  this->FileName = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlDataVolumeReadWriteStructuredPoints::~vtkMrmlDataVolumeReadWriteStructuredPoints()
{

}

//----------------------------------------------------------------------------
void vtkMrmlDataVolumeReadWriteStructuredPoints::PrintSelf(ostream& os, vtkIndent indent)
{

}

//----------------------------------------------------------------------------
//
// Do all the reading.
// Return the vtkImageSource already updated
// to be used by vtkMrmlDataVolume->Read
//
int vtkMrmlDataVolumeReadWriteStructuredPoints::Read(vtkMrmlVolumeNode *node, 
                                                     vtkImageSource **output)
{
  vtkStructuredPointsReader* reader = vtkStructuredPointsReader::New();
  //reader->DebugOn();
  reader->SetFileName(this->FileName);
  reader->Update();
  // perhaps we should tell the reader this info,
  // but the default may be worse than the reader's default.
  //node->GetLittleEndian();  

  // return pointer to the reader object
  *output = (vtkImageSource *) reader;

  // set up things in the node that are specified by the file
  int ext[6];
  vtkStructuredPoints *sp =   reader->GetOutput();
  sp->GetExtent(ext);
  node->SetImageRange(ext[4],ext[5]);
  node->SetDimensions(ext[1]-ext[0]+1,ext[3]-ext[2]+1);
  node->SetSpacing(sp->GetSpacing());
  node->SetScalarType(sp->GetScalarType());
  if (sp->GetPointData()->GetScalars())
    node->SetNumScalars(sp->GetPointData()->GetScalars()->GetNumberOfComponents());
  else
    node->SetNumScalars(0);
  // Set up things in the node that may have required user input.
  // These things should be set in the node from the GUI 
  // before reading in the volume, since this info is not in a 
  // structured points file
  //node->SetLittleEndian();  // was set from GUI already
  //node->SetTilt();   // was set from GUI
  // this should be set in the node from GUI input before reading file
  node->ComputeRasToIjkFromScanOrder(node->GetScanOrder());
  // return success
  return 1;
}


//----------------------------------------------------------------------------
int vtkMrmlDataVolumeReadWriteStructuredPoints::Write(vtkMrmlVolumeNode *node,
                                                      vtkImageData *input)
{
  vtkStructuredPointsWriter* writer = vtkStructuredPointsWriter::New();
  //writer->DebugOn();
  writer->SetFileName(this->FileName);
  writer->SetInput(input);
  writer->Update();

  writer->Delete();
  // return success
  return 1;
}
