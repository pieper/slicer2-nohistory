/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalCollection.cxx,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIntervalCollection.h"

vtkCxxRevisionMacro(vtkIntervalCollection, "$Revision: 1.4 $");

//-------------------------------------------------------------------

vtkIntervalCollection *vtkIntervalCollection::New ( ) {

    vtkObject *ret = vtkObjectFactory::CreateInstance ( "vtkIntervalCollection" );
    if (ret) {
        return ( vtkIntervalCollection* ) ret;
    }
    return new vtkIntervalCollection;
}



//-------------------------------------------------------------------
vtkIntervalCollection::vtkIntervalCollection ( ) 
{
    this->index = 0.0;
    this->numIntervals = 0;
    this->CollectionID = -1;
    this->intervalhead = NULL;
    this->intervaltail = NULL;
    this->selectedInterval = NULL;
    this->referenceInterval = NULL;    
    this->globalSpan = vtkIntervalSpan::New();
    this->interval = NULL;
}



//-------------------------------------------------------------------
vtkIntervalCollection::vtkIntervalCollection ( int ID ) 
{
    this->index = 0.0;
    this->numIntervals = 0;
    this->CollectionID = ID;
    this->intervalhead = NULL;
    this->intervaltail = NULL;
    this->selectedInterval = NULL;
    this->referenceInterval = NULL;    
    this->globalSpan = vtkIntervalSpan::New();
    this->interval = NULL;
}



//-------------------------------------------------------------------
vtkIntervalCollection::vtkIntervalCollection (float min, float max ) 
{
    this->index = 0.0;
    this->numIntervals = 0;
    this->CollectionID = -1;
    this->intervalhead = NULL;
    this->intervaltail = NULL;
    this->selectedInterval = NULL;
    this->referenceInterval = NULL;    
    this->globalSpan = vtkIntervalSpan::New();
    this->globalSpan->setSpan(min, max);
    this->interval = NULL;
}


//-------------------------------------------------------------------
vtkIntervalCollection::vtkIntervalCollection (float min , float max, int ID ) 
{
    this->index = 0.0;
    this->numIntervals = 0;
    this->CollectionID = ID;
    this->intervalhead = NULL;
    this->intervaltail = NULL;
    this->selectedInterval = NULL;
    this->referenceInterval = NULL;    
    this->globalSpan = vtkIntervalSpan::New();
    this->globalSpan->setSpan(min, max);
    this->interval = NULL;
}



//-------------------------------------------------------------------
vtkIntervalCollection::~vtkIntervalCollection ( )
{
    this->interval->Delete ( );
}



//-------------------------------------------------------------------
void vtkIntervalCollection::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);
}





//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getIntervalByName ( char *ivalname ) {

    vtkInterval *iptr;

    for ( iptr = this->intervalhead; iptr != NULL; iptr = iptr->next ) {
        if (  (strcmp (iptr->Getname( ), ivalname )) == 0 )
            return iptr;
    }
    fprintf ( stderr, "getIntervalByname: no interval found with name %s.\n", ivalname);
    return NULL;
}





//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getIntervalByID ( int ID ) {

    vtkInterval *iptr;

    for ( iptr = this->intervalhead; iptr != NULL; iptr = iptr->next ) {
        if ( iptr->GetIntervalID( ) == ID )
            return iptr;
    }
    fprintf ( stderr, "getIntervalByID: no interval found with IntervalID=%d\n", ID );
    return NULL;
}


//here



//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getIntervalHead ( ) {

    return this->intervalhead;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::setIntervalHead ( vtkInterval *h ) {

    this->intervalhead = h;
}




//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getIntervalTail ( ) {

    return this->intervaltail;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::setIntervalTail ( vtkInterval *t ) {

    this->intervaltail = t;
}







//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getReferenceInterval ( ) {
    
    return this->referenceInterval;
}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::setReferenceInterval ( vtkInterval *ref ) {

    vtkInterval *iptr;

    // set collection reference interval pointer.
    this->referenceInterval = ref;

    // set each interval's reference pointer
    // to point to the designated interval
    iptr=this->intervalhead;
    while (iptr != NULL) {
        iptr->setReferenceInterval ( ref );
        iptr=iptr->next;
    }
}





//--------------------------------------------------------------------------------------
vtkIntervalSpan *vtkIntervalCollection::getGlobalSpan ( ) {

    return this->globalSpan;
}



//--------------------------------------------------------------------------------------
void vtkIntervalCollection::setGlobalSpan ( float min, float max ) {

    vtkInterval *iptr;

    //set collection's global span
    this->globalSpan->updateSpan ( min, max );

    // set same in each interval
    iptr = this->intervalhead;
    while (iptr != NULL) {
        iptr->setGlobalSpan ( min, max );
        iptr=iptr->next;
    }

}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::setGlobalSpan (vtkIntervalSpan *sp ) {
    float unitstart, unitstop;

    //set collection's global span
    unitstart = sp->GetunitStart ( );
    unitstop = sp->GetunitStop ( );
    this->globalSpan->updateSpan ( unitstart, unitstop );

    
}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::addInterval ( vtkInterval *addme, int type ) {


    // if this is the first interval in the collection
    if (this->intervalhead == NULL) {
        this->interval = addme;
        this->intervalhead = this->interval;
        this->intervaltail = this->interval;
    }
    else {
        this->intervaltail->next = addme;
        addme->prev = this->intervaltail;
        this->intervaltail = addme;
    }
    this->numIntervals += 1;
    addme->Setorder(numIntervals);
    addme->SetIntervalType (type);
}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::addInterval ( vtkInterval *addme, char *name, int type) {

    addme->Setname(name);
    // if this is the first interval in the collection
    if (this->intervalhead == NULL) {
        this->interval = addme;
        this->intervalhead = this->interval;
        this->intervaltail = this->interval;
    }
    else {
        this->intervaltail->next = addme;
        addme->prev = this->intervaltail;
        this->intervaltail = addme;
    }
    this->numIntervals += 1;
    addme->Setorder(numIntervals);
    //default...
    addme->SetIntervalType(type);
}


//--------------------------------------------------------------------------------------
void vtkIntervalCollection::addInterval ( vtkInterval *addme, char *name, int type, float min, float max) {

    addme->Setname(name);
    // if this is the first interval in the collection
    if (this->intervalhead == NULL) {
        this->interval = addme;
        this->intervalhead = this->interval;
        this->intervaltail = this->interval;
    }
    else {
        this->intervaltail->next = addme;
        addme->prev = this->intervaltail;
        this->intervaltail = addme;
    }
    this->numIntervals += 1;
    addme->Setorder(numIntervals);
    addme->setSpan(min, max);
    addme->SetIntervalType(type);
}



//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::addInterval (  char *myname, int type, float min, float max) {
    vtkInterval *addme;

    //if this is the first interval in the collection
    if (this->intervalhead == NULL) {
        this->interval = vtkInterval::New ( );
        this->intervalhead = this->interval;
        this->intervaltail = this->interval;
    }
    else {
        addme = vtkInterval::New ( );
        this->intervaltail->next = addme;
        addme->prev = this->intervaltail;
        this->intervaltail = addme;
    }
    this->numIntervals += 1;
    addme->Setname ( myname);
    addme->setSpan(min, max);
    addme->Setorder(numIntervals);
    addme->SetIntervalType(type);
    return addme;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::deleteInterval ( vtkInterval *killme ) {

    vtkInterval *iptr;

    for ( iptr = this->intervalhead; iptr != NULL; iptr = iptr->next ) {
        if ( iptr == killme ) {
            //re-wire
            iptr->prev->next = iptr->next;
            iptr->next->prev = iptr->prev;
            //clean up
            killme->Delete();
            return;
        }
    }
    numIntervals -= 1;
    this->reOrderIntervals ( );
}



//--------------------------------------------------------------------------------------
void vtkIntervalCollection::deleteAllIntervals ( ) {

    vtkInterval *killptr, *holdptr;

    // delete the list...
    killptr = holdptr = this->intervalhead;
    while ( killptr != NULL ) {
        holdptr = killptr->next;
        killptr->Delete();
        killptr = holdptr;
    }
    numIntervals = 0;
    return;

}


// Description:
// selectInterval marks the interval as selected, and also
// sets a collection pointer "selectedInterval" to the selected interval.
//--------------------------------------------------------------------------------------
void vtkIntervalCollection::selectInterval ( vtkInterval *iptr ) {

    iptr->selectInterval ( );
    this->selectedInterval = iptr;
}




// Description:
// selectInterval marks the interval as selected, and also
// sets a collection pointer "selectedInterval" to the selected interval.
//--------------------------------------------------------------------------------------
void vtkIntervalCollection::selectInterval (char *myname ) {

    vtkInterval *iptr;
    iptr = getIntervalByName ( myname );
    if ( iptr == NULL ) {
        fprintf ( stderr, "No interval named: %s\n", myname);
        return;
    }
    iptr->selectInterval ( );
    this->selectedInterval = iptr;
}



// Description:
// deselectInterval marks the interval as not selected, and also
// sets the collection "selectedInterval" pointer to NULL.
//--------------------------------------------------------------------------------------
void vtkIntervalCollection::deselectInterval ( vtkInterval *iptr ) {

    iptr->deselectInterval ( );
    this->selectedInterval = NULL;
}



// Description:
// deselectInterval marks the interval as not selected, and also
// sets the collection "selectedInterval" pointer to NULL.
//--------------------------------------------------------------------------------------
void vtkIntervalCollection::deselectInterval ( char *myname ) {

    vtkInterval *iptr;
    iptr = getIntervalByName ( myname );
    if ( iptr == NULL ) {
        fprintf ( stderr, "No interval named: %s\n", myname);
        return;
    }
    iptr->deselectInterval ( );
    this->selectedInterval = NULL;
        
}




// Description:
// getSelectedInterval returns the collection's user-selected
// interval, or the NULL pointer if nothing is selected.
//--------------------------------------------------------------------------------------
vtkInterval *vtkIntervalCollection::getSelectedInterval ( ) {

    return this->selectedInterval;
}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::insertIntervalBeforeInterval (vtkInterval *addThis,
                                                          vtkInterval *beforeThis ) {
    // if we're adding at the head of list
    if ( beforeThis->prev == NULL ) {
        this->intervalhead = addThis;
        addThis->prev = NULL;
        addThis->next = beforeThis;
        beforeThis->prev = addThis;
    }
    else {
        addThis->prev = beforeThis->prev;
        addThis->next = beforeThis;
        beforeThis->prev->next = addThis;
        beforeThis->prev = addThis;
    }
    this->reOrderIntervals ( );
    return;
}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::insertIntervalAfterInterval (vtkInterval *addThis,
                                                         vtkInterval *afterThis ) {
    // if we're adding at the tail of list
    if ( afterThis->next == NULL ) {
        addThis->prev = afterThis;
        addThis->next = NULL;
        afterThis->next = addThis;
        this->intervaltail = addThis;
    }
    else {
        addThis->prev = afterThis;
        addThis->next = afterThis->next;
        afterThis->next->prev = addThis;
        afterThis->next = addThis;
    }
    this->reOrderIntervals ( );
    return;

}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::addNewIntervalBeforeInterval ( vtkInterval *addThis,
                                                        vtkInterval *beforeThis ) {

    insertIntervalBeforeInterval ( addThis, beforeThis );
    numIntervals += 1;
    return;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::addNewIntervalAfterInterval ( vtkInterval *addThis,
                                                       vtkInterval *afterThis ) {

    insertIntervalAfterInterval ( addThis, afterThis );
    numIntervals += 1;
    return;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::moveIntervalBeforeInterval ( vtkInterval *moveThis,
                                                        vtkInterval *beforeThis ) {

    // extract interval from initial location
    if ( moveThis->prev != NULL )
        moveThis->prev->next = moveThis->next;
    if ( moveThis->next != NULL )
        moveThis->next->prev = moveThis->prev;
    
    // and insert it in new location
    insertIntervalBeforeInterval ( moveThis, beforeThis );
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::moveIntervalAfterInterval ( vtkInterval *moveThis,
                                                       vtkInterval *afterThis ) {

    // extract interval from initial location
    if ( moveThis->prev != NULL )
        moveThis->prev->next = moveThis->next;
    if ( moveThis->next != NULL )
        moveThis->next->prev = moveThis->prev;

    // and insert in new location
    insertIntervalAfterInterval ( moveThis, afterThis );

}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::moveIntervalToHead ( vtkInterval *moveThis )
{
    if ( this->intervalhead != NULL )
        moveIntervalBeforeInterval ( moveThis, this->intervalhead );
    else 
        this->intervalhead = moveThis;

}





//--------------------------------------------------------------------------------------
void vtkIntervalCollection::moveIntervalToTail ( vtkInterval *moveThis )
{
    if (this->intervaltail != NULL )
        moveIntervalAfterInterval ( moveThis, this->intervaltail );
    else
        this->intervaltail = moveThis;
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::reOrderIntervals ( ) {

    vtkInterval *iptr;
    int order = 1;

    for ( iptr = this->intervalhead; iptr != NULL; iptr = iptr->next ) {
        iptr->Setorder(order);
        order++;
    }

}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::orderSortIntervals ( ) {

    vtkInterval *iptrA, *iptrB;
    int doAgain = 1;
    int oA;
    int oB;

    while ( doAgain ) {
        // set flag to stop;
        doAgain = 0;
        // compare values (stupid bubble sort)
        iptrA = this->intervalhead;
        iptrB = iptrA->next;
        while ( iptrB != NULL ) {
            oA = iptrA->Getorder();
            oB = iptrB->Getorder();
            if ( oA > oB ) {
                // reassign head/tail
                if ( iptrA == this->intervalhead ) this->intervalhead = iptrB;
                if ( iptrB == this->intervaltail )    this->intervaltail = iptrA;
                // exchange links
                iptrA->next = iptrB->next;
                iptrA->prev = iptrB;
                iptrB->next = iptrA;
                iptrB->prev = iptrA->prev;
                // set flag to go again
                doAgain = 1;
                // reassign pointers for next pass
                iptrB = iptrA->next;
            }
            else {
                // reassign pointers for next pass
                iptrA = iptrB;
                iptrB = iptrB->next;
            }
        }
    }
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::shiftInterval ( vtkInterval *iptr, float shiftAmount ){
    
    iptr->shiftInterval ( shiftAmount );
    updateGlobalSpan ( );
}




//--------------------------------------------------------------------------------------
void vtkIntervalCollection::shiftIntervalDrops ( vtkInterval *iptr, float shiftAmount ){

    iptr->shiftInterval ( shiftAmount );
    updateGlobalSpan ( );
}



//--------------------------------------------------------------------------------------
void vtkIntervalCollection::shiftIntervalDrop ( vtkIntervalDrop *dptr, float shiftAmount )
{
    dptr->shiftDrop ( shiftAmount );
    updateGlobalSpan ( );
}




// Description:
// updateGlobalSpan goes through all the intervals in a collection
// and finds the smallest span that will encompass all of their data.
// A collection's globalSpan is set with those min, max and span
// values, and each collection interval's global span is updated too.
//--------------------------------------------------------------------------------------
void vtkIntervalCollection::updateGlobalSpan ( ) {

    vtkInterval *iptr;
    float start1, start2;
    float stop1, stop2;
    vtkIntervalSpan *span;

    // examine the span of each interval in the collection
    // and update the global span to fit if necessary.
    iptr = this->intervalhead;
    while ( iptr != NULL ) {
        span = iptr->getSpan();
        start1 = span->GetunitStart( );
        start2 = this->globalSpan->GetunitStart( );
        if ( start1 < start2 )
        this->globalSpan->SetunitStart ( start1);
        stop1 = span->GetunitStop( );
        stop2 = this->globalSpan->GetunitStop( );
        if ( stop1 > stop2 )
        this->globalSpan->SetunitStop ( stop1 );
    }
    this->globalSpan->updateSpan ();

    // update all the colllection's intervals' global spans too
    iptr = this->intervalhead;
    while ( iptr != NULL ) {
        start1 = this->globalSpan->GetunitStart ( );
        stop1 = this->globalSpan->GetunitStop ( );
        iptr->setGlobalSpan ( start1, stop1);
        iptr = iptr->next;
    }
    
}


