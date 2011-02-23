/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLiveWireTester.cxx,v $
  Date:      $Date: 2006/01/06 17:56:42 $
  Version:   $Revision: 1.22 $

=========================================================================auto=*/
#include "vtkImageLiveWireTester.h"
#include "vtkObjectFactory.h"
#include "vtkImageLiveWireEdgeWeights.h"

//------------------------------------------------------------------------------
vtkImageLiveWireTester* vtkImageLiveWireTester::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageLiveWireTester");
  if(ret)
    {
    return (vtkImageLiveWireTester*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageLiveWireTester;
}

//----------------------------------------------------------------------------
// Description:
// Constructor sets default values.
vtkImageLiveWireTester::vtkImageLiveWireTester()
{
  // must be set by user
  this->LiveWire = NULL;

  this->EdgeFilters = NULL;
  this->SetNumberOfEdgeFilters(4);
  //this->SetNumberOfEdgeFilters(8);
  
  this->SettingsFileName = NULL;
}

//----------------------------------------------------------------------------
vtkImageLiveWireTester::~vtkImageLiveWireTester()
{
  if (this->LiveWire)
    {
      this->LiveWire->Delete();
    }
  
  if (this->EdgeFilters)
    {
      for (int i = 0; i < this->NumberOfEdgeFilters; i++)
    {
      if (this->EdgeFilters[i])
        {
          this->EdgeFilters[i]->Delete();
        }
    }

      delete [] this->EdgeFilters;
    }
  

  // We must UnRegister any object that has a vtkSetObjectMacro
  if (this->LiveWire != NULL) 
  {
    this->LiveWire->UnRegister(this);
  }

}

//----------------------------------------------------------------------------
// Description:
// creates the edge filter objects
// make sure to set their inputs when using this
void vtkImageLiveWireTester::SetNumberOfEdgeFilters(int number)
{

  if (number == 4 || number == 8) 
    {
      // kill the old ones
      if (this->EdgeFilters)
    {
      for (int i = 0; i < this->NumberOfEdgeFilters; i++)
        {
          if (this->EdgeFilters[i])
        {
          this->EdgeFilters[i]->Delete();
        }
        }

      delete [] this->EdgeFilters;
    }
  
      // make the new ones
      this->NumberOfEdgeFilters = number;
  
      this->EdgeFilters = new vtkImageLiveWireEdgeWeights*[this->NumberOfEdgeFilters];
  
      for (int i = 0; i < this->NumberOfEdgeFilters; i++)
    {
      this->EdgeFilters[i] = vtkImageLiveWireEdgeWeights::New();
      this->EdgeFilters[i]->SetEdgeDirection(i);
    }

    }
  else
    {
      vtkErrorMacro("NumberOfEdgeFilters must be 4 or 8");
    }
}

//----------------------------------------------------------------------------
// Description:
// return output of edge filter (for display)
vtkImageData *vtkImageLiveWireTester::GetEdgeImage(int filter)
{
  if (filter < this->NumberOfEdgeFilters)
    {
      return this->EdgeFilters[filter]->GetOutput();
    }
  else
    {
      vtkErrorMacro(<<"Requested filter " << filter << " greater than number of filters!");
      return this->EdgeFilters[0]->GetOutput();
    }
}

//----------------------------------------------------------------------------
// Description:
// get all filters to write their settings to one file
void vtkImageLiveWireTester::WriteFilterSettings()
{

  ofstream file;

  if (this->SettingsFileName)
    {
      file.open(this->SettingsFileName);
      if (file.fail())
    {
      vtkErrorMacro("Could not open file %" << this->SettingsFileName);
      return;
    }  
    }
  else 
    {
      vtkErrorMacro("FileName has not been set");
      return;
    }

  file << "Slicer Edge Filter Settings Version 1\n";

  char settings[2000];
  settings[0] = '\0';
  // tell each edge filter to output its data
  for (int i = 0; i < this->NumberOfEdgeFilters; i++)
    {
      // reset settings string
      
      // get settings from this filter
      this->EdgeFilters[i]->GetFeatureSettingsString(settings);

      this->EdgeFilters[i]->AppendFeatureSettings(file);
      file << "\n";
    }
  //cout << "i: " << i  << " settings: " << settings << endl;
  //cout << "len: " << strlen(settings) << endl;

  file.close();
}

//----------------------------------------------------------------------------
// Description:
// Hook up the edge filters to  Livewire filter.
//
// The rest of the pipeline is set up outside this filter.
// The whole pipeline is like this:
//
// thisFilter -> many edge filters -> -> -> -> livewire (inputs 1-max)
// and
// thisFilter -> livewire (input 0)
// 
void vtkImageLiveWireTester::InitializePipeline()
{
  // Max edge cost of edge filters and live wire need to match

  // give live wire all edge inputs
  this->LiveWire->SetUpEdges(this->EdgeFilters[0]->GetOutput());
  this->LiveWire->SetDownEdges(this->EdgeFilters[1]->GetOutput());
  this->LiveWire->SetLeftEdges(this->EdgeFilters[2]->GetOutput());
  this->LiveWire->SetRightEdges(this->EdgeFilters[3]->GetOutput());


  if (this->NumberOfEdgeFilters == 8)
    {
      this->LiveWire->SetUpLeftEdges(this->EdgeFilters[4]->GetOutput());
      this->LiveWire->SetUpRightEdges(this->EdgeFilters[5]->GetOutput());
      this->LiveWire->SetDownLeftEdges(this->EdgeFilters[6]->GetOutput());
      this->LiveWire->SetDownRightEdges(this->EdgeFilters[7]->GetOutput());
    }

}

//----------------------------------------------------------------------------
// Description:
// Pseudo-multiple-output filter.  Feeds 4 edge images to LiveWire, which
// should be next in pipeline and get this filter's output image too.
// So LiveWire will get: 
// input[0] : output of this filter (just matches filter's input)
// input[1] - input[4]: edges
//
static void vtkImageLiveWireTesterExecute(vtkImageLiveWireTester *self,
                     vtkImageData *inData, short *inPtr,
                     vtkImageData *outData, short *outPtr, 
                     int outExt[6])
{
  if (!self->GetLiveWire())
    {
      cout << "ERROR in vtkImageLiveWireTester: vtkImageLiveWire member not set."<< endl;
      return;
    }

  self->InitializePipeline();

  // Output is the same as input
  outData->CopyAndCastFrom(inData, inData->GetExtent());  

  return;
}


//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageLiveWireTester::Execute(vtkImageData *inData, vtkImageData *outData)
{
  int outExt[6];
  int s;
  outData->GetWholeExtent(outExt);
  void *inPtr = inData->GetScalarPointerForExtent(outExt);
  void *outPtr = outData->GetScalarPointerForExtent(outExt);

  int x1;

  x1 = GetInput()->GetNumberOfScalarComponents();
  if (x1 != 1) 
  {
    vtkErrorMacro(<<"Input has "<<x1<<" instead of 1 scalar component.");
    return;
  }

  /* Need short data */
  s = inData->GetScalarType();
  if (s != VTK_SHORT) 
  {
    vtkErrorMacro("Input scalars are type "<<s 
      << " instead of "<<VTK_SHORT);
    return;
  }

  vtkImageLiveWireTesterExecute(this, inData, (short *)inPtr, 
          outData, (short *)(outPtr), outExt);
}

void vtkImageLiveWireTester::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os,indent);
  

}
