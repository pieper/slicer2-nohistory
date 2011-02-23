/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireTester.h,v $
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkImageLiveWireTester - Wrapper around vtkImageLiveWire
// .SECTION Description
//  This poorly named class handles the multiple edge inputs to 
// vtkImageLiveWire.  It replaces a bit of tcl code and may be
// replaced itself in future...
//

#ifndef __vtkImageLiveWireTester_h
#define __vtkImageLiveWireTester_h

#include "vtkImageToImageFilter.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkImageLiveWireTester : public vtkImageToImageFilter
{
  public:
  static vtkImageLiveWireTester *New();
  vtkTypeMacro(vtkImageLiveWireTester,vtkImageToImageFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // LiveWire object this class makes edges for
  vtkSetObjectMacro(LiveWire, vtkImageLiveWire);
  vtkGetObjectMacro(LiveWire, vtkImageLiveWire);

  // Description:
  // Set up the pipeline (give edge images to LiveWire filter)
  void InitializePipeline();

  // Description:
  // Number of filters for edges (number of directions of edges)
  vtkGetMacro(NumberOfEdgeFilters, int);
  void SetNumberOfEdgeFilters(int number);

  // Description:
  // Array of edge filters.
  vtkImageLiveWireEdgeWeights **GetEdgeFilters(){return this->EdgeFilters;};
  vtkImageLiveWireEdgeWeights *GetEdgeFilter(int i){return this->EdgeFilters[i];};

  // Description:
  // Returns output of one of the edge-producing filters.
  vtkImageData *GetEdgeImage(int filter);
  
  // Description: 
  // The file where all edge filters' settings will be written when using 
  // WriteFeatureSettings.  Use this to save training information.
  vtkSetStringMacro(SettingsFileName);
  vtkGetStringMacro(SettingsFileName);

  // Description: 
  // Write settings of all edge filters to file
  void WriteFilterSettings();

protected:
  vtkImageLiveWireTester();
  ~vtkImageLiveWireTester();

  char *SettingsFileName;

  // Description:
  // object we are creating input (multiple edges) for.
  // this filter's output should also be input to it
  vtkImageLiveWire *LiveWire;

  // Description:
  // Array of filters to find edges in all directions
  vtkImageLiveWireEdgeWeights **EdgeFilters;
  int NumberOfEdgeFilters;

  void Execute(vtkImageData *inData, vtkImageData *outData);

private:
  vtkImageLiveWireTester(const vtkImageLiveWireTester&);
  void operator=(const vtkImageLiveWireTester&);
};

#endif



