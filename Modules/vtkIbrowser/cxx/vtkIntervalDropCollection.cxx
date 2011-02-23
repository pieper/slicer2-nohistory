/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalDropCollection.cxx,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIntervalDropCollection.h"

vtkCxxRevisionMacro(vtkIntervalDropCollection, "$Revision: 1.4 $");

//-------------------------------------------------------------------

vtkIntervalDropCollection *vtkIntervalDropCollection::New ( ) {

    vtkObject *ret = vtkObjectFactory::CreateInstance ( "vtkIntervalDropCollection" );
    if (ret) {
        return ( vtkIntervalDropCollection* ) ret;
    }
    return new vtkIntervalDropCollection;
}



//-------------------------------------------------------------------
vtkIntervalDropCollection::vtkIntervalDropCollection ( ) 
{
    // allocate image data.
    this->drop = vtkIntervalDrop::New ( );
    this->regularDropSpacingFlag = 1;

}



//-------------------------------------------------------------------
vtkIntervalDropCollection::vtkIntervalDropCollection ( vtkTransform& t )
{
    // allocate image data.
    this->drop = vtkIntervalDrop::New ( );
    this->drop->myTransform = &t;
    this->regularDropSpacingFlag = 1;

}


//-------------------------------------------------------------------
vtkIntervalDropCollection::vtkIntervalDropCollection ( vtkIntervalDrop *ref )
{
    // allocate image data.
    this->drop = vtkIntervalDrop::New ( );
    this->drop->myTransform = NULL;
    this->referenceDrop = ref;
    this->regularDropSpacingFlag = 1;

}

//-------------------------------------------------------------------
vtkIntervalDropCollection::~vtkIntervalDropCollection ( )
{
    // delete image data.
    this->drop->Delete ( );

}




// Description:
// addDrop adds an intervalDrop to the end of a list of drops
// within an interval; this routine is meant to be overridden with
// appropriate parameters and return type for each subclass of
// vtkIntervalDrop.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::addDrop( vtkIntervalDrop *drop ) {

    this->droptail->next = drop;
    drop->prev = this->droptail;
    this->droptail = drop;
    drop->setDropType(this->collectionType );
    this->numDrops += 1;
}




// Description:
// deleteDrop removes a drop, corresponding to a specified
// pointer from the interval's list of drops
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::deleteDrop( vtkIntervalDrop *drop ) {

    vtkIntervalDrop *dptr;

    // if target drop is head
    if ( drop == this->drophead ) {
        dptr = drop->next;
        dptr->prev = NULL;
        this->drophead = dptr;
        drop->Delete();
        return;
    }

    // if target drop is tail
    if ( drop == this->droptail ) {
        dptr = drop->prev;
        dptr->next = NULL;
        this->droptail = dptr;
        drop->Delete();
        return;
    }

    // target is in the middle of list
    drop->prev->next = drop->next;
    drop->next->prev = drop->prev;
    drop->Delete();
    this->numDrops -= 1;
}


// Description:
// deleteDrop removes a drop corresponding to a specified IntervalID
// from the interval's list of drops.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::deleteDrop( int id ) {

    vtkIntervalDrop *dptr;
    int tmpID;
    
    // first find drop
    dptr = this->drophead;
    while ( dptr != NULL ) {
        tmpID = dptr->GetDropID ( );
        if ( tmpID == id ) {
            // then delete it.
            deleteDrop ( dptr );
            return;
        }
        dptr = dptr->next;
    }
}




// Description:
// deleteAllDrops removes all drops from an interval, but
// keeps the empty interval in the collection.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::deleteAllDrops() {

    vtkIntervalDrop *killptr, *holdptr;

    killptr = holdptr = this->drophead;
    while ( killptr != NULL ) {
        holdptr = killptr->next;
        killptr->Delete ( );
        killptr = holdptr;
    }
    numDrops = 0;
}




// Description:
// shiftDrops moves a single drop along an interval from 
// its current position bythe specified shiftAmount.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::shiftDrop ( vtkIntervalDrop *d, float shiftAmount ) {
    int dexxer;

    // shift drop
    d->shiftDrop(shiftAmount);

    //update interval's span info
    dexxer = d->GetdropIndex ( );
    this->mySpan->checkUpdateSpan ( dexxer, dexxer );
}





// Description:
// computeDropIndices goes down the list of drops within
// an interval and recomputes their position, based on an
// interval's dropSpacing. This is only appropriate when drops
// are regularly spaced within an interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::computeDropIndices ( ) {

    vtkIntervalDrop *dptr;
    float loc;
    
    // start at drop head.
    dptr = this->drophead;
    loc = this->mySpan->GetunitStart ( );

    // position first drop at beginning of
    // interval's span. Then regularly
    // space all subsequent drops.
    while ( dptr != NULL ) {
        dptr->SetdropPosition ( loc );
        loc = loc + this->dropSpacing;
        dptr = dptr->next;
    }
}




// Description:
// computeDropSpacing sets the vtkIntervalDrop spacing within an
// interval by looking at the positions of the first few drops.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::computeDropSpacing ( ) {

    vtkIntervalDrop *dptr;
    float p1, p2;

    if ( this->regularDropSpacingFlag  && numDrops > 1 ) {
        dptr = this->drophead;
        p1 = dptr->GetdropPosition ( );
        dptr = dptr->next;
        p2 = dptr->GetdropPosition ( );
        this->dropSpacing = (p2-p1);
    }
}




// Description:
// shiftDrops moves all drops along an interval from its
// current position by the specified shiftAmount.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::shiftDrops( float shiftAmount ) {
    vtkIntervalDrop *dptr;

    // shift drops
    dptr = this->drophead;
    while ( dptr != NULL ) {
        dptr->shiftDrop(shiftAmount);
        dptr=dptr->next;
    }

    // update interval's span info
    this->mySpan->shiftSpan (shiftAmount);
    this->mySpan->updateSpan ();
}





// Description:
// insertDropBeforeDrop is a tool for repositioning an existing
// and already extracted drop within an interval. This is only
// appropriate to use when drops are regularly spaced within
// an interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::insertDropBeforeDrop (vtkIntervalDrop *putThis,
                                        vtkIntervalDrop *beforeThis)
{

    if (this->regularDropSpacingFlag == 0 ) {
        fprintf (stderr, "You must reposition drop with a specific index.\n");
        return;
    }
    // if we're inserting at the head of the list
    if ( beforeThis->prev == NULL ) {
        this->drophead = putThis;
        putThis->prev = NULL;
        putThis->next = beforeThis;
        beforeThis->prev = putThis;
    }
    else {
        putThis->prev = beforeThis->prev;
        putThis->next = beforeThis;
        beforeThis->prev->next = putThis;
        beforeThis->prev = putThis;
    }
    // reconfigure drops
    computeDropIndices ( );
}







// Description:
// insertDropAfterDrop is a tool for repositioning an existing
// and already extracted drop within an interval. This is only
// appropriate to use when drops are regularly spaced within
// an interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::insertDropAfterDrop (vtkIntervalDrop *putThis,
                                       vtkIntervalDrop *afterThis )
{
    if (this->regularDropSpacingFlag == 0 ) {
        fprintf (stderr, "In intervals irregularly populated with drops,\n");
        fprintf (stderr, "you must edit the drop's index explicitly.\n");
        return;
    }
    // if we're inserting at the tail of list
    if ( afterThis->next == NULL) {
        putThis->prev = afterThis;
        putThis->next = NULL;
        afterThis->next = putThis;
        this->droptail = putThis;
    }
    else {
        putThis->prev = afterThis;
        putThis->next = afterThis->next;
        afterThis->next->prev = putThis;
        afterThis->next = putThis;
    }
    // reconfigure drops
    computeDropIndices ( );
}






// Description:
// addDropBeforeDrop adds a new drop into the interval
// at the assigned location. This routine assumes that
// drops are evenly spaced within the interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::addDropBeforeDrop ( vtkIntervalDrop *putThis,
                                      vtkIntervalDrop *beforeThis )
{
    // insert a new drop in the interval 
    putThis->setDropType(this->collectionType) ;
    insertDropBeforeDrop ( putThis, beforeThis );
    numDrops += 1;
}






// Description:
// addDropAfterDrop adds a new drop into the interval
// at the assigned location. This routine assumes that
// drops are evenly spaced within the interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::addDropAfterDrop ( vtkIntervalDrop *putThis,
                                     vtkIntervalDrop *afterThis )
{
    // insert a new drop in the interval
    putThis->setDropType (this->collectionType) ;
    insertDropAfterDrop ( putThis, afterThis );
    numDrops += 1;
}




// Description:
// moveDropBeforeDrop is used to extract an existing drop from
// its position within an interval, and to move it to a new location.
// The routine assumes that drops are evenly spaced within an
// interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::moveDropBeforeDrop (vtkIntervalDrop *moveThis,
                                      vtkIntervalDrop *beforeThis )
{
    // extract interval from initial location
    if ( moveThis->prev != NULL )
        moveThis->prev->next = moveThis->next;
    if ( moveThis->next != NULL )
        moveThis->next->prev = moveThis->prev;
    
    // and insert it in a new location
    insertDropBeforeDrop ( moveThis, beforeThis );
}






// Description:
// moveDropAfterDrop is used to extract an existing drop from
// its position within an interval, and to move it to a new location.
// The routine assumes that drops are evenly spaced within an
// interval.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::moveDropAfterDrop (vtkIntervalDrop *moveThis,
                                      vtkIntervalDrop *afterThis )
{
    // extract interval from initial location
    if ( moveThis->prev != NULL )
        moveThis->prev->next = moveThis->next;
    if ( moveThis->next != NULL )
        moveThis->next->prev = moveThis->prev;

    // and insert it in a new location
    insertDropAfterDrop ( moveThis, afterThis );
}






// Description:
// moveDropToHead extracts a drop from its current location
// and moves it to the head of an interval's drop list.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::moveDropToHead ( vtkIntervalDrop *moveThis )
{
    if (this->drophead != NULL )
        moveDropBeforeDrop ( moveThis, this->drophead );
    else
        this->drophead = moveThis;
}





// Description:
// moveDropToTail extracts a drop from its current location
// and moves it to the tail of an interval's drop list.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::moveDropToTail ( vtkIntervalDrop *moveThis )
{
    if ( this->droptail != NULL )
        moveDropAfterDrop ( moveThis, this->droptail );
    else
        this->droptail = moveThis;
}





// Description:
// getDropHead returns the head of an interval's list of drops.
//--------------------------------------------------------------------------------------
vtkIntervalDrop *vtkIntervalDropCollection::getDropHead ( ) {

    return this->drophead;
}




// Description:
// getDropTail returns the tail of an interval's list of drops.
//--------------------------------------------------------------------------------------
vtkIntervalDrop *vtkIntervalDropCollection::getDropTail ( ) {

    return this->droptail;
}




// Description:
// setDropHead sets the head of an interval's list of drops.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::setDropHead ( vtkIntervalDrop *ptr )
{
    this->drophead = ptr;
}





// Description:
// setDropTail sets the tail of an interval's list of drops.
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::setDropTail (vtkIntervalDrop *ptr )
{
    this->droptail = ptr;
}







// Description:
//--------------------------------------------------------------------------------------
vtkIntervalDrop *vtkIntervalDropCollection::getReferenceDrop ( ) {

    return this->referenceDrop;
}


// Description:
//--------------------------------------------------------------------------------------
void vtkIntervalDropCollection::setReferenceDrop ( vtkIntervalDrop *ref)
{
    this->referenceDrop = ref;
}






//-------------------------------------------------------------------
void vtkIntervalDropCollection::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkObject::PrintSelf(os, indent);

       os << indent << "vtkIntervalDropCollection: ";
       os << indent << "number of Drops:" << numDrops << "\n";
       os << indent << "drop spacing:" << dropSpacing << "\n";
       os << indent << "regular spacing flag" << regularDropSpacingFlag << "\n";
       os << indent << "collectionID" << collectionID << "\n";
}
