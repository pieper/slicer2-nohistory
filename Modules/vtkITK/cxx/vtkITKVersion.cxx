/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKVersion.cxx,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#ifndef _vtkITKVersion_cxx
#define _vtkITKVersion_cxx

#include "vtkITKVersion.h"

vtkITKVersion* vtkITKVersion::New()
{
    return new vtkITKVersion;
}

char * vtkITKVersion::GetITKVersion()
{
    return ITK_VERSION_STRING;
}

void vtkITKVersion::PrintSelf(ostream& os, vtkIndent indent)
{
}

#endif
