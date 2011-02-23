/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageResliceST.h,v $
  Date:      $Date: 2006/01/06 17:57:10 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkImageResliceST_h
#define __vtkImageResliceST_h

#include <vtkAGConfigure.h>


#include "vtkImageReslice.h"

class VTK_AG_EXPORT vtkImageResliceST : public vtkImageReslice
{
public:
  static vtkImageResliceST *New();
  vtkTypeMacro(vtkImageResliceST, vtkImageReslice);

  virtual void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkImageResliceST();
  ~vtkImageResliceST();
  vtkImageResliceST(const vtkImageResliceST&);
  void operator=(const vtkImageResliceST&);

  void ThreadedExecute(vtkImageData *inData, vtkImageData *outData, 
               int ext[6], int id);
};

#endif





