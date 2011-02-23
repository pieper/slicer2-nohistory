/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkXDisplayWindow.cxx,v $
  Date:      $Date: 2006/01/06 17:56:51 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#ifndef _WIN32
#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#endif
#include "vtkXDisplayWindow.h"
#include "vtkObjectFactory.h"

//----------------------------------------------------------------------------
vtkXDisplayWindow* vtkXDisplayWindow::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkXDisplayWindow");
  if(ret)
    {
    return (vtkXDisplayWindow*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkXDisplayWindow;
}

vtkXDisplayWindow::vtkXDisplayWindow()
{
  this->RenderWindow = NULL;
}

vtkXDisplayWindow::~vtkXDisplayWindow()
{
  if(this->RenderWindow) {
    this->RenderWindow->Delete();
    this->RenderWindow = NULL;
  }
}

vtkRenderWindow* vtkXDisplayWindow::GetRenderWindow(int screen)
{
  if (this->RenderWindow != NULL) {
    this->RenderWindow->Delete();
    this->RenderWindow = NULL;
  }
  char str[80];
  sprintf(str, ":0.%d", screen);
  fprintf(stderr, "vtkXDisplayWindow: Creating display '%s'.\n", str);

  this->RenderWindow = vtkRenderWindow::New();
#ifndef _WIN32
  this->RenderWindow->SetDisplayId(XOpenDisplay(str));
#endif
  return this->RenderWindow;
}
