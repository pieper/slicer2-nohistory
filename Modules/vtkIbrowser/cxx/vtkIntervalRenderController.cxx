/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalRenderController.cxx,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIntervalRenderController.h"
#include <vtkIbrowserConfigure.h>


vtkCxxRevisionMacro(vtkIntervalRenderController, "$Revision: 1.4 $");

//--------------------------------------------------------------------------------------
vtkIntervalRenderController *vtkIntervalRenderController::New ( )
{
    vtkObject* ret = vtkObjectFactory::CreateInstance ( "vtkIntervalRenderController" );
    if ( ret ) {
        return ( vtkIntervalRenderController* ) ret;
    }
    return new vtkIntervalRenderController;
}

//--------------------------------------------------------------------------------------
vtkIntervalRenderController::vtkIntervalRenderController ( ) {
    this->Opacity = 1.0;
}


//--------------------------------------------------------------------------------------
vtkIntervalRenderController::~vtkIntervalRenderController ( ) {

}


//--------------------------------------------------------------------------------------
void vtkIntervalRenderController::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);
    
}

