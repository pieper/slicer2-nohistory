/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolumeReadWriteStructuredPoints.h,v $
  Date:      $Date: 2006/02/14 20:40:14 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkMrmlDataVolumeReadWriteStructuredPoints - 
// .SECTION Description
// This sub-object is specific to each
// type of volume that needs to be read in.  This can be used
// to clean up the special cases which handle
// volumes of various types, such as dicom, header, etc.  In
// future these things can be moved here.  Each read/write 
// sub-object corresponds to a vtkMrmlVolumeReadWriteNode subclass.
// These subclasses write any needed info in the MRML file.
//

#ifndef __vtkMrmlDataVolumeReadWriteStructuredPoints_h
#define __vtkMrmlDataVolumeReadWriteStructuredPoints_h

#include "vtkObject.h"
#include "vtkSlicer.h"
#include "vtkMrmlVolumeNode.h"
#include "vtkStructuredPoints.h"
#include "vtkMrmlDataVolumeReadWrite.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlDataVolumeReadWriteStructuredPoints : public vtkMrmlDataVolumeReadWrite 
{
  public:
  static vtkMrmlDataVolumeReadWriteStructuredPoints *New();
  vtkTypeMacro(vtkMrmlDataVolumeReadWriteStructuredPoints,vtkMrmlDataVolumeReadWrite);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Return code indicates success (1) or error (0)
  int Read(vtkMrmlVolumeNode *node, vtkImageSource **output);
  int Write(vtkMrmlVolumeNode *node, vtkImageData *input);

  //--------------------------------------------------------------------------
  // Specifics for reading/writing each type of volume data
  //--------------------------------------------------------------------------

  // Subclasses must fill these in.
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

protected:
  vtkMrmlDataVolumeReadWriteStructuredPoints();
  ~vtkMrmlDataVolumeReadWriteStructuredPoints();
  vtkMrmlDataVolumeReadWriteStructuredPoints(const vtkMrmlDataVolumeReadWriteStructuredPoints&);
  void operator=(const vtkMrmlDataVolumeReadWriteStructuredPoints&);

  char *FileName;

};

#endif
