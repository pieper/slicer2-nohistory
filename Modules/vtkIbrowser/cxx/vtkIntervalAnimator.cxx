/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalAnimator.cxx,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIntervalAnimator.h"
#include "vtkIbrowserConfigure.h"
#include <stdio.h>


vtkCxxRevisionMacro(vtkIntervalAnimator, "$Revision: 1.4 $");

int vtkIntervalAnimator::animationPaused = 0;
int vtkIntervalAnimator::animationRunning = 0;
int vtkIntervalAnimator::animationMode = ONCE;
int vtkIntervalAnimator::animationDirection = FORWARD;


//--------------------------------------------------------------------------------------
vtkIntervalAnimator *vtkIntervalAnimator::New ( )
{
    vtkObject* ret = vtkObjectFactory::CreateInstance ( "vtkIntervalAnimator" );
    if ( ret ) {
        return ( vtkIntervalAnimator* ) ret;
    }
    return new vtkIntervalAnimator;
}



//--------------------------------------------------------------------------------------
vtkIntervalAnimator::vtkIntervalAnimator ( ) {

}



//--------------------------------------------------------------------------------------
vtkIntervalAnimator::~vtkIntervalAnimator ( ) {
    
}

//--------------------------------------------------------------------------------------
int vtkIntervalAnimator::getAnimationMode ( ) {

    return vtkIntervalAnimator::animationMode;
}

//--------------------------------------------------------------------------------------
void vtkIntervalAnimator::setAnimationMode ( int setting) {

    vtkIntervalAnimator::animationMode = setting;
}


//--------------------------------------------------------------------------------------
int vtkIntervalAnimator::getAnimationDirection ( ) {

    return vtkIntervalAnimator::animationDirection;
}

//--------------------------------------------------------------------------------------
void vtkIntervalAnimator::setAnimationDirection ( int setting) {

    vtkIntervalAnimator::animationDirection = setting;
}


//--------------------------------------------------------------------------------------
int vtkIntervalAnimator::getAnimationPaused ( ) {

    return vtkIntervalAnimator::animationPaused;
}

//--------------------------------------------------------------------------------------
void vtkIntervalAnimator::setAnimationPaused ( int setting) {

    vtkIntervalAnimator::animationPaused = setting;
}

//--------------------------------------------------------------------------------------
int vtkIntervalAnimator::getAnimationRunning ( ) {

    return vtkIntervalAnimator::animationRunning;
}

//--------------------------------------------------------------------------------------
void vtkIntervalAnimator::setAnimationRunning ( int setting) {

    vtkIntervalAnimator::animationRunning = setting;
}


//--------------------------------------------------------------------------------------
void vtkIntervalAnimator::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);
}

