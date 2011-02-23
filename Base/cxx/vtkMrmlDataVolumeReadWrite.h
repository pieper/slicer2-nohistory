/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolumeReadWrite.h,v $
  Date:      $Date: 2006/02/14 20:40:13 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
// .NAME vtkMrmlDataVolumeReadWrite - 
// .SECTION Description
// This sub-object is specific to each
// type of volume that needs to be read in.  This can be used
// to clean up the special cases which handle
// volumes of various types, such as dicom, header, etc.  In
// future these things can be moved here.  Each read/write 
// sub-object corresponds to a vtkMrmlVolumeReadWriteNode subclass.
// These subclasses write any needed info in the MRML file.
//

#ifndef __vtkMrmlDataVolumeReadWrite_h
#define __vtkMrmlDataVolumeReadWrite_h

#include "vtkObject.h"
#include "vtkSlicer.h"
#include "vtkMrmlVolumeNode.h"
#include "vtkImageSource.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlDataVolumeReadWrite : public vtkObject
{
  public:
  static vtkMrmlDataVolumeReadWrite *New();
  vtkTypeMacro(vtkMrmlDataVolumeReadWrite,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Return code indicates success (1) or error (0)
  virtual int Read(vtkMrmlVolumeNode *node, vtkImageSource **output);
  virtual int Write(vtkMrmlVolumeNode *node, vtkImageData *input);

  //--------------------------------------------------------------------------
  // Specifics for reading/writing each type of volume data
  //--------------------------------------------------------------------------

  // Subclasses must fill these in.

protected:
  vtkMrmlDataVolumeReadWrite();
  ~vtkMrmlDataVolumeReadWrite();
  vtkMrmlDataVolumeReadWrite(const vtkMrmlDataVolumeReadWrite&);
  void operator=(const vtkMrmlDataVolumeReadWrite&);
};

#endif
