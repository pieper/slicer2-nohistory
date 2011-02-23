/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkINRReader.h,v $
  Date:      $Date: 2006/02/14 20:51:33 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkINRReader_h
#define __vtkINRReader_h

#include <vtkAGConfigure.h>

#include <stdio.h>
#include "vtkImageReader.h"

class VTK_AG_EXPORT vtkINRReader : public vtkImageReader
{
public:
  static vtkINRReader *New();
  vtkTypeMacro(vtkINRReader,vtkImageReader);
  
protected:
  vtkINRReader() {};
  ~vtkINRReader() {};
  vtkINRReader(const vtkINRReader&);
  void operator=(const vtkINRReader&);
  void ExecuteInformation();
};

#endif


