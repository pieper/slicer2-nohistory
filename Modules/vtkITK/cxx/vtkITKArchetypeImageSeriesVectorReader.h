/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKArchetypeImageSeriesVectorReader.h,v $
  Date:      $Date: 2006/03/06 20:09:01 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#ifndef __vtkITKArchetypeImageSeriesVectorReader_h
#define __vtkITKArchetypeImageSeriesVectorReader_h

#include "vtkITKArchetypeImageSeriesReader.h"

class VTK_EXPORT vtkITKArchetypeImageSeriesVectorReader : public vtkITKArchetypeImageSeriesReader
{
 public:
  static vtkITKArchetypeImageSeriesVectorReader *New();
  vtkTypeRevisionMacro(vtkITKArchetypeImageSeriesVectorReader,vtkITKArchetypeImageSeriesReader);
  void PrintSelf(ostream& os, vtkIndent indent);

 protected:
  vtkITKArchetypeImageSeriesVectorReader();
  ~vtkITKArchetypeImageSeriesVectorReader();

  void ExecuteData(vtkDataObject *data);

  // private:
};

#endif
