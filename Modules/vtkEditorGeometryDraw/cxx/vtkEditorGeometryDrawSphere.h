/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEditorGeometryDrawSphere.h,v $
  Date:      $Date: 2006/12/28 21:54:17 $
  Version:   $Revision: 1.1 $

=========================================================================auto=*/
#ifndef __vtkEditorGeometryDrawSphere_h
#define __vtkEditorGeometryDrawSphere_h

#include "vtkSlicer.h"
#include "vtkSphere.h"
#include "vtkImplicitFunctionToImageStencil.h"
#include "vtkImageStencil.h"
#include "vtkMrmlDataVolume.h"
#include "vtkImageEditor.h"
#include "vtkImageStencilData.h"
#include "vtkImageToImageFilter.h"

#include "vtkEditorGeometryDrawConfigure.h"

class VTK_EDITORGEOMETRYDRAW_EXPORT vtkEditorGeometryDrawSphere : public vtkImageToImageFilter
{
public:
  // -----------------------------------------------------
  // General Functions for the filter
  // -----------------------------------------------------
  static vtkEditorGeometryDrawSphere *New();

  vtkTypeMacro(vtkEditorGeometryDrawSphere,vtkImageToImageFilter);
  vtkEditorGeometryDrawSphere();
  ~vtkEditorGeometryDrawSphere();
  //vtkTypeRevisionMacro(vtkEditorGeometryDrawSphere,vtkImageToImageFilter)
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkSetObjectMacro(Vol, vtkMrmlDataVolume);
  vtkSetObjectMacro(Ed, vtkImageEditor);
  
  void ApplySphere(float ci, float cj, float ck, float radius, int label); // , vtkMrmlDataVolume *vol, vtkImageEditor *ed);

protected:
  void ExecuteData(vtkDataObject *);
  
  vtkMrmlDataVolume *Vol;
  vtkImageEditor *Ed;

private:
  vtkEditorGeometryDrawSphere(const vtkEditorGeometryDrawSphere&);
  void operator=(const vtkEditorGeometryDrawSphere&);
};

#endif
