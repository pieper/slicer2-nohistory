/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalHashNode.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalHashNode_h
#define __vtkIntervalHashNode_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkIntervalDrop.h"
#include "vtkIbrowserConfigure.h"

//-------------------------------------------------------------------
// Description:
// A vtkInterval stores an ordered collection of vtkIntervalDrops 
// in a hash table (vtkIntervalHash), and keyed by the start/stop
// endpoints of their vtkSpan. There are different subclasses of
// vtkInterval; and related vtkIntervals are stored together in a
// vtkIntervalCollection.
//-------------------------------------------------------------------

class VTK_EXPORT vtkIntervalHashNode : public vtkObject
{
 public:
    static vtkIntervalHashNode *New ( );
    vtkTypeRevisionMacro (vtkIntervalHashNode, vtkObject );
    void PrintSelf (ostream& os, vtkIndent indent );
    void initNode ( vtkIntervalHashNode *n );    
    void setKeyStart ( float start );
    void setKeyStop ( float stop );

 protected:
    float keyStart;
    float keyStop;
    vtkIntervalDrop *drop;
    vtkIntervalHashNode *next;
    vtkIntervalHashNode *prev;

    vtkIntervalHashNode ( );
    ~vtkIntervalHashNode ( );
};


#endif
