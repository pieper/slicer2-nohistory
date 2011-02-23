/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalSpan.h,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalSpan_h
#define __vtkIntervalSpan_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkIntervalDrop.h"
#include <vtkIbrowserConfigure.h>

//--------------------------------------------------------------------------------------
// Description:
// In the IntervalBrowser, most objects have a span.
// vtkIntervalCollections have a vtkIntervalSpan: this describes
// the global span of the study, includes the global start,
// stop and duration.
//--------------------------------------------------------------------------------------
class VTK_EXPORT vtkIntervalSpan : public vtkObject {
 public:
    static vtkIntervalSpan *New ();
    vtkTypeRevisionMacro ( vtkIntervalSpan, vtkObject );
    void PrintSelf ( ostream& os, vtkIndent indent );

    vtkIntervalSpan *getReferenceSpan( );
    vtkIntervalDrop *getFirstDropInSpan ( );
    vtkIntervalDrop *getLastDropInSpan ( );
    void setReferenceSpan ( vtkIntervalSpan *ref );
    void setFirstDropInSpan ( vtkIntervalDrop  *first );
    void setLastDropInSpan ( vtkIntervalDrop *last );
    
    void updateSpan ( );
    void updateSpan ( float min, float max );
    void setSpan ( float min, float max );
    void checkUpdateSpan ( float locheck, float hicheck );
    void shiftSpan ( float shiftAmount );
    void scaleSpanAroundCenter ( float scaleAmount );
    void scaleSpanFromStart( float scaleAmount );
    void normalizeSpan ( float max, float min );
    float getDistanceFromStart ( float index );
    float getDistanceFromStop ( float index );
    float getDistanceFromReferenceStart ( float index );
    float getDistanceFromReferenceStop (float index);

    vtkSetMacro ( unitStart, float ) ;
    vtkGetMacro ( unitStart, float );
    vtkSetMacro ( unitStop, float );
    vtkGetMacro ( unitStop, float );
    vtkSetMacro ( unitSpan, float );
    vtkGetMacro ( unitSpan, float );
    vtkSetMacro ( isReference, int );
    vtkGetMacro ( isReference, int );
    
 protected:
    float unitStart;
    float unitStop;
    float unitSpan;
    vtkIntervalDrop *firstDrop;
    vtkIntervalDrop *lastDrop;
    vtkIntervalSpan *referenceSpan;
    int isReference;

    vtkIntervalSpan ( );
    vtkIntervalSpan ( float min, float max );
    ~vtkIntervalSpan ( );
    
 private:
    vtkIntervalSpan(const vtkIntervalSpan&);
    void operator=(const vtkIntervalSpan&);


};

#endif
