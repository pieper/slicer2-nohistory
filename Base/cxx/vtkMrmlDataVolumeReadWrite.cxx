/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolumeReadWrite.cxx,v $
  Date:      $Date: 2006/01/06 17:56:45 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkMrmlDataVolumeReadWrite.h"
#include "vtkObjectFactory.h"

  //------------------------------------------------------------------------------
  vtkMrmlDataVolumeReadWrite* vtkMrmlDataVolumeReadWrite::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlDataVolumeReadWrite");
  if(ret)
  {
    return (vtkMrmlDataVolumeReadWrite*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlDataVolumeReadWrite;
}

//----------------------------------------------------------------------------
vtkMrmlDataVolumeReadWrite::vtkMrmlDataVolumeReadWrite()
{

}

//----------------------------------------------------------------------------
vtkMrmlDataVolumeReadWrite::~vtkMrmlDataVolumeReadWrite()
{

}

//----------------------------------------------------------------------------
void vtkMrmlDataVolumeReadWrite::PrintSelf(ostream& os, vtkIndent indent)
{

}

//----------------------------------------------------------------------------
//
// Do all the reading.
// Return the vtkImageSource already updated
// to be used by vtkMrmlDataVolume->Read
//
int vtkMrmlDataVolumeReadWrite::Read(vtkMrmlVolumeNode *node, 
                                     vtkImageSource **output)
{
  output = NULL;
  // return success
  return 1;
}


//----------------------------------------------------------------------------
int vtkMrmlDataVolumeReadWrite::Write(vtkMrmlVolumeNode *node,
                                      vtkImageData *input)
{
  // return success
  return 1;
}
