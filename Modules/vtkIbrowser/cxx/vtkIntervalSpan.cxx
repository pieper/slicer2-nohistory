/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalSpan.cxx,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkObjectFactory.h"
#include "vtkObject.h"
#include "vtkIntervalSpan.h"


// Description:
// This is a basic container for a Span populated by data.
// A vtkIntervalSpan might encapsulate an entire interval,
// or several vtkIntervalSpans might be included within an
// interval.
//--------------------------------------------------------------------------------------
vtkIntervalSpan *vtkIntervalSpan::New()
{
    vtkObject* ret = vtkObjectFactory::CreateInstance("vtkIntervalSpan");
    if ( ret ) {
        return ( vtkIntervalSpan* ) ret;
    }

    // If the factory wasn't able to create the vtkIntervalSpan,
    // then create it here.
    return new vtkIntervalSpan;
}




//--------------------------------------------------------------------------------------
vtkIntervalSpan::vtkIntervalSpan ( )
{
    this->unitStart = 0.0;
    this->unitStop = 1.0;
    this->unitSpan = 1.0;
    this->isReference = 0;
    this->referenceSpan = NULL;
}



//--------------------------------------------------------------------------------------
vtkIntervalSpan::vtkIntervalSpan ( float min, float max )
{
    float range;

    range = max-min;
    this->unitStart = min;
    this->unitStop = max;
    this->unitSpan = range;
    this->isReference = 0;
    this->referenceSpan = NULL;
}




//--------------------------------------------------------------------------------------
vtkIntervalSpan::~vtkIntervalSpan ( )
{
    // no data allocated to free... easy cleanup.
}




//--------------------------------------------------------------------------------------
vtkCxxRevisionMacro(vtkIntervalSpan, "$Revision: 1.4 $");





//--------------------------------------------------------------------------------------
void vtkIntervalSpan::PrintSelf(ostream &os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);
}



//--------------------------------------------------------------------------------------
vtkIntervalSpan *vtkIntervalSpan::getReferenceSpan ( )
{
    return this->referenceSpan;
}



//--------------------------------------------------------------------------------------
void vtkIntervalSpan::setReferenceSpan ( vtkIntervalSpan *span)
{
    this->referenceSpan = span;
}




//--------------------------------------------------------------------------------------
vtkIntervalDrop *vtkIntervalSpan::getFirstDropInSpan ( )
{
    return this->firstDrop;
}



//--------------------------------------------------------------------------------------
void vtkIntervalSpan::setFirstDropInSpan ( vtkIntervalDrop *first )
{
    this->firstDrop = first;
}




//--------------------------------------------------------------------------------------
vtkIntervalDrop *vtkIntervalSpan::getLastDropInSpan ()
{
    return this->lastDrop;
}



//--------------------------------------------------------------------------------------
void vtkIntervalSpan::setLastDropInSpan ( vtkIntervalDrop *last )
{
    this->lastDrop = last;
}





//--------------------------------------------------------------------------------------
void vtkIntervalSpan::updateSpan ( )
{
    this->setSpan ( this->unitStart, this->unitStop );
}




//--------------------------------------------------------------------------------------
void vtkIntervalSpan::updateSpan ( float min, float max )
{
    this->setSpan ( min, max );
}




//--------------------------------------------------------------------------------------
void vtkIntervalSpan::setSpan ( float min,  float max )
{
    float wid;

    wid = max-min;
    if (wid < 0.0) wid = -wid;

    this->unitStart = min;
    this->unitStop = max;
    this->unitSpan = wid;
}




//--------------------------------------------------------------------------------------
void vtkIntervalSpan::checkUpdateSpan ( float lowCheck, float hiCheck )
{
    if ( lowCheck < this->unitStart )
        this->unitStart = lowCheck;
    if (hiCheck > this->unitStop )
        this->unitStop = hiCheck;
    this->updateSpan ( );
}



//--------------------------------------------------------------------------------------
void vtkIntervalSpan::shiftSpan ( float shiftAmount )
{
    unitStart = unitStart + shiftAmount;
    unitStop = unitStop + shiftAmount;
    this->updateSpan( );
}


//--------------------------------------------------------------------------------------
void vtkIntervalSpan::scaleSpanAroundCenter ( float scaleAmount )
{
    float centerSpan;
    float half,  transl;
    
    // find span's center.
    centerSpan = ( this->unitStop - this->unitStart ) / 2.0;
    centerSpan = this->unitStart + centerSpan;

    // translate the center to zero.
    transl = centerSpan;
    this->unitStart -= transl;
    this->unitStop -= transl;

    // now scale around that point.
    this->unitSpan = this->unitSpan * scaleAmount;
    half = this->unitSpan / 2.0;

    // and shift back to center position.
    this->unitStart = ( this->unitSpan - half ) + transl;
    this->unitStop = ( this->unitSpan + half ) + transl;
    this->updateSpan();
    
}



//--------------------------------------------------------------------------------------
void vtkIntervalSpan::scaleSpanFromStart ( float scaleAmount )
{

    // keep span's start pinned, and scale.
    this->unitSpan = this->unitSpan * scaleAmount;
    this->unitStop = this->unitStart + this->unitSpan;
    this->updateSpan();
    
}


// Description:
// normalizes span to the range of 0.0 to 1.0, given a span max, min
//--------------------------------------------------------------------------------------
void vtkIntervalSpan::normalizeSpan ( float max, float min )
{
    float range;
    
    range = max-min;
    if ( (this->unitStart < min) || (this->unitStop > max) ) {
        //error
    }
    if ( this->unitSpan > range ) {
        //error
    }
    this->unitStart = this->unitStart/range;
    this->unitStop = this->unitStop/range;
    this->updateSpan();
}








//--------------------------------------------------------------------------------------
float vtkIntervalSpan::getDistanceFromStart ( float index )
{
    float dist;

    dist = index - this->unitStart;
    return dist;
}




//--------------------------------------------------------------------------------------
float vtkIntervalSpan::getDistanceFromStop ( float index )
{
    float dist;

    dist = this->unitStop - index;
    return dist;
    
}



//--------------------------------------------------------------------------------------
float vtkIntervalSpan::getDistanceFromReferenceStart ( float index)
{
    float dist;

    if ( this->referenceSpan == NULL ) {
        fprintf ( stderr, "getDistanceFromReferenceStart: reference is NULL\n");
    }
    dist = index - this->referenceSpan->unitStart;
    return dist;
}



//--------------------------------------------------------------------------------------
float vtkIntervalSpan::getDistanceFromReferenceStop( float index )
{
    float dist;

    if ( referenceSpan == NULL ) {
        fprintf ( stderr, "getDistanceFromReferenceStop: reference is NULL\n");
    }
    dist = this->referenceSpan->unitStop - index;
    return dist;
}






