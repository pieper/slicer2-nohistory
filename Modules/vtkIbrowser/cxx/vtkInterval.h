/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkInterval.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkInterval_h
#define __vtkInterval_h


#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkIntervalConfig.h"
#include "vtkIntervalHash.h"
#include "vtkIntervalDropCollection.h"
#include "vtkIntervalSpan.h"
#include "vtkTransform.h"
#include "vtkImageToImageFilter.h"
#include <vtkIbrowserConfigure.h>

//-------------------------------------------------------------------
// Description:
// A vtkInterval is an abstract container for an ordered collection of
// vtkIntervalDrops  in a hash table (vtkIntervalHash), and keyed by
// a user-selected  index. There are different subclasses of vtkInterval.
// Related vtkIntervals are stored together in a vtkIntervalCollection.
//-------------------------------------------------------------------

class VTK_EXPORT vtkInterval : public vtkObject {

 public:

    static vtkInterval *New ();
    vtkTypeRevisionMacro(vtkInterval, vtkObject);
    void PrintSelf (ostream& os, vtkIndent indent);
    
    // vtkGet/Set interval parameters
    vtkSetStringMacro ( name );
    vtkGetStringMacro ( name );
    vtkSetMacro ( IntervalID, int );
    vtkGetMacro ( IntervalID, int );
    vtkSetMacro ( RefID, int );
    vtkGetMacro ( RefID, int );
    vtkSetMacro ( order, int );
    vtkGetMacro ( order, int );    
    vtkGetMacro ( numDrops, int );
    vtkSetMacro ( numDrops, int );
    vtkSetMacro ( isSelected, int );
    vtkGetMacro ( isSelected, int );
    vtkSetMacro ( visibility, int );
    vtkGetMacro ( visibility, int );
    vtkSetMacro ( opacity, float );
    vtkGetMacro ( opacity, float );
    vtkGetMacro ( MRMLid, int);
    vtkSetMacro ( MRMLid, int);
    void setReferenceInterval ( vtkInterval *ref );
    vtkInterval *getReferenceInterval ( );
    void setSampledLinearly ( );
    void setSampledNonlinearly ( );
    void setTransform ( vtkTransform *t );
    vtkTransform *getTransform ( );
    void setGlobalSpan ( vtkIntervalSpan *sp );
    void setGlobalSpan ( float min, float max );
    vtkIntervalSpan *getGlobalSpan ( );

    // edit interval properties
    void editIntervalProperties ( char *newname );
    void editIntervalProperties ( int newVis );
    void editIntervalProperties ( float newOpaq );

    // manipulations of vtkIntervals within the collection
    void normalizeIntervalSpan ( float max, float min );
    void selectInterval ( );
    void deselectInterval ( );
    void toggleVisibility ( );
    void scaleIntervalAroundCenter ( float scaleAmount );
    void scaleIntervalFromStart ( float scaleAmount );
    void shiftInterval ( float shiftAmount );

 protected:
    char *name;
    int MRMLid;
    int IntervalID;
    int RefID;
    int order;
    int isSpelected;
    int visibility;
    float opacity;
    intervalType myIntervalType;
    static vtkIntervalSpan *globalSpan;
    vtkInterval *referenceInterval;
    vtkIntervalDropCollection *dropCollection;
    vtkIntervalSpan *mySpan;
    vtkIntervalHash *dropHash;               
    vtkTransform *myTransform;

    vtkInterval *next;
    vtkInterval *prev;
    
    vtkInterval ( );
    vtkInterval ( char *myname, int type );
    vtkInterval ( char *myname, int type, float max, float min );
    vtkInterval (char *myname, int type, float max, float min, vtkInterval *ref);
    virtual ~vtkInterval ( );

};



#endif
