/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkINRWriter.h,v $
  Date:      $Date: 2006/02/14 20:51:33 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkINRWriter_h
#define __vtkINRWriter_h

#include <vtkAGConfigure.h>

#include "vtkImageWriter.h"
#include "vtkImageData.h"

class VTK_AG_EXPORT vtkINRWriter : public vtkImageWriter
{
public:
  static vtkINRWriter *New();
  vtkTypeMacro(vtkINRWriter,vtkImageWriter);

  vtkSetMacro(WritePixelSizes,bool);
  vtkGetMacro(WritePixelSizes,bool);
  vtkBooleanMacro(WritePixelSizes,bool);

protected:
  vtkINRWriter();
  ~vtkINRWriter() {};
  vtkINRWriter(const vtkINRWriter&);
  void operator=(const vtkINRWriter&);

  virtual void WriteFileHeader(ofstream *, vtkImageData *);

private:
  bool WritePixelSizes;
};

#endif


