/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalAnimator.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalAnimator_h
#define __vtkIntervalAnimator_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkIbrowserConfigure.h"

#define ONCE 0
#define LOOP 1
#define PINGPONG 2
#define STEP 3
#define RANDOMLY_INDEX 4
#define PAUSE 5
#define STOP 6

#define FORWARD 1
#define REVERSE 2

//Description:
//A vtkIntervalAnimator consolidates the animation functions
//for the IntervalBrowser. Plays, records and saves animations,
//and keeps track of the state of the controller.

class VTK_EXPORT vtkIntervalAnimator : public vtkObject {
 public:
    vtkTypeRevisionMacro(vtkIntervalAnimator, vtkObject)
    void PrintSelf (ostream &os, vtkIndent indent);

    static vtkIntervalAnimator *New ();

    //Description:
    //These specify controller state
    static int animationMode;
    static int animationDirection;
    static int animationRunning;
    static int animationPaused;

    //Description:
    //These do the animation work
    //void animateSingleFrame ( int index);
    //void animateSingleFrame ( float index);
    //void playAnimation ();
    //void pauseAnimation ();
    //void stopAnimation ();

    //Description:
    //These are effective get&set operations
    int getAnimationMode ( );
    void setAnimationMode ( int );
    int getAnimationDirection ( );
    void setAnimationDirection ( int );
    int getAnimationRunning ( );
    void setAnimationRunning( int );
    int getAnimationPaused ( );
    void setAnimationPaused ( int );
    
 protected:
    ~vtkIntervalAnimator ();
    vtkIntervalAnimator ();

 private:
    vtkIntervalAnimator(const vtkIntervalAnimator&);   //Not implemented.
    void operator=(const vtkIntervalAnimator&);          //Not implemented.
    
};

#endif
