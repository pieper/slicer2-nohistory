/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkROISelectTracts.h,v $
  Date:      $Date: 2006/08/15 16:39:53 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkROISelectTracts - 
// .SECTION Description
//
// Select tractographic paths based on intersection with ROI(s)
//

#ifndef __vtkROISelectTracts_h
#define __vtkROISelectTracts_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"

#include "vtkTransform.h"
#include "vtkDoubleArray.h"
#include "vtkIntArray.h"
#include "vtkShortArray.h"
#include "vtkDoubleArray.h"
#include "vtkCollection.h"
#include "vtkPolyData.h"
#include "vtkImageData.h"
#include "vtkMultipleStreamlineController.h"

class VTK_DTMRI_EXPORT vtkROISelectTracts : public vtkObject
{
 public:
  static vtkROISelectTracts *New();
  vtkTypeMacro(vtkROISelectTracts,vtkObject);

  // Description
  // This transformation relates a point in the Wld coordinate system with
  // a point into the memory array for the ROI. It is used to create a combine
  // transform that is used in the vtkStreemlineConvolve
  // Transformation used in seeding streamlines. 
  vtkSetObjectMacro(ROIWldToIjk, vtkTransform);
  vtkGetObjectMacro(ROIWldToIjk, vtkTransform);
  
  // Description
  // Transformation used in seeding streamline. Relates streamlines points,
  // given in scaled ijk coordinates(origin and spacing) to the world coordinate
  // system (slicer 3D viewer)
  vtkSetObjectMacro(StreamlineWldToScaledIjk, vtkTransform);
  vtkGetObjectMacro(StreamlineWldToScaledIjk, vtkTransform);

  // Description
  // Convolution Kernel that is used to convolve the fiber with when
  // finding the ROIs that the fiber passes through
  vtkSetObjectMacro(ConvolutionKernel, vtkDoubleArray);
  vtkGetObjectMacro(ConvolutionKernel, vtkDoubleArray);

  // Description
  // Get Streamlines as Polylines
  vtkGetObjectMacro(StreamlinesAsPolyLines,vtkPolyData);
   
  // Description
  // Class that controls streamlines creation and display
  void SetStreamlineController(vtkMultipleStreamlineController *controller) {
     StreamlineController = controller;
     Streamlines = controller->GetStreamlines();
     this->Register(controller);
  };
  
  vtkGetObjectMacro(StreamlineController,vtkMultipleStreamlineController);   
     
  // Description
  // Streamlines will be started at locations with this value in the InputROI.
  // The value must be greater than 0. A 0 value is not allowed because it
  // would allow users to accidentally start streamlines outside of their
  // ROI.
  vtkSetClampMacro(InputROIValue, int, 1, VTK_SHORT_MAX);
  vtkGetMacro(InputROIValue, int);

  // Description
  // ROI labels that fibers will pass through (AND operation).
  vtkSetObjectMacro(InputANDROIValues,vtkShortArray);
  vtkGetObjectMacro(InputANDROIValues,vtkShortArray);
  
  // Description
  // ROI labels that fibers will not pass through (NOT operation).
  vtkSetObjectMacro(InputNOTROIValues,vtkShortArray);
  vtkGetObjectMacro(InputNOTROIValues,vtkShortArray);
  
  
  // Description
  // Threshold to pass the test and define that a streamline pass a given
  // set of ROI's define in the ADN list and NOT list.
  vtkSetMacro(PassThreshold,double);
  vtkGetMacro(PassThreshold,double);
  
  // Description
  // Input ROI volume for testing tract/ROI intersection
  vtkSetObjectMacro(InputROI, vtkImageData);
  vtkGetObjectMacro(InputROI, vtkImageData);

    //Description
  // Find the streamlines that pass through the set of ROI values
  // stored in InputMultipleROIValues. This operation is performed
  // by convolving  the streamline with the kernel ConvolutionKernel.
  void FindStreamlinesThatPassThroughROI();
  
  // Description
  // Convert Streamline from Points representation to PolyLines
  void ConvertStreamlinesToPolyLines();
  
  void HighlightStreamlinesPassTest();
  
  void DeleteStreamlinesNotPassTest();
  
  void ResetStreamlinesPassTest();

 protected:
  vtkROISelectTracts();
  ~vtkROISelectTracts();

  vtkMultipleStreamlineController *StreamlineController;
  vtkCollection *Streamlines;

  vtkImageData *InputROI;
  vtkImageData *InputROI2;

  int InputROIValue;
  int InputROI2Value;
 
  vtkTransform *ROIWldToIjk;
  vtkTransform *StreamlineWldToScaledIjk;
  vtkShortArray *InputANDROIValues;
  vtkShortArray *InputNOTROIValues;
  double PassThreshold;
  
  vtkDoubleArray *ConvolutionKernel;
  
  vtkPolyData *StreamlinesAsPolyLines;
  vtkIntArray *StreamlineIdPassTest;
 
  vtkDoubleArray *ColorStreamlines;

};

#endif
