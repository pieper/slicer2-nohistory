/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSlicerBaseWin32Header.h,v $
  Date:      $Date: 2006/01/06 17:56:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkSlicerBaseWin32Header.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:56:51 $
  Version:   $Revision: 1.4 $

  Copyright (c) 1993-2002 Ken Martin, Will Schroeder, Bill Lorensen 
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkSlicerBaseWin32Header - manage Windows system differences
// .SECTION Description
// The vtkSlicerBaseWin32Header captures some system differences between Unix
// and Windows operating systems. 

#ifndef __vtkSlicerBaseWin32Header_h
#define __vtkSlicerBaseWin32Header_h

#include <vtkSlicerConfigure.h>

#if defined(WIN32) && !defined(VTKSLICER_STATIC)
#if defined(vtkSlicerBase_EXPORTS)
#define VTK_SLICER_BASE_EXPORT __declspec( dllexport ) 
#else
#define VTK_SLICER_BASE_EXPORT __declspec( dllimport ) 
#endif
#else
#define VTK_SLICER_BASE_EXPORT
#endif

#endif
