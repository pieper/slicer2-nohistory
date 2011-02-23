/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKVersion.h,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef __vtkITKVersion_h
#define __vtkITKVersion_h

#include "vtkObjectFactory.h"

#include <itkConfigure.h>
#include <itkVersion.h>

class VTK_EXPORT vtkITKVersion : public vtkObject
{
public:
    static vtkITKVersion *New();
    vtkTypeMacro(vtkITKVersion,vtkObject);
    void PrintSelf(ostream& os, vtkIndent indent);
    
    char *GetITKVersion();
};
#endif
