/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalRenderController.h,v $
  Date:      $Date: 2006/01/06 17:57:51 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtkIntervalRenderController_h
#define __vtkIntervalRenderController_h

#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkIbrowserConfigure.h"

#define JUST_THE_PIX            0
#define RGB_TO_INDEX          1
#define VOLUME                     2
#define SURFACE                   3

class VTK_EXPORT vtkIntervalRenderController : public vtkObject
{
 public:
    static vtkIntervalRenderController *New ( );
    vtkTypeRevisionMacro(vtkIntervalRenderController, vtkObject);
    void PrintSelf (ostream& os, vtkIndent indent);

    // Description:
    // Get/Set information to adjust: the rendered appearance of an interval;
    // the way intervals are combined; and the way drops within the same
    // interval are interpolated.
    vtkSetMacro (RenderMethod, int);
    vtkGetMacro (RenderMethod, int);
    vtkSetMacro (Opacity, float);
    vtkGetMacro (Opacity, float);
    vtkSetMacro (CompositeOperation, int);
    vtkGetMacro (CompositeOperation, int);
    vtkSetMacro (CompositeOrder, int);
    vtkGetMacro (CompositeOrder, int);
    vtkSetMacro (InterpMethod, int);
    vtkGetMacro (InterpMethod, int);
    
    //Description:
    // Methods that set the ways vtkDrops are interpolated, the way
    // data in a vtkInterval is rendered and composited with others'
    virtual void setInterpolationMethod () = 0;  //use specific defs for subclasses
    virtual void setRenderMethod () = 0;          //use specific defs for subclasses
    virtual void setCompositeMethod () = 0;     //use specific defs for subclasses
    virtual int getInterpolationMethod () = 0;    //use specific defs for subclasses
    virtual int getRenderMethod () = 0;            //use specific defs for subclasses 
    virtual int getCompositeMethod () = 0;       //use specific defs for subclasses

 protected:
    vtkIntervalRenderController ();
    ~vtkIntervalRenderController ();
    int InterpMethod;               
    int RenderMethod;
    float Opacity;                           //0= transparent, 1=opaque.
    int CompositeOperation;           //0=background, 1=OR, 2=AND
    int CompositeOrder;                 //0=shown top-most in rendering

 private:

};

#endif
