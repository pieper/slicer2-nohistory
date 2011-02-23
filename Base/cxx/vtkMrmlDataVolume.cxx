/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlDataVolume.cxx,v $
  Date:      $Date: 2006/03/31 18:20:12 $
  Version:   $Revision: 1.29 $

=========================================================================auto=*/
#include "vtkMrmlDataVolume.h"

#include "vtkObjectFactory.h"
#include "vtkMrmlVolumeNode.h"
#include "vtkCommand.h"
#include "vtkCallbackCommand.h"
#include "vtkImageReader.h"
#include "vtkImageWriter.h"
#include "vtkImageCanvasSource2D.h"
#include "vtkImageCopy.h"
#include "vtkImageDICOMReader.h"
#include "vtkPointData.h"

//------------------------------------------------------------------------------
vtkMrmlDataVolume* vtkMrmlDataVolume::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlDataVolume");
  if(ret)
  {
    return (vtkMrmlDataVolume*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlDataVolume;
}

//----------------------------------------------------------------------------
vtkMrmlDataVolume::vtkMrmlDataVolume()
{
  // Allocate VTK objects
  this->Accumulate = vtkImageAccumulateDiscrete::New();
  this->Bimodal = vtkImageBimodalAnalysis::New();
  this->Resize = vtkImageResize::New();
  this->HistPlot = vtkImagePlot::New();
  this->ImageData = NULL;
  this->AxiPolyStack = vtkStackOfPolygons::New();
  this->AxiRasPolyStack = vtkStackOfPolygons::New();
  this->SagPolyStack = vtkStackOfPolygons::New();
  this->SagRasPolyStack = vtkStackOfPolygons::New();
  this->CorPolyStack = vtkStackOfPolygons::New();
  this->CorRasPolyStack = vtkStackOfPolygons::New();
  this->Samples = vtkPoints::New();
  this->ReadWrite = NULL;

  // W/L Slider range 
  this->RangeAuto = 1;
  this->RangeLow = 0;
  this->RangeHigh = 0;

  this->HistogramColor[0] = 1;
  this->HistogramColor[1] = 0;
  this->HistogramColor[2] = 0;

  // Setup a callback for the internal writer to report progress.
  this->ProgressObserver = vtkCallbackCommand::New();
  this->ProgressObserver->SetCallback(&vtkMrmlData::ProgressCallbackFunction);
  this->ProgressObserver->SetClientData(this);

  // NOTE: ImageData has a reference count of 2 because it is the ImageData
  // of this and the Input of this->Accumulate.
  // If we call SetImageData [something else] then the reference count drops
  // to 1.  Then when we call this->Update, then this->Accumulate gets a
  // new input and the reference count of the original ImageData drops to 0
  // and the object is deleted from memory.

  // Of course, the above works very nicely ONLY if the imagedata isn't
  // in a pipeline somewhere in the slicer...
}

//----------------------------------------------------------------------------
vtkMrmlDataVolume::~vtkMrmlDataVolume()
{
  // Delete if self-created or if no one else is using it
  if (this->ImageData != NULL) 
  {
    this->ImageData->UnRegister(this);
  }

  // Delete objects we allocated
  this->AxiPolyStack->Delete();
  this->AxiRasPolyStack->Delete();
  this->SagPolyStack->Delete();
  this->SagRasPolyStack->Delete();
  this->CorPolyStack->Delete();
  this->CorRasPolyStack->Delete();
  this->Samples->Delete();
  this->Accumulate->Delete();
  this->Bimodal->Delete();
  this->Resize->Delete();
  this->HistPlot->Delete();
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkMrmlData::PrintSelf(os, indent);

  os << indent << *this->HistPlot   << endl;
  os << indent << "Range Low: " << this->RangeLow << endl;
  os << indent << "Range High: " << this->RangeHigh << endl;
  os << indent << "Range Auto: " << this->RangeAuto << endl;

  os << indent << "ImageData: " << this->ImageData << "\n";
  os << indent << "AxiPolyStack: " << this->AxiPolyStack << "\n";
  os << indent << "AxiRasPolyStack: " << this->AxiRasPolyStack << "\n";
  os << indent << "SagPolyStack: " << this->SagPolyStack << "\n";
  os << indent << "SagRasPolyStack: " << this->SagRasPolyStack << "\n";
  os << indent << "CorPolyStack: " << this->CorPolyStack << "\n";
  os << indent << "CorRasPolyStack: " << this->CorRasPolyStack << "\n";
  if (this->ImageData)
  {
    this->ImageData->PrintSelf(os,indent.GetNextIndent());
  }
}

//----------------------------------------------------------------------------
// Determine the modified time of this object
unsigned long int vtkMrmlDataVolume::GetMTime()
{
  unsigned long result, t;

  result = vtkMrmlData::GetMTime();
 
  // ImageData
  if (this->ImageData)
  {
    t = this->ImageData->GetMTime(); 
    result = (t > result) ? t : result;
  }

  return result;
}

const char* vtkMrmlDataVolume::GetOutputPointer(int zslice)
{
    static char p[1024];
    void *ptr;

    if ( this->ImageData == NULL )
      {
      sprintf (p, "%d", 0);
      }
    else
      {
      ptr = this->ImageData->GetScalarPointer(0, 0, zslice);
      sprintf (p, "%p", ptr);
      }
    return p;
}


//----------------------------------------------------------------------------
void vtkMrmlDataVolume::CheckImageData()
{
  // If the user has not set the ImageData, then create it.
  // The key is to perform: New(), Register(), Delete().
  // Then we can call UnRegister() in the destructor, and it will delete
  // the object if no one else is using it.  We don't have to distinguish
  // between whether we created the object, or someone else did!

  if (this->ImageData == NULL)
  {
    // Give it a size that matches with the MrmlNode (but 2D)
    int dim[2];
    short s=0;
    vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;
    node->GetDimensions(dim);

#ifndef SLICER_VTK5
    vtkImageCanvasSource2D *canvas = vtkImageCanvasSource2D::New();
    canvas->SetScalarType(node->GetScalarType());
    canvas->SetNumberOfScalarComponents(node->GetNumScalars());
    canvas->SetExtent(0, dim[0]-1, 0, dim[1]-1, 0, 0);
    canvas->SetSpacing(node->GetSpacing());
    canvas->SetDrawColor(s);
    canvas->FillBox(0, dim[0]-1, 0, dim[0]-1);

    vtkImageCopy *copy = vtkImageCopy::New();
    copy->SetInput(canvas->GetOutput());
    copy->Update();
    this->SetImageData(copy->GetOutput());
    copy->SetOutput(NULL);
    copy->Delete();
      canvas->Delete();
#else

    // Make this an empty RGBA image
    vtkImageData *id = vtkImageData::New();
    id->SetNumberOfScalarComponents(node->GetNumScalars());
    //id->SetScalarType(VTK_UNSIGNED_CHAR);
    id->SetScalarType(node->GetScalarType());
    id->SetExtent(0, dim[0]-1, 0, dim[1]-1, 0, 0);
    id->SetSpacing(node->GetSpacing());
    id->AllocateScalars();

    // clear the image, just in case
    //unsigned char *ptr = (unsigned char *)id->GetScalarPointer();
    //memset (ptr, 0, 4 * dim[0] * dim[1]);

    this->SetImageData(id);
    id->Delete();

#endif /* !SLICER_VTK5 */

  }
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::CheckMrmlNode()
{
  // If the user has not set the ImageData, then create it.
  // The key is to perform: New(), Register(), Delete().
  // Then we can call UnRegister() in the destructor, and it will delete
  // the object if no one else is using it.  We don't have to distinguish
  // between whether we created the object, or someone else did!

  if (this->MrmlNode == NULL)
  {
    this->MrmlNode = (vtkMrmlNode*) vtkMrmlVolumeNode::New();
    this->MrmlNode->Register(this);
    this->MrmlNode->Delete();
  }
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::Update()
{
  int ext[6];

  this->vtkMrmlData::Update();
  
  // We really should have an Update time that we compare with the
  // MTime, but since the other objects inside this class do this, 
  // its alright.

  // Create objects that the user hasn't already set
  this->CheckImageData();
  // Connect pipeline
  this->Accumulate->SetInput(this->ImageData);
  this->Accumulate->Update();
  this->Bimodal->SetInput(this->Accumulate->GetOutput());
  this->Bimodal->Update();
  this->Bimodal->GetClipExtent(ext);
  this->Resize->SetInputClipExtent(ext);
  this->Resize->SetInput(this->Accumulate->GetOutput());
  this->Resize->Update();
  this->HistPlot->SetInput(this->Resize->GetOutput());

  // Bound W/L range and apply auto if requested
  this->UpdateWindowLevelThreshold();
}

//----------------------------------------------------------------------------
vtkImageData* vtkMrmlDataVolume::GetOutput()
{
  this->Update();
  return this->ImageData;
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::UpdateWindowLevelThreshold()
{
  vtkFloatingPointType window, level, upper, lower;

  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;

  // Compute the range using the accumulator and bimodal analysis.
  // The common case is auto W/L, so we want this to be the fastest.
  //
  this->Bimodal->Update();

  // Auto Range
  if (this->RangeAuto) 
  {
    this->RangeLow  = this->Bimodal->GetMin();
    this->RangeHigh = this->Bimodal->GetMax();
  }

  // Auto W/L
  if (node->GetAutoWindowLevel())
  {
    node->SetLevel(this->Bimodal->GetLevel());
    node->SetWindow(this->Bimodal->GetWindow());
  }

  // Auto Threshold
  if (node->GetAutoThreshold())
  {
    node->SetLowerThreshold(this->Bimodal->GetThreshold());
    node->SetUpperThreshold(this->Bimodal->GetMax());
  }

  // Force Window/Level/Thresh to be within the Range
  level  = node->GetLevel();
  window = node->GetWindow();
  upper  = node->GetUpperThreshold();
  lower  = node->GetLowerThreshold();

  // Clip Level
  if (level < this->RangeLow) 
  {
    level = this->RangeLow;
    node->SetLevel(level);
  } 
  else if (level > this->RangeHigh) 
  {
    level = this->RangeHigh;
    node->SetLevel(level);
  }

  // Clip Window
  if (window < 0) 
  {
    window = 0;
    node->SetWindow(window);
  }
  if (window > (this->RangeHigh - this->RangeLow + 1)) 
  {
    window = this->RangeHigh - this->RangeLow + 1;
    node->SetWindow(window);
  }

  // Clip UpperThreshold
  if (upper < this->RangeLow) 
  {
    upper = this->RangeLow;
    node->SetUpperThreshold(upper);
  } 
  else if (upper > this->RangeHigh) 
  {
    upper = this->RangeHigh;
    node->SetUpperThreshold(upper);
  }

  // Clip LowerThreshold 
  if (lower < this->RangeLow) 
  {
    lower = this->RangeLow;
    node->SetLowerThreshold(lower);
  } 
  else if (lower > this->RangeHigh) 
  {
    lower = this->RangeHigh;
    node->SetLowerThreshold(lower);
  }

  // Do not apply W/L to the LabelIndirectLUT
  if (this->UseLabelIndirectLUT == 0)
  {
    this->IndirectLUT->SetLevel(level);
    this->IndirectLUT->SetWindow(window);
    this->IndirectLUT->SetLowerThreshold(lower);
    this->IndirectLUT->SetUpperThreshold(upper);
    this->IndirectLUT->SetApplyThreshold(node->GetApplyThreshold());
    this->IndirectLUT->Build();
  }
}

//----------------------------------------------------------------------------
vtkImageData* vtkMrmlDataVolume::GetHistogramPlot()
{
  int ext[6];
  int signalRange[2];

  // Update pipeline for the plot
  this->Update();
  this->Bimodal->GetClipExtent(ext);
  this->Bimodal->GetSignalRange(signalRange);
  this->Resize->SetInputClipExtent(ext);
  this->HistPlot->SetDataRange(0, signalRange[1]);
  this->HistPlot->SetDataDomain(
    this->Bimodal->GetMin(), this->Bimodal->GetMax());
  this->HistPlot->SetLookupTable(this->GetIndirectLUT());
  this->HistPlot->SetColor(this->HistogramColor);
  this->HistPlot->Update();
  
  return this->HistPlot->GetOutput();
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::DicomReaderSetup(vtkImageDICOMReader *dcmreader,
                                     vtkMrmlVolumeNode *node,
                                     int ext[6])
{
  dcmreader->SetNumberOfScalarComponents(node->GetNumScalars());
  dcmreader->SetDataScalarType(node->GetScalarType());
  dcmreader->SetDataByteOrder(node->GetLittleEndian());
  dcmreader->SetDataSpacing(node->GetSpacing());
  dcmreader->SetFilePattern(node->GetFilePattern());
  dcmreader->SetFilePrefix(node->GetFullPrefix());
  dcmreader->SetDataExtent(ext);

  dcmreader->SetDICOMFileNames(node->GetNumberOfDICOMFiles(),
                               node->GetDICOMFileNamesPointer(),
                   node->GetNumberOfDICOMMultiFrameOffsets(),
                   node->GetDICOMMultiFrameOffsetPointer());
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::NonDicomReaderSetup(vtkImageReader *ireader,
                                      vtkMrmlVolumeNode *node,
                                      int ext[6])
{
  ireader->SetNumberOfScalarComponents(node->GetNumScalars());
  ireader->SetDataScalarType(node->GetScalarType());
  ireader->SetDataByteOrder(node->GetLittleEndian());
  ireader->SetDataSpacing(node->GetSpacing());
  ireader->SetFilePattern(node->GetFilePattern());
  ireader->SetFilePrefix(node->GetFullPrefix());
  ireader->SetDataExtent(ext);
}

//----------------------------------------------------------------------------
//
// Do all the reading.
// Return the vtkImageSource already updated
// used by this->Read
//
vtkImageSource *vtkMrmlDataVolume::ReaderHelper()
{
  int ext[6], *range, *dim;


  // Create objects that don't already exist
  //this->CheckMrmlNode();
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;

  // Start progress reporting
  //this->InvokeEvent(vtkCommand::StartEvent,NULL);

  range = node->GetImageRange();
  dim = node->GetDimensions();
  ext[0] = 0;
  ext[1] = dim[0] - 1;
  ext[2] = 0;
  ext[3] = dim[1] - 1;
  ext[4] = range[0];
  ext[5] = range[1];

  //
  // Modified by Attila Tanacs 8/28/2000
  //

  vtkImageSource *reader;

  // try as DICOM
  if(node->GetNumberOfDICOMFiles() > 0)
    { // DICOM
      vtkImageDICOMReader *dcmreader = vtkImageDICOMReader::New();
      this->DicomReaderSetup(dcmreader,node,ext);

      reader = (vtkImageSource *) dcmreader;
    }
  else
    { // Not DICOM (use the original code)
      vtkImageReader *ireader = vtkImageReader::New();
      this->NonDicomReaderSetup(ireader,node,ext);

      reader = (vtkImageSource *) ireader;
   }

  // Progress callback
  this->ProcessObject = reader;
  reader->AddObserver (vtkCommand::ProgressEvent,
                       this->ProgressObserver);
 
  // Read it
  reader->Update();

  return reader;
}


//----------------------------------------------------------------------------
int vtkMrmlDataVolume::Read()
{

  // Start progress reporting
  this->InvokeEvent(vtkCommand::StartEvent,NULL);

  // Create objects that don't already exist
  this->CheckMrmlNode();
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;

  // pointer to output of internally used read method
  vtkImageSource *reader;

  if (this->ReadWrite == NULL) 
    {
      // use old method
      reader = ReaderHelper();
    }
  else
    {
      // use new object for read/write whichever file type it may be
      // NOTE: should fix progress reporting
      reader = NULL;
      this->ReadWrite->Read(node,&reader);
    }

  // Detach image data from reader
  this->SetImageData(reader->GetOutput());
  reader->SetOutput(NULL);
  this->ProcessObject = NULL;
  reader->Delete();

  // End progress reporting
  this->InvokeEvent(vtkCommand::EndEvent,NULL);

  // Update W/L
  this->Update();
  // Right now how no way to deal with failure
  return 1;
}


//----------------------------------------------------------------------------
int vtkMrmlDataVolume::Write()
{

  this->CheckMrmlNode();
  this->CheckImageData();
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;
  
  // Start progress reporting
  this->InvokeEvent(vtkCommand::StartEvent,NULL);

  if (this->ReadWrite == NULL) 
    {
      // Make the z extent equal the desired range of image numbers
      // so that the writer will start on the right image number (.001 not .000)
      int tmpExt[6], saveExt[6], saveWholeExt[6], range[2];
      this->ImageData->GetExtent(saveExt);
      this->ImageData->GetWholeExtent(saveWholeExt);
      this->ImageData->GetExtent(tmpExt);
      
      node->GetImageRange(range);
      tmpExt[4] = range[0];
      tmpExt[5] = range[1];
      this->ImageData->SetExtent(tmpExt);
      this->ImageData->SetWholeExtent(tmpExt);

      // Set up the image writer
      vtkImageWriter *writer = vtkImageWriter::New();
      if (node->GetFilePattern()) 
      { writer->SetFilePattern(node->GetFilePattern());
      }
      if (node->GetFullPrefix())
      { writer->SetFilePrefix(node->GetFullPrefix());
      }
      writer->SetInput(this->ImageData);
      
      // Progress callback
      writer->AddObserver (vtkCommand::ProgressEvent,
                           this->ProgressObserver);
      // The progress callback function needs a handle to the writer 
#ifdef SLICER_VTK5
      // TODO - fix observer for vtk5
      vtkWarningMacro ("vtkImageWriter is not a vtkProcessObject in vtk5");
#else
      this->ProcessObject = writer;
#endif
     
      // Write it
      writer->Write();

      writer->SetInput(NULL);
      writer->Delete();

      // Reset the original extent of the data
      this->ImageData->SetExtent(saveExt);
      this->ImageData->SetWholeExtent(saveWholeExt);
    }  // end if ReadWrite is NULL
  else 
    {
      // use the new method of writing volumes.
      this->ReadWrite->Write(node,this->ImageData);
    }

  // End progress reporting
  this->InvokeEvent(vtkCommand::EndEvent,NULL);

  // Right now how no way to deal with failure
  return 1;
}

//----------------------------------------------------------------------------
int vtkMrmlDataVolume::WritePTS(char *filename)
{

  this->CheckMrmlNode();
  this->CheckImageData();
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->MrmlNode;
  
  // Start progress reporting
  this->InvokeEvent(vtkCommand::StartEvent,NULL);

      // Make the z extent equal the desired range of image numbers
      // so that the writer will start on the right image number (.001 not .000)
      int tmpExt[6], saveExt[6], range[2];
      this->ImageData->GetExtent(saveExt);
      this->ImageData->GetExtent(tmpExt);
      
      node->GetImageRange(range);
      tmpExt[4] = range[0];
      tmpExt[5] = range[1];
      this->ImageData->SetExtent(tmpExt);

      // Set up the image writer
      vtkPTSWriter *writer = vtkPTSWriter::New();
      writer->SetFileName(filename);
      writer->SetInput(this->ImageData);
      
      // Progress callback
      writer->AddObserver (vtkCommand::ProgressEvent,
                           this->ProgressObserver);
      // The progress callback function needs a handle to the writer 
      this->ProcessObject = writer;
     
      // Write it
      //writer->Write();
      writer->WriteAsciiPTS();

      writer->SetInput(NULL);
      writer->Delete();

      // Reset the original extent of the data
      this->ImageData->SetExtent(saveExt);

  // End progress reporting
  this->InvokeEvent(vtkCommand::EndEvent,NULL);

  // Right now how no way to deal with failure
  return 1;
}

int vtkMrmlDataVolume::WritePTSFromStack(int window, char *filename,
                                         vtkMatrix4x4 *RasToIjkMatrix,
                                         char *order, int activeSlice)
{
    if (filename == NULL)
    {
        vtkErrorMacro(<< "Please specify filename to write");
        return 1;
    }

    // Write ASCII PTS file
    FILE *fp;
    if ((fp = fopen(filename, "w")) == NULL)
    {
        vtkErrorMacro(<< "Couldn't open file: " << filename);
        return 1;
    }

    vtkStackOfPolygons *RasPolyStack;
    switch (window)
    {
        case 0: RasPolyStack = this->AxiRasPolyStack; break;
        case 1: RasPolyStack = this->SagRasPolyStack; break;
        case 2: RasPolyStack = this->CorRasPolyStack; break;
    }

    for (unsigned int s = 0; s < RasPolyStack->GetStackSize(); s++)
    {
        // Skip this slice of stack if no polygon ever been stored in it
        if (!(RasPolyStack->Nonempty(s))) continue;
        for (int p = 0; p < NUM_POLYGONS; p++)
        {
            // Skip this polygon if it has no points
            if (RasPolyStack->GetNumberOfPoints(s, p) < 1) continue;
            vtkPoints *ras = RasPolyStack->GetSampledPolygon(s, p);
            int n = ras->GetNumberOfPoints();
            for (int i = 0; i < n; i++)
            {
                // outPt is the true 3D RAS coordinates of polygon point
                vtkFloatingPointType *outPt = ras->GetPoint(i);
                // Write out the RAS coordinates to the .pts file
                if (fprintf(fp, "%f %f %f\n", outPt[0], outPt[1], outPt[2]) < 0)
                {
                    fclose (fp);
                    vtkErrorMacro (<< "Out of disk space error.");
                    return 1;
                }
            }
        }
    }

    fclose(fp);

    // Right now no way to deal with failure
    return 1;
}

//----------------------------------------------------------------------------
void vtkMrmlDataVolume::SetHistogramWidth(int w)
{
  int ext[6];

  memset(ext, 0, 6*sizeof(int));
  ext[1] = w-1;
  this->Resize->SetOutputWholeExtent(ext);
}

