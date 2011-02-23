/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkXDisplayWindow.h,v $
  Date:      $Date: 2006/01/06 17:56:51 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
// .NAME vtkXDisplayWindow - Used to display a vtk window on an X display.
// .SECTION Description
// Can display on any screen (display) number.
//

#ifndef __vtkXDisplayWindow_h
#define __vtkXDisplayWindow_h

#include <stdio.h>
#include "vtkRenderWindow.h"
#include "vtkObject.h"

#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkXDisplayWindow : public vtkObject
{
public:
  static vtkXDisplayWindow *New();
  vtkTypeMacro(vtkXDisplayWindow, vtkObject);

  vtkRenderWindow* GetRenderWindow(int screen);

protected:
  vtkXDisplayWindow();
  ~vtkXDisplayWindow();
  vtkRenderWindow *RenderWindow;
};

#endif


