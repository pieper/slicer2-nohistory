/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkInterval.cxx,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkInterval.h"


vtkCxxRevisionMacro(vtkInterval, "$Revision: 1.4 $");
vtkIntervalSpan *vtkInterval::globalSpan = vtkIntervalSpan::New();

//--------------------------------------------------------------------------------------
vtkInterval *vtkInterval::New ( )
{
    vtkObject* ret = vtkObjectFactory::CreateInstance ( "vtkInterval" );
    if ( ret ) {
        return ( vtkInterval* ) ret;
    }
    return new vtkInterval;
}





//--------------------------------------------------------------------------------------
vtkInterval::vtkInterval ( ) {

    this->name = "defaultNew";
    this->IntervalID = -1;
    this->RefID = -1;
    this->IntervalType = IMAGEINTERVAL;
    this->order = 0;
    this->isSelected = 0;
    this->visibility = 1;
    this->opacity = 1.0;
    this->referenceInterval = NULL;
    this->mySpan = vtkIntervalSpan::New();
    this->myTransform = vtkTransform::New();
    this->dropHash = vtkIntervalHash::New();
    this->dropCollection= vtkIntervalDropCollection::New();
    this->dropCollection->mySpan = this->mySpan;
    this->dropCollection->collectionType = IntervalType;
    this->next = NULL;
    this->prev = NULL;
}





//--------------------------------------------------------------------------------------
vtkInterval::vtkInterval ( char *myname, int type) {

    this->name = myname;
    this->IntervalID = -1;
    this->RefID = -1;
    this->IntervalType = type;
    this->order = 0;
    this->isSelected = 0;
    this->visibility = 1;
    this->opacity = 1.0;
    this->referenceInterval = NULL;
    this->mySpan = vtkIntervalSpan::New();
    this->myTransform = vtkTransform::New();
    this->dropHash = vtkIntervalHash::New();
    this->dropCollection= vtkIntervalDropCollection::New();
    this->dropCollection->mySpan = this->mySpan;
    this->dropCollection->collectionType = IntervalType;
    this->next = NULL;
    this->prev = NULL;
}





//--------------------------------------------------------------------------------------
vtkInterval::vtkInterval ( char *myname, int type, float max, float min ) {

    this->name = myname;
    this->IntervalID = -1;
    this->RefID = -1;
    this->IntervalType = type;
    this->order = 0;
    this->isSelected = 0;
    this->visibility = 1;
    this->opacity = 1.0;
    this->referenceInterval = NULL;
    this->mySpan = vtkIntervalSpan::New();
    this->mySpan->setSpan( min, max );
    this->myTransform = vtkTransform::New();
    this->dropHash = vtkIntervalHash::New();
    this->dropCollection= vtkIntervalDropCollection::New();
    this->dropCollection->mySpan = this->mySpan;
    this->dropCollection->collectionType = IntervalType;
    this->next = NULL;
    this->prev = NULL;
}



//--------------------------------------------------------------------------------------
vtkInterval::vtkInterval (char *myname, int type, float max, float min, vtkInterval *ref) {

    this->name = myname;
    this->IntervalID = -1;
    this->RefID = ref->IntervalID;
    this->IntervalType = type;
    this->order = 0;
    this->isSelected = 0;
    this->visibility = 1;
    this->opacity = 1.0;
    this->referenceInterval = ref;
    this->mySpan = vtkIntervalSpan::New();
    this->mySpan->setSpan( min, max );
    this->myTransform = vtkTransform::New();
    this->dropHash = vtkIntervalHash::New();
    this->dropCollection= vtkIntervalDropCollection::New();
    this->dropCollection->mySpan = this->mySpan;
    this->dropCollection->collectionType = IntervalType;
    this->next = NULL;
    this->prev = NULL;
}


//--------------------------------------------------------------------------------------
vtkInterval::~vtkInterval ( ) {

    this->mySpan->Delete ( );
    this->myTransform->Delete ( );
    this->dropHash->Delete ( );
    this->dropCollection->Delete ( );
}




// Description:
// editInterval allows an interval's name, visibility and opacity
// to be edited.
//--------------------------------------------------------------------------------------
void vtkInterval::editIntervalProperties ( char *newname ) {

    this->name = newname;
}




// Description:
// editInterval allows an interval's name, visibility and opacity
// to be edited.
//--------------------------------------------------------------------------------------
void vtkInterval::editIntervalProperties ( int newvis) {

    this->visibility = newvis;
}





// Description:
// editInterval allows an interval's name, visibility and opacity
// to be edited.
//--------------------------------------------------------------------------------------
void vtkInterval::editIntervalProperties ( float newopaq ) {

    this->opacity = newopaq;
}




// Description:
// shiftInterval translates the interval's span and
// shifts all drops within it. 
//--------------------------------------------------------------------------------------
void vtkInterval::shiftInterval ( float shiftAmount ) {

    // shift all drops.
    this->dropCollection->shiftDrops ( shiftAmount );

}





// Description:
// scaleIntervalAroundCenter scales an interval around its
// center point, changing its start and endpoints.
//--------------------------------------------------------------------------------------
void vtkInterval::scaleIntervalAroundCenter ( float scaleAmount ) {

    this->mySpan->scaleSpanAroundCenter ( scaleAmount);
}




// Description:
// scaleIntervalFromStart pins an interval at its start and
// scales it, changing its endpoint.
//--------------------------------------------------------------------------------------
void vtkInterval::scaleIntervalFromStart( float scaleAmount ) {

    this->mySpan->scaleSpanFromStart ( scaleAmount);
}




// Description:
// normalizeInterval normalizes an interval given a max and min
// which correspond to 0.0 and 1.0.
//--------------------------------------------------------------------------------------
void vtkInterval::normalizeIntervalSpan ( float max, float min ) {

    this->mySpan->normalizeSpan ( max, min );
}





// Description:
// selectInterval marks an interval as selected.
//--------------------------------------------------------------------------------------
void vtkInterval::selectInterval ( ) {

    this->isSelected = 1;
}





// Description:
// deselectInterval marks an interval as deselected.
//--------------------------------------------------------------------------------------
void vtkInterval::deselectInterval ( ) {

    this->isSelected = 0;
}




// Description:
// toggleVisibility changes an interval's visibility, from
// either visible or invisible.
//--------------------------------------------------------------------------------------
void vtkInterval::toggleVisibility ( ) {

    if ( this->visibility = 0 )
        this->visibility = 1;
    else this->visibility = 0;
}




// Description:
// setSampledNonlinearly marks an interval as having
// irregularly spaced drops.
//--------------------------------------------------------------------------------------
void vtkInterval::setSampledNonlinearly ( ) {
    this->dropCollection->regularDropSpacingFlag = 0;
}




// Description:
// setSampledLinearly marks an interval as having
// regularly spaced drops.
//--------------------------------------------------------------------------------------
void vtkInterval::setSampledLinearly ( ) {
    this->dropCollection->regularDropSpacingFlag = 1;
}








// Description:
// setReferenceInterval sets a pointer to
// the interval it references for transformations.
//--------------------------------------------------------------------------------------
void vtkInterval::setReferenceInterval ( vtkInterval *ref ) {

    this->referenceInterval = ref;
}



// Description:
//--------------------------------------------------------------------------------------
vtkInterval *vtkInterval::getReferenceInterval ( ){
    return this->referenceInterval;
}


// Description:
//--------------------------------------------------------------------------------------
void vtkInterval::setGlobalSpan ( vtkIntervalSpan *sp ) {
float start, stop;
    start = sp->GetunitStart ( );
    stop = sp->GetunitStop ( );
    this->globalSpan->updateSpan ( start, stop );
}



// Description:
//--------------------------------------------------------------------------------------
void vtkInterval::setGlobalSpan (float min, float max ) {

    this->globalSpan->updateSpan ( min, max );
}


// Description:
//--------------------------------------------------------------------------------------
vtkIntervalSpan *vtkInterval::getGlobalSpan () {

    return this->globalSpan;
}



// Description:
//--------------------------------------------------------------------------------------
void vtkInterval::setSpan (float min, float max){

    this->mySpan->updateSpan( min, max);

}

// Description:
//--------------------------------------------------------------------------------------
vtkIntervalSpan *vtkInterval::getSpan ( ){

    return this->mySpan;
}


// Description:
//--------------------------------------------------------------------------------------
void vtkInterval::setTransform ( vtkTransform *t )
{
 this->myTransform = t;
}




// Description:
//--------------------------------------------------------------------------------------
vtkTransform *vtkInterval::getTransform ( )
{
    return this->myTransform;
}




//Description:
//--------------------------------------------------------------------------------------
void vtkInterval::PrintSelf(ostream &os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);
}








