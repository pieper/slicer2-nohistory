/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKSceneSpatialObjectViewer.h,v $
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKSceneSpatialObjectViewer.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:48 $
  Version:   $Revision: 1.3 $
*/
// .NAME vtkITKSceneSpatialObjectViewer
// .SECTION Description
// vtkITKSceneSpatialObjectViewer


#ifndef __vtkITKSceneSpatialObjectViewer_h
#define __vtkITKSceneSpatialObjectViewer_h

#ifdef _MSC_VER
#pragma warning ( disable : 4786 )
#pragma warning ( disable : 4284 )
#pragma warning ( disable : 4018 )
#endif

#include "vtkProcessObject.h"
#include "sovVTKRenderer3D.h"
#include "vtkObjectFactory.h"
#include "vtkRenderer.h"

class VTK_EXPORT vtkITKSceneSpatialObjectViewer : public vtkProcessObject
{
 
public:
  static vtkITKSceneSpatialObjectViewer *New();
  vtkTypeRevisionMacro(vtkITKSceneSpatialObjectViewer, vtkProcessObject);

  void SetRenderer(vtkRenderer* renderer)
    {
    m_Renderer = renderer;
    }

  void SetFileName(const char* filename)
    {
    m_FileName = filename;
    }
  void AddActors();

protected:
  //BTX
  vtkITKSceneSpatialObjectViewer() // : Superclass ( vtkObject::New() )
    {
    };

  ~vtkITKSceneSpatialObjectViewer() {};
  //ETX
  
private:
  vtkITKSceneSpatialObjectViewer(const vtkITKSceneSpatialObjectViewer&);  // Not implemented.
  void operator=(const vtkITKSceneSpatialObjectViewer&);  // Not implemented.

  vtkRenderer*                 m_Renderer;
  const char*                  m_FileName;
};

vtkCxxRevisionMacro(vtkITKSceneSpatialObjectViewer, "$Revision: 1.3 $");
vtkStandardNewMacro(vtkITKSceneSpatialObjectViewer);

#endif




