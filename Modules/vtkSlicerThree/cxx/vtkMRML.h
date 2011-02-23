/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   MRML
  Module:    $RCSfile: vtkMRML.h,v $
  Date:      $Date: 2006/03/19 17:12:28 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

/*
 * This is needed for loading mrml code as module.
 */


//
// use an ifdef on MRML_VTK5 to flag code that won't
// compile on vtk4.4 and before
//
#if ( (VTK_MAJOR_VERSION >= 5) || ( VTK_MAJOR_VERSION == 4 && VTK_MINOR_VERSION >= 5 ) )
#define MRML_VTK5
#endif
/*
#if defined(WIN32) && !defined(VTKMRML_STATIC)
#if defined(MRML_EXPORTS)
#define VTK_MRML_EXPORT __declspec( dllexport ) 
#else
#define VTK_MRML_EXPORT __declspec( dllimport ) 
#endif
#else
#define VTK_MRML_EXPORT
#endif
*/
#define VTK_MRML_EXPORT VTK_EXPORT
