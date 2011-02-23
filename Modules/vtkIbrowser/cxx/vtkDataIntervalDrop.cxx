/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDataIntervalDrop.cxx,v $
  Date:      $Date: 2006/01/06 17:57:49 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkDataIntervalDrop.h"

vtkCxxRevisionMacro(vtkDataIntervalDrop, "$Revision: 1.4 $");

//--------------------------------------------------------------------------------------
vtkDataIntervalDrop *vtkDataIntervalDrop::New( )
{
    vtkObject *ret = vtkObjectFactory::CreateInstance ("vtkDataIntervalDrop");
    if (ret) 
        {
        return ( vtkDataIntervalDrop* ) ret;
        }
    return new vtkDataIntervalDrop;
}



//--------------------------------------------------------------------------------------
vtkDataIntervalDrop::vtkDataIntervalDrop ( ) 
{
    // allocate data.
    this->drop = vtkDataObject::New ( );
    this->next = NULL;
    this->prev = NULL;
    this->myTransform = NULL;
}


//--------------------------------------------------------------------------------------
vtkDataIntervalDrop::vtkDataIntervalDrop ( vtkTransform& tr)
{
    // add t into the transform pipeline for this drop.
    this->drop = vtkDataObject::New ( );
    this->next = NULL;
    this->prev = NULL;
    this->myTransform = &tr;
}

//--------------------------------------------------------------------------------------
vtkDataIntervalDrop::~vtkDataIntervalDrop ( ) 
{
    // delete data.
    this->drop->Delete ( );
    this->myTransform->Delete ();
}


//--------------------------------------------------------------------------------------
void vtkDataIntervalDrop::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkIntervalDrop::PrintSelf(os, indent);
    
}
