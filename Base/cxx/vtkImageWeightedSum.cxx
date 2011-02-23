/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWeightedSum.cxx,v $
  Date:      $Date: 2006/04/25 16:49:20 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
#include "vtkImageWeightedSum.h"
#include "vtkObjectFactory.h"
#include <math.h>
#include <time.h>

//------------------------------------------------------------------------------
vtkImageWeightedSum* vtkImageWeightedSum::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageWeightedSum");
  if(ret)
    {
      return (vtkImageWeightedSum*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageWeightedSum;
}

//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageWeightedSum::vtkImageWeightedSum()
{
  // all inputs
  this->NumberOfRequiredInputs = 1;
  this->NumberOfInputs = 0;

  // array of weights: need as many weights as inputs
  this->Weights = vtkFloatArray::New();
  // 1st component is weight set by user, second is normalized weight
  this->Weights->SetNumberOfComponents(2);
}


//----------------------------------------------------------------------------
vtkImageWeightedSum::~vtkImageWeightedSum()
{
  this->Weights->Delete();
}

#define COMPONENT_WEIGHT 0
#define COMPONENT_NORM_WEIGHT 1

void vtkImageWeightedSum::NormalizeWeights()
{
  // sum weights and norm each one by this
  int numberOfWeights = this->Weights->GetNumberOfTuples();
  float sum = 0;

  // sum weights (component 0)
  for (int i = 0; i < numberOfWeights; i++) {
    sum += this->Weights->GetComponent(i,COMPONENT_WEIGHT);
  }

  // normalize by sum (and set component 1)
  float norm;
  for (int j = 0; j < numberOfWeights; j++) {
    norm = this->Weights->GetComponent(j,COMPONENT_WEIGHT)/sum;
    this->Weights->SetComponent(j,COMPONENT_NORM_WEIGHT,norm);
  }
}

void vtkImageWeightedSum::SetWeightForInput(int i, float w)
{
  this->Weights->InsertComponent(i,COMPONENT_WEIGHT,w);
  // need to fill entire component, so set norm weight to 0 for now
  this->Weights->InsertComponent(i,COMPONENT_NORM_WEIGHT,0);
  this->NormalizeWeights();
  this->Modified();
}

float vtkImageWeightedSum::GetWeightForInput(int i) {

  return(this->Weights->GetComponent(i,COMPONENT_WEIGHT));

}

float vtkImageWeightedSum::GetNormalizedWeightForInput(int i) {

  return(this->Weights->GetComponent(i,COMPONENT_NORM_WEIGHT));

}

void vtkImageWeightedSum::CheckWeights() {

  int numberOfWeights = this->Weights->GetNumberOfTuples();
  int numberOfInputs = this->GetNumberOfInputs();

  if (numberOfWeights < numberOfInputs) {
    // set the ones that haven't been set yet to 1
    for (int i = numberOfWeights; i < numberOfInputs; i++)
      {
      this->Weights->InsertComponent(i,COMPONENT_WEIGHT,1);
      // need to fill entire component, so set norm weight to 0 for now
      this->Weights->InsertComponent(i,COMPONENT_NORM_WEIGHT,0);
    }

    this->NormalizeWeights();
  }
  // else if number of weights is equal to number of inputs we
  // have already normalized the weights.
}


//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageWeightedSumExecute(vtkImageWeightedSum *self,
                          vtkImageData **inDatas, T **inPtrs,
                          vtkImageData *outData,
                          int outExt[6], int id)
{
  // For looping though output (and input) pixels.
  int outMin0, outMax0, outMin1, outMax1, outMin2, outMax2;
  int outIdx0, outIdx1, outIdx2;
  int inInc0, inInc1, inInc2;
  int outInc0, outInc1, outInc2;
  T **inPtrs0, **inPtrs1, **inPtrs2;
  T *outPtr0, *outPtr1, *outPtr2;
  // The extent of the whole input image
  int inImageMin0, inImageMin1, inImageMin2;
  int inImageMax0, inImageMax1, inImageMax2;
  T *outPtr = (T*)outData->GetScalarPointerForExtent(outExt);
  unsigned long count = 0;
  unsigned long target;
  int numberOfInputs;
  clock_t tStart, tEnd, tDiff;
  tStart = clock();

  // Get information to march through data
  // all indatas are the same type, so use the same increments
  inDatas[0]->GetIncrements(inInc0, inInc1, inInc2);

  // march through all inputs using array of input pointers.
  numberOfInputs = self->GetNumberOfInputs();
  inPtrs0 = new T*[numberOfInputs];
  inPtrs1 = new T*[numberOfInputs];
  inPtrs2 = new T*[numberOfInputs];

  self->GetInput()->GetWholeExtent(inImageMin0, inImageMax0, inImageMin1,
                   inImageMax1, inImageMin2, inImageMax2);

  outData->GetIncrements(outInc0, outInc1, outInc2);
  outMin0 = outExt[0];   outMax0 = outExt[1];
  outMin1 = outExt[2];   outMax1 = outExt[3];
  outMin2 = outExt[4];   outMax2 = outExt[5];

  // in and out should be marching through corresponding pixels.
  target = (unsigned long)((outMax2-outMin2+1)*
               (outMax1-outMin1+1)/50.0);
  target++;

  // make sure that weights have been set adequately.
  self->CheckWeights();

  // loop through pixels of output (and all inputs)
  int i = 0;
  outPtr2 = outPtr;
  for (i = 0; i < numberOfInputs; i++)
    {
    inPtrs2[i] = inPtrs[i];
    }
  for (outIdx2 = outMin2; outIdx2 <= outMax2; outIdx2++)
    {
    outPtr1 = outPtr2;
    for (i = 0; i < numberOfInputs; i++)
      {
      inPtrs1[i] = inPtrs2[i];
    }
    for (outIdx1 = outMin1;
      !self->AbortExecute && outIdx1 <= outMax1; outIdx1++)
      {
      if (!id)
        {
        if (!(count%target))
          {
          self->UpdateProgress(count/(50.0*target));
          }
        count++;
        }

      outPtr0 = outPtr1;
      for (i = 0; i < numberOfInputs; i++) {
        inPtrs0[i] = inPtrs1[i];
      }
      for (outIdx0 = outMin0; outIdx0 <= outMax0; outIdx0++)
        {
        T sum = 0;
        for (i = 0; i < numberOfInputs; i++) {
          sum += (*inPtrs0[i]) * self->GetNormalizedWeightForInput(i);

        }
        *outPtr0 = sum;

        for (i = 0; i < numberOfInputs; i++) {
          inPtrs0[i] += inInc0;
        }
        outPtr0 += outInc0;
        }//for0
      for (i = 0; i < numberOfInputs; i++) {
        inPtrs1[i] += inInc1;
      }
      outPtr1 += outInc1;
      }//for1
    for (i = 0; i < numberOfInputs; i++) {
      inPtrs2[i] += inInc2;
    }
    outPtr2 += outInc2;
    }//for2

  tEnd = clock();
  tDiff = tEnd - tStart;
  //cout << "sum time: " << tDiff << endl;
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageWeightedSum::ThreadedExecute(vtkImageData **inDatas,
                         vtkImageData *outData,
                         int outExt[6], int id)
{
  void **inPtrs = new void*[this->NumberOfInputs];
  void *outPtr;

  for (int i = 0; i < this->NumberOfInputs; i++)
    {
    inPtrs[i] = inDatas[i]->GetScalarPointerForExtent(inDatas[i]->GetExtent());
    }

  outPtr = outData->GetScalarPointerForExtent(outData->GetExtent());

  switch (inDatas[0]->GetScalarType())
    {
    case VTK_FLOAT:
      vtkImageWeightedSumExecute(this, inDatas, (float **)(inPtrs),
                    outData, outExt, id);
      break;
    default:
      vtkErrorMacro(<< "Execute: Bad input ScalarType, float needed");
      return;
    }

  delete [] inPtrs;
}

//----------------------------------------------------------------------------
// Make sure all the inputs are the same size. Doesn't really change
// the output. Just performs a sanity check
void vtkImageWeightedSum::ExecuteInformation(vtkImageData **inputs,
                             vtkImageData *output)
{
  int *in1Ext, *in2Ext;

  // we require that all inputs have been set.
  if (this->NumberOfInputs < this->NumberOfRequiredInputs)
    {
    vtkErrorMacro(<< "ExecuteInformation: Expected "
      << this->NumberOfRequiredInputs << " inputs, got only "
      << this->NumberOfInputs);
    return;
    }

  // Check that all extents are the same.
  in1Ext = inputs[0]->GetWholeExtent();
  for (int i = 1; i < this->NumberOfInputs; i++)
    {
    in2Ext = inputs[i]->GetWholeExtent();

    if (in1Ext[0] != in2Ext[0] || in1Ext[1] != in2Ext[1] ||
        in1Ext[2] != in2Ext[2] || in1Ext[3] != in2Ext[3] ||
        in1Ext[4] != in2Ext[4] || in1Ext[5] != in2Ext[5])
      {
      vtkErrorMacro("ExecuteInformation: Inputs 0 and " << i <<
        " are not the same size. "
        << in1Ext[0] << " " << in1Ext[1] << " "
        << in1Ext[2] << " " << in1Ext[3] << " vs: "
        << in2Ext[0] << " " << in2Ext[1] << " "
        << in2Ext[2] << " " << in2Ext[3] );
      return;
      }
    }

  // we like floats
  output->SetNumberOfScalarComponents(1);
  output->SetScalarType(VTK_FLOAT);
}

//----------------------------------------------------------------------------
void vtkImageWeightedSum::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  // objects
  os << indent << "Weights: " << this->Weights << "\n";
  this->Weights->PrintSelf(os,indent.GetNextIndent());
}
