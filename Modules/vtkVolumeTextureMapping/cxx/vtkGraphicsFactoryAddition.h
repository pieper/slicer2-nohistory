/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkGraphicsFactoryAddition.h,v $
  Date:      $Date: 2006/01/06 17:58:07 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

// .NAME vtkGraphicsFactoryAddition - 
// .SECTION Description

#ifndef __vtkGraphicsFactoryAddition_h
#define __vtkGraphicsFactoryAddition_h
#include <vtkVolumeTextureMappingConfigure.h>
#include "vtkObject.h"

class VTK_VOLUMETEXTUREMAPPING_EXPORT vtkGraphicsFactoryAddition : public vtkObject
{
public:
  static vtkGraphicsFactoryAddition *New();
  vtkTypeRevisionMacro(vtkGraphicsFactoryAddition,vtkObject);


  // Description:
  // Create and return an instance of the named vtk object.
  // This method first checks the vtkObjectFactory to support
  // dynamic loading. 
  static vtkObject* CreateInstance(const char* vtkclassname);

  // Description:
  // What rendering library has the user requested
  static const char *GetRenderLibrary();

  // Description:
  // This option enables the creation of Mesa classes
  // instead of the OpenGL classes when using mangled Mesa.
  static void SetUseMesaClasses(int use);
  static int  GetUseMesaClasses();
  
protected:
  vtkGraphicsFactoryAddition() {};

  static int UseMesaClasses;

private:
  vtkGraphicsFactoryAddition(const vtkGraphicsFactoryAddition&);  // Not implemented.
  void operator=(const vtkGraphicsFactoryAddition&);  // Not implemented.
};

#endif
