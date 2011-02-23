/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalStudy.cxx,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIntervalStudy.h"

//Description:
// A vtkIntervalStudy contains a doubly-linked list of
// related intervals. The collection's GUI representation
// mediates the exploration of data contained within each
// interval in the collection. The collection can be named,
// edited, saved and reloaded.
//--------------------------------------------------------------------------------------
vtkIntervalStudy *vtkIntervalStudy::New ( )
{
    vtkObject* ret = vtkObjectFactory::CreateInstance ( "vtkIntervalStudy" );
    if ( ret ) {
        return ( vtkIntervalStudy* ) ret;
    }
    return new vtkIntervalStudy;
}




//--------------------------------------------------------------------------------------
vtkIntervalStudy::vtkIntervalStudy ( ) {

    // initialize some parameters.
    this->Name = "defaultNew";
    this->zoomfactor = 1;
    this->intervalCollection = vtkIntervalCollection::New();
    this->player = NULL;
}



//--------------------------------------------------------------------------------------
vtkIntervalStudy::vtkIntervalStudy ( int ID ) {

    // initialize some parameters.
    this->Name = "defaultNew";
    this->zoomfactor = 1;
    this->intervalCollection = vtkIntervalCollection::New(ID);
    this->player = NULL;
}



//--------------------------------------------------------------------------------------
vtkIntervalStudy::vtkIntervalStudy ( float min, float max ) {

    this->Name = "defaultNew";
    this->zoomfactor = 1;
    this->intervalCollection = vtkIntervalCollection::New( min, max );
    this->player = NULL;
}


//--------------------------------------------------------------------------------------
vtkIntervalStudy::vtkIntervalStudy ( float min, float max, int ID ) {

    this->Name = "defaultNew";
    this->zoomfactor = 1;
    this->intervalCollection = vtkIntervalCollection::New( min, max, ID);
    this->player = NULL;
}




//--------------------------------------------------------------------------------------
vtkIntervalStudy::~vtkIntervalStudy ( ) {
}





//--------------------------------------------------------------------------------------
vtkCxxRevisionMacro ( vtkIntervalStudy, "$revision: 1.1 $" );






//--------------------------------------------------------------------------------------
void vtkIntervalStudy::PrintSelf ( ostream &os, vtkIndent indent ) {

    vtkObject::PrintSelf (os, indent );
}





//--------------------------------------------------------------------------------------
void vtkIntervalStudy::deleteIntervalStudy ( ){

    //delete intervals, but keep the empty collection.
    this->Name = "";
}


//--------------------------------------------------------------------------------------
void vtkIntervalStudy::zoomInIntervalStudy ( int zf ) {

    // zooms in by a factor of zoomfactor
    this->zoomfactor = zf;

}



//--------------------------------------------------------------------------------------
void vtkIntervalStudy::zoomOutIntervalStudy ( int zf ) {

    // zooms in by a factor of zoomfactor
    this->zoomfactor = zf;
}




