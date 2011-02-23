/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPTSWriter.h,v $
  Date:      $Date: 2006/02/14 20:40:16 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkPTSWriter.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkPTSWriter - Writes Windows NMBL PTS files.
// .SECTION Description
// vtkPTSWriter writes PTS files.

#ifndef __vtkPTSWriter_h
#define __vtkPTSWriter_h

#include "vtkImageWriter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkPTSWriter : public vtkImageWriter
{
public:
  static vtkPTSWriter *New();
  vtkTypeMacro(vtkPTSWriter,vtkImageWriter);
  virtual void PrintSelf(ostream& os, vtkIndent indent);
  void WriteAsciiPTS();

protected:
  vtkPTSWriter();
  ~vtkPTSWriter() {};

  virtual void WriteFile(ofstream *file, vtkImageData *data, int ext[6]);
  virtual void WriteFileHeader(ofstream *, vtkImageData *);
private:
  vtkPTSWriter(const vtkPTSWriter&);  // Not implemented.
  void operator=(const vtkPTSWriter&);  // Not implemented.
};

#endif


