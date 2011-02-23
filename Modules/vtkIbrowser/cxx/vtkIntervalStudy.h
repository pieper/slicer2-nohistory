/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalStudy.h,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalStudy_h
#define __vtkIntervalStudy_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkInterval.h"
#include "vtkIntervalDrop.h"
#include "vtkIntervalAnimator.h"
#include "vtkIntervalConfig.h"
#include "vtkIntervalSpan.h"
#include "vtkIntervalCollection.h"
#include "vtkIbrowserConfigure.h"



//-------------------------------------------------------------------
// Description:
// A vtkIntervalStudy contains a doubly-linked list of related
// intervals. The collection's GUI representation mediates the
// exploration of data contained within the collection.
// The collection can be named, edited, saved and reloaded.
// Class methods add, delete and manipulate the intervals
// represented within the collection.
//-------------------------------------------------------------------
class VTK_EXPORT vtkIntervalStudy : public vtkObject {
 public:
    static vtkIntervalStudy *New ();
    vtkTypeRevisionMacro(vtkIntervalStudy, vtkObject);
    void PrintSelf (ostream& os, vtkIndent indent);

    //interval collection name and id
    vtkSetStringMacro ( Name );
    vtkGetStringMacro ( Name );
    //Sets the resolution of index
    vtkSetMacro ( zoomfactor, int );
    vtkGetMacro ( zoomfactor, int );

    //Description:
    // Top-level operations for an entire vtkIntervalStudy
    void deleteIntervalStudy ( );
    void zoomInIntervalStudy ( int );
    void zoomOutIntervalStudy ( int );

 protected:
    // A linked list of intervals, each containing data
    vtkIntervalCollection *intervalCollection;
    // the tool that plays the study thru slicer's viewer
    vtkIntervalAnimator *player;
    char *Name;
    int zoomfactor;

    ~vtkIntervalStudy ();
    vtkIntervalStudy ();
    vtkIntervalStudy (int ID);
    vtkIntervalStudy ( float min, float max);
    vtkIntervalStudy (float min, float max, int ID);

 private:
    vtkIntervalStudy(const vtkIntervalStudy&); //Not implemented
    void operator=(const vtkIntervalStudy&);        //Not implemented
};

#endif
