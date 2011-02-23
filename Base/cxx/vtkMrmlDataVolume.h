/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolume.h,v $
  Date:      $Date: 2006/07/27 16:01:01 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkMrmlDataVolume - Object used in the slicer to perform
// everything related to the access and display of image data (volumes).
// .SECTION Description
// Used in conjunction with a vtkMrmlDataVolumeNode (which neatly describes
// display settings, file locations, etc.).  Essentially, the MRML 
// node gives the high level description of what this class should 
// actually do with the ImageData.
// 

#ifndef __vtkMrmlDataVolume_h
#define __vtkMrmlDataVolume_h

//#include <fstream.h>
#include <stdlib.h>
//#include <iostream.h>

#include "vtkMrmlData.h"

#include "vtkMrmlVolumeNode.h"
#include "vtkImageAccumulateDiscrete.h"
#include "vtkImageBimodalAnalysis.h"
#include "vtkImageResize.h"
#include "vtkImagePlot.h"
#include "vtkImageData.h"
#include "vtkStackOfPolygons.h"
#include "vtkSlicer.h"
#include "vtkMrmlDataVolumeReadWrite.h"
#include "vtkPTSWriter.h"

class vtkImageDICOMReader;
class vtkImageReader;

//----------------------------------------------------------------------------
class VTK_SLICER_BASE_EXPORT vtkMrmlDataVolume : public vtkMrmlData
{
public:
  static vtkMrmlDataVolume *New();
  vtkTypeMacro(vtkMrmlDataVolume,vtkMrmlData);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Provides opportunity to insure internal consistency before access. 
  // Transfers all ivars from MrmlNode to internal VTK objects
  // Also causes ImageData's source (if any) to update itself.
  void Update();
  unsigned long int GetMTime();

  // Description:
  // Set the image data
  // Use GetOutput to get the image data.
  vtkSetObjectMacro(ImageData, vtkImageData);
  vtkImageData* GetOutput();
  const char* GetOutputPointer(int zslice);

  // Description:
  // Read/Write image 
  int Read();
  int Write();
  int WritePTS(char *filename);
  int WritePTSFromStack(int window, char *filename,
                        vtkMatrix4x4 *RasToIjkMatrix,
                        char *order, int activeSlice);

  //--------------------------------------------------------------------------
  // Read/Write volume data contained by this object.
  // This sub-object is specific to each
  // type of volume that needs to be read in.  This can be used
  // to clean up the special cases which handle
  // volumes of various types, such as dicom, header, etc.  In
  // future these things can be moved here.  Each read/write 
  // sub-object corresponds to a vtkMrmlVolumeReadWriteNode subclass.
  // These subclasses write any needed info in the MRML file.
  //--------------------------------------------------------------------------
  vtkSetObjectMacro(ReadWrite,vtkMrmlDataVolumeReadWrite);
  vtkGetObjectMacro(ReadWrite,vtkMrmlDataVolumeReadWrite);

  // Description:
  // Set Histogram attributes
  void SetHistogramHeight(int h) {this->HistPlot->SetHeight(h);};
  void SetHistogramWidth(int w);
  vtkSetVector3Macro(HistogramColor, vtkFloatingPointType);

  // Description:
  // Get Histogram plot (an image)
  vtkImageData *GetHistogramPlot();

  int GetBimodalThreshold() {return this->Bimodal->GetThreshold();};
  
  // Description:
  // Assumes GetHistogramPlot has already been called
  int MapBinToScalar(int b) {return this->HistPlot->MapBinToScalar(b);};
  int MapScalarToBin(int s) {return this->HistPlot->MapScalarToBin(s);};
  
  // Description:
  // Set/Get window/level/threshold slider range
  vtkGetMacro(RangeLow,  vtkFloatingPointType);
  vtkGetMacro(RangeHigh, vtkFloatingPointType);
  vtkSetMacro(RangeLow,  vtkFloatingPointType);
  vtkSetMacro(RangeHigh, vtkFloatingPointType);
  vtkGetMacro(RangeAuto, int);
  vtkSetMacro(RangeAuto, int);
  vtkBooleanMacro(RangeAuto, int);

    vtkImageAccumulateDiscrete *GetAccumulate() { return this->Accumulate;};
    vtkImageBimodalAnalysis *GetBimodal() { return this->Bimodal;};
    
  void StackSetPolygon(int window, vtkPoints *poly, int s, int p, int d,
                       int closed, int preshape, int label)
  {
    switch (window)
    {
      case 0: this->AxiPolyStack->SetPolygon(poly, s, p, d, closed, preshape,
                                             label);
              break;
      case 1: this->SagPolyStack->SetPolygon(poly, s, p, d, closed, preshape,
                                             label);
              break;
      case 2: this->CorPolyStack->SetPolygon(poly, s, p, d, closed, preshape,
                                             label);
              break;
    }
  };
  void StackRemovePolygon(int window, int s, int p)
  {
    switch (window)
    {
      case 0: this->AxiPolyStack->RemovePolygon(s, p);
              break;
      case 1: this->SagPolyStack->RemovePolygon(s, p);
              break;
      case 2: this->CorPolyStack->RemovePolygon(s, p);
              break;
    }
  };

  void RasStackRemovePolygon(int window, int s, int p)
  {
    switch (window)
    {
      case 0: this->AxiRasPolyStack->RemovePolygon(s, p);
              break;
      case 1: this->SagRasPolyStack->RemovePolygon(s, p);
              break;
      case 2: this->CorRasPolyStack->RemovePolygon(s, p);
              break;
    }
  };
  void RasStackSetPolygon(int window, vtkPoints *rasPoly, int s, int p, int d,
                          int closed, int preshape, int label)
  {
    switch (window)
    {
      case 0: this->AxiRasPolyStack->SetPolygon(rasPoly, s, p, d, closed,
                                                preshape, label);
              break;
      case 1: this->SagRasPolyStack->SetPolygon(rasPoly, s, p, d, closed,
                                                preshape, label);
              break;
      case 2: this->CorRasPolyStack->SetPolygon(rasPoly, s, p, d, closed,
                                                preshape, label);
              break;
    }
  };

protected:
  vtkMrmlDataVolume();
  ~vtkMrmlDataVolume();
  vtkMrmlDataVolume(const vtkMrmlDataVolume&);
  void operator=(const vtkMrmlDataVolume&);

  // Description: 
  // If Data has not be created, create it.
  void CheckMrmlNode();
  void UpdateWindowLevelThreshold();
  void CheckImageData();

  vtkFloatingPointType RangeLow;
  vtkFloatingPointType RangeHigh;
  int RangeAuto;
  vtkFloatingPointType HistogramColor[3];

  vtkImageData *ImageData;
  vtkStackOfPolygons *AxiPolyStack;
  vtkStackOfPolygons *AxiRasPolyStack;
  vtkStackOfPolygons *SagPolyStack;
  vtkStackOfPolygons *SagRasPolyStack;
  vtkStackOfPolygons *CorPolyStack;
  vtkStackOfPolygons *CorRasPolyStack;
  vtkPoints *Samples;
  vtkImageAccumulateDiscrete *Accumulate;
  vtkImageBimodalAnalysis *Bimodal;
  vtkImageResize *Resize;
  vtkImagePlot *HistPlot;

// Description:
// Take information from the VtkMrmlNode and put it in the appropriate reader.
void DicomReaderSetup(vtkImageDICOMReader *dcmreader,
                      vtkMrmlVolumeNode *node,
                      int ext[6]);
void NonDicomReaderSetup(vtkImageReader *dcmreader,
                         vtkMrmlVolumeNode *node,
                         int ext[6]);

// Description:
// Do all the reading.
// Return the vtkImageSource already updated
// used by this->Read() and this->ReRead()
 vtkImageSource *ReaderHelper();

 // hook for developers to add any kind of volume reading
 vtkMrmlDataVolumeReadWrite *ReadWrite;


};

#endif
