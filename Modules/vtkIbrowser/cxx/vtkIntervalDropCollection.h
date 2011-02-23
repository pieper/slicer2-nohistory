/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalDropCollection.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalDropCollection_h
#define __vtkIntervalDropCollection_h

#include "vtkIntervalSpan.h"
#include "vtkIntervalDrop.h"
#include "vtkIntervalConfig.h"


//-------------------------------------------------------------------
// Description:
// A vtkIntervalDropCollection is a linked list of
// vtkIntervalDrops.
//-------------------------------------------------------------------
class VTK_EXPORT vtkIntervalDropCollection : public vtkObject{

 public:
    static vtkIntervalDropCollection *New();        
    void PrintSelf (ostream& os, vtkIndent indent );
    vtkTypeRevisionMacro (vtkIntervalDropCollection, vtkObject );

    vtkSetMacro (numDrops, int);
    vtkGetMacro (numDrops, int);
    vtkSetMacro (collectionID, int);
    vtkGetMacro (collectionID, int);
    vtkSetMacro ( dropSpacing, float );
    vtkGetMacro ( dropSpacing, float );

    // access functions
    vtkIntervalDrop *getDropHead ();
    vtkIntervalDrop *getDropTail ();
    void setDropHead (vtkIntervalDrop *d);
    void setDropTail (vtkIntervalDrop *d);
    vtkIntervalDrop *getReferenceDrop ( );
    void setReferenceDrop ( vtkIntervalDrop *ref);
    void shiftDrop ( vtkIntervalDrop *d, float shiftAmount );
    void shiftDrops ( float shiftAmount );
    // compute things about vtkIntervalDrops
    void computeDropSpacing ( );
    void computeDropIndices ( );

    // add and delete and manipulate vtkIntervalDrops in list.
    void addDrop ( vtkIntervalDrop *drop);
    void deleteDrop ( vtkIntervalDrop *drop);
    void deleteDrop (  int id );
    void deleteAllDrops ( );
    void insertDropBeforeDrop (vtkIntervalDrop *putThis, vtkIntervalDrop *beforeThis );
    void insertDropAfterDrop (vtkIntervalDrop *putThis, vtkIntervalDrop *afterThis );
    void addDropBeforeDrop (vtkIntervalDrop *putThis, vtkIntervalDrop *beforeThis );
    void addDropAfterDrop (vtkIntervalDrop *putThis, vtkIntervalDrop *beforeThis );
    void moveDropBeforeDrop ( vtkIntervalDrop *moveThis, vtkIntervalDrop *beforeThis );
    void moveDropAfterDrop ( vtkIntervalDrop *moveThis, vtkIntervalDrop *afterThis );
    void moveDropToHead ( vtkIntervalDrop *moveThis );
    void moveDropToTail ( vtkIntervalDrop *moveThis );

    int numDrops;
    float dropSpacing;
    int regularDropSpacingFlag;
    int collectionID;
    
    vtkIntervalDrop *drop;
    vtkIntervalDrop *drophead;
    vtkIntervalDrop *droptail;
    vtkIntervalDrop *activeDrop;
    vtkIntervalDrop *referenceDrop;
    int collectionType;
    vtkIntervalSpan *mySpan;

 protected:
    vtkIntervalDropCollection ( );
    vtkIntervalDropCollection ( vtkTransform& t);
    vtkIntervalDropCollection ( vtkIntervalDrop *ref );
    ~vtkIntervalDropCollection ( );
        
 private:
};

#endif
