/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkEditorGeometryDrawSphere.cxx,v $
  Date:      $Date: 2007/03/15 19:43:22 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "vtkObjectFactory.h"

#include "vtkEditorGeometryDrawSphere.h"


//vtkCxxRevisionMacro(vtkEditorGeometryDrawSphere, "$Revision: 1.2 $");
//vtkStandardNewMacro(vtkEditorGeometryDrawSphere);

//------------------------------------------------------------------------------
vtkEditorGeometryDrawSphere* vtkEditorGeometryDrawSphere::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkEditorGeometryDrawSphere");
  if (ret)
    {
    return (vtkEditorGeometryDrawSphere*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkEditorGeometryDrawSphere;
}

//------------------------------------------------------------------------------
vtkEditorGeometryDrawSphere::vtkEditorGeometryDrawSphere()
{
  this->Ed = NULL;
  this->Vol = NULL;
}

//------------------------------------------------------------------------------
vtkEditorGeometryDrawSphere::~vtkEditorGeometryDrawSphere()
{
}

//------------------------------------------------------------------------------
void vtkEditorGeometryDrawSphere::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkObject::PrintSelf(os, indent);
  os << indent << "vtkEditorGeometryDrawSphere.\n";
}

//------------------------------------------------------------------------------
void vtkEditorGeometryDrawSphere::ExecuteData(vtkDataObject *)
{
  vtkImageData *inData = this->GetInput();
  vtkImageData *outData = this->GetOutput();

  outData->SetExtent(this->GetOutput()->GetWholeExtent());
  outData->AllocateScalars();

  int outExt[6];
  outData->GetWholeExtent(outExt);
  void *inPtr = inData->GetScalarPointerForExtent(outExt);
  void *outPtr = outData->GetScalarPointerForExtent(outExt);

}

//------------------------------------------------------------------------------
void vtkEditorGeometryDrawSphere::ApplySphere(float ci, float cj, float ck, float radius, int label) //, vtkMrmlDataVolume *vol, vtkImageEditor *ed)
{
    if (this->Vol == NULL)
      {
      std::cout << "Volume is null.\n";
      return;
      }
    if (this->Ed == NULL)
      {
      std::cout << "Editor pointer is null\n";
      return;
      }
    
    vtkSphere *sphere = vtkSphere::New();
    sphere->SetCenter(ci, cj, ck);
    sphere->SetRadius(radius);
    
    vtkImplicitFunctionToImageStencil *functionToStencil = vtkImplicitFunctionToImageStencil::New();
    functionToStencil->SetInput(sphere);

    functionToStencil->GetOutput()->SetUpdateExtent(this->Vol->GetOutput()->GetExtent());
    functionToStencil->GetOutput()->SetSpacing(this->Vol->GetOutput()->GetSpacing());
    functionToStencil->Update();
    
    vtkImageStencil *stencil = vtkImageStencil::New();

    stencil->ReverseStencilOn();
    stencil->SetStencil(functionToStencil->GetOutput());
    stencil->SetBackgroundValue(label);

    this->Ed->SetInput(this->Vol->GetOutput());
    this->Ed->UseInputOn();
    this->Ed->SetFirstFilter(stencil);
    this->Ed->SetLastFilter(stencil);
    this->Ed->Apply();
    
    stencil->Delete();
    functionToStencil->Delete();
    sphere->Delete();
}
