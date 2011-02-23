/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalCollection.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalCollection_h
#define __vtkIntervalCollection_h

#include "vtkInterval.h"


//-------------------------------------------------------------------
// Description:
// A vtkIntervalCollection is a linked list of
// vtkIntervals.
//-------------------------------------------------------------------
class VTK_EXPORT vtkIntervalCollection : public vtkObject{

 public:
    static vtkIntervalCollection *New();        
    void PrintSelf (ostream& os, vtkIndent indent );
    vtkTypeRevisionMacro (vtkIntervalCollection, vtkObject );

    vtkGetMacro (CollectionID, int);
    vtkSetMacro (CollectionID, int);

    vtkGetMacro ( numIntervals, int );
    vtkSetMacro ( numIntervals, int  );

    //The interval variable that indexes all.
    vtkSetMacro ( index, float );
    vtkGetMacro ( index, float );    

    //Find an interval in the collection
    vtkInterval *getIntervalByName ( char *ivalname );
    vtkInterval *getIntervalByID ( int intervalID );     

    //Get/Set head, tail, reference intervals
    vtkInterval *getIntervalHead ( );
    void setIntervalHead ( vtkInterval *h );
    vtkInterval *getIntervalTail ( );
    void setIntervalTail ( vtkInterval *t );
    vtkInterval *getReferenceInterval ( );
    void setReferenceInterval ( vtkInterval *ref );

    //Get/Set global span
    vtkIntervalSpan *getGlobalSpan ( );
    void setGlobalSpan ( float min, float max );
    void setGlobalSpan ( vtkIntervalSpan *sp );
    void updateGlobalSpan ( );

    //Add, delete, select, manipulate intervals
    void addInterval ( vtkInterval *addme , int type );
    void addInterval (vtkInterval *addme, char *name, int type);
    void addInterval (vtkInterval *addme, char *name, int type, float min, float max);
    vtkInterval *addInterval ( char *myname, int type, float max, float min);
    void deleteInterval ( vtkInterval *killme );
    void deleteAllIntervals ( );
    void selectInterval ( char *myname );
    void selectInterval ( vtkInterval *i );
    vtkInterval *getSelectedInterval ( );
    void deselectInterval (char *myname );
    void deselectInterval ( vtkInterval *i );
    void addNewIntervalBeforeInterval ( vtkInterval *addThis, vtkInterval *beforeThis );
    void addNewIntervalAfterInterval ( vtkInterval *addThis, vtkInterval *afterThis );
    void moveIntervalBeforeInterval ( vtkInterval *moveThis, vtkInterval *beforeThis );
    void moveIntervalAfterInterval ( vtkInterval *moveThis, vtkInterval *afterThis );
    void moveIntervalToHead ( vtkInterval *moveThis );
    void moveIntervalToTail ( vtkInterval *moveThis );
    void insertIntervalBeforeInterval (vtkInterval *addThis, vtkInterval *beforeThis );
    void insertIntervalAfterInterval (vtkInterval *addThis, vtkInterval *afterThis );
    void reOrderIntervals ( );
    void orderSortIntervals ( );
    void shiftInterval ( vtkInterval *iptr, float shiftAmount  );
    void shiftIntervalDrops ( vtkInterval *iptr, float shiftAmount );
    void shiftIntervalDrop ( vtkIntervalDrop *dptr, float shiftAmount );

    vtkInterval *interval;
    
    vtkInterval *intervaltail;
    vtkInterval *intervalhead;
    vtkInterval *selectedInterval;

    //interval to which others are registered
    vtkInterval *referenceInterval; 
    vtkIntervalSpan *globalSpan;
    int CollectionID;
    int numIntervals;
    // index that probes the collection
    float index;
    
 protected:
    vtkIntervalCollection ( );
    vtkIntervalCollection (int ID);
    vtkIntervalCollection (float min, float max);
    vtkIntervalCollection (float min, float max, int ID);
    ~vtkIntervalCollection ( );
        
 private:
};

#endif
