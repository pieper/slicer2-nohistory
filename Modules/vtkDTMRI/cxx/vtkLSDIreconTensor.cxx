/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkLSDIreconTensor.cxx,v $
  Date:      $Date: 2006/01/13 16:44:43 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
#include "vtkLSDIreconTensor.h"
#include "vtkObjectFactory.h"
#include "vtkFloatArray.h"
#include "vtkImageData.h"
#include "vtkPointData.h"

//----------------------------------------------------------------------------
vtkLSDIreconTensor* vtkLSDIreconTensor::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkLSDIreconTensor");
  if(ret)
    {
      return (vtkLSDIreconTensor*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkLSDIreconTensor;
}


//----------------------------------------------------------------------------
vtkLSDIreconTensor::vtkLSDIreconTensor()
{
  // may be set by user
  this->Transform = NULL;

  this->NumberOfRequiredInputs = 6;
  this->NumberOfGradients = 6;
  this->G = NULL;
  //this->AllocateInternals();
  
  // scaling of the short data on disk is by 1000
  this->InputScaleFactor = 1000;

  this->DualBasis = vtkVectorToOuterProductDualBasis::New();
  this->DualBasis->SetNumberOfInputVectors(this->NumberOfGradients);

  // defaults are from DT-MRI 
  // (from Processing and Visualization for 
  // Diffusion Tensor MRI, C-F Westin, pg 8)
  this->SetDiffusionGradient(0,1,1,0);
  this->SetDiffusionGradient(1,0,1,1);
  this->SetDiffusionGradient(2,1,0,1);
  this->SetDiffusionGradient(3,0,1,-1);
  this->SetDiffusionGradient(4,1,-1,0);
  this->SetDiffusionGradient(5,-1,0,1);

  // test:
  //for (int i = 0; i < 6; i++ ) {
  //vtkFloatingPointType *tmp = this->GetDiffusionGradient(i);
  //cout << tmp[0] << " " << tmp[1] << " " << tmp[2] << endl;
  //}

}
vtkLSDIreconTensor::~vtkLSDIreconTensor()
{
  //this->DeallocateInternals();
}

//----------------------------------------------------------------------------
void vtkLSDIreconTensor::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfGradients: " << this->NumberOfGradients << "\n";

  // print all of the gradients
  for (int i = 0; i < this->NumberOfGradients; i++ ) 
    {
      vtkFloatingPointType *g = this->GetDiffusionGradient(i);
      os << indent << "Gradient " << i << ": (" 
     << g[0] << ", "
     << g[1] << ", "
     << g[2] << ")" << "\n";
      
    }  
}

//----------------------------------------------------------------------------
void vtkLSDIreconTensor::TransformDiffusionGradients()
{
  vtkFloatingPointType gradient[3];

  // if matrix has not been set by user don't use it
  if (this->Transform == NULL) 
    {
      return;
    }

  vtkDebugMacro("Transforming diffusion gradients");
  //this->Transform->Print(cout);


  // transform each gradient by this matrix
  for (int i = 0; i < this->NumberOfGradients; i++ ) 
    {
      vtkFloatingPointType *g = this->GetDiffusionGradient(i);
      this->Transform->TransformPoint(g,gradient);

      // set the gradient to the transformed one 
      // (note this set function normalizes too)
      this->SetDiffusionGradient(i,gradient);
    }
}

//----------------------------------------------------------------------------
// The number of required inputs is one more than the number of
// diffusion gradients applied.  (Since image 0 is an image
// acquired without diffusion gradients).
void vtkLSDIreconTensor::SetNumberOfGradients(int num) 
{
  if (this->NumberOfGradients != num)
    {
      vtkDebugMacro ("setting num gradients to " << num);
      // internal array for storage of gradient vectors
      this->DualBasis->SetNumberOfInputVectors(num);
      // this class's info
      this->NumberOfGradients = num;
      this->NumberOfRequiredInputs = num + 1;
      this->Modified();
    }
}

//----------------------------------------------------------------------------
//
void vtkLSDIreconTensor::ExecuteInformation(vtkImageData **inDatas, 
                         vtkImageData *outData)
{
  // We always want to output vtkFloatingPointType scalars
  outData->SetScalarType(VTK_FLOAT);

}

//----------------------------------------------------------------------------
// Replace superclass Execute with a function that allocates tensors
// as well as scalars.  This gets called before multithreader starts
// (after which we can't allocate, for example in ThreadedExecute).
// Note we return to the regular pipeline at the end of this function.
void vtkLSDIreconTensor::ExecuteData(vtkDataObject *out)
{
  vtkImageData *output = vtkImageData::SafeDownCast(out);

  // set extent so we know how many tensors to allocate
  output->SetExtent(output->GetUpdateExtent());

  // allocate output tensors
  vtkFloatArray* data = vtkFloatArray::New();
  int* dims = output->GetDimensions();
  vtkDebugMacro("Allocating output tensors, dims " << dims[0] <<" " << dims[1] << " " << dims[2]);
  data->SetNumberOfComponents(9);
  data->SetNumberOfTuples(dims[0]*dims[1]*dims[2]);
  output->GetPointData()->SetTensors(data);
  data->Delete();

  // make sure our gradient matrix is up to date
  //This update is not thread safe and it has to be performed outside
  // the threaded part.
  // if the user has transformed the coordinate system
  this->TransformDiffusionGradients();
  this->GetDualBasis()->CalculateDualBasis();


  // jump back into normal pipeline: call standard superclass method here
  this->vtkImageMultipleInputFilter::ExecuteData(out);
}



//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
template <class T>
static void vtkLSDIreconTensorExecute(vtkLSDIreconTensor *self,
                       vtkImageData **inDatas, 
                       T ** inPtrs,
                       vtkImageData *outData, 
                       float * outPtr,
                       int outExt[6], int id)
{
  int idxX, idxY, idxZ;
  int maxX, maxY, maxZ;
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  unsigned long count = 0;
  unsigned long target;
  double Sk, fk;
  int numInputs, k,i,j,idx, gradientIdx;
  float val, inputScaling;
  double **G;

  vtkDataArray *outTensors;
  float outT[3][3];
  int ptId;

  // Get information to march through output tensor data
  outTensors = self->GetOutput()->GetPointData()->GetTensors();
  
  // Get pointer to already calculated G matrix
  G =  self->GetDualBasis()->GetPseudoInverse();


  int *outInc, *outFullUpdateExt;
  outInc = self->GetOutput()->GetIncrements();
  outFullUpdateExt = self->GetOutput()->GetUpdateExtent(); //We are only working over the update extent
  ptId = ((outExt[0] - outFullUpdateExt[0]) * outInc[0]
     + (outExt[2] - outFullUpdateExt[2]) * outInc[1]
     + (outExt[4] - outFullUpdateExt[4]) * outInc[2]);

  // find the region to loop over
  maxX = outExt[1] - outExt[0];
  maxY = outExt[3] - outExt[2]; 
  maxZ = outExt[5] - outExt[4];
  target = (unsigned long)(outData->GetNumberOfScalarComponents()*
               (maxZ+1)*(maxY+1)/50.0);
  target++;

  // Get increments to march through image data 
  inDatas[0]->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  numInputs = self->GetNumberOfInputs();
  cout << "Number of inputs: " << numInputs << "\n";
  inputScaling = self->GetInputScaleFactor();

  for (idxZ = 0; idxZ <= maxZ; idxZ++)
    {
      for (idxY = 0; !self->AbortExecute && idxY <= maxY; idxY++)
    {
      if (!id) 
        {
          if (!(count%target)) 
        {
          self->UpdateProgress(count/(50.0*target) 
                       + (maxZ+1)*(maxY+1));
        }
          count++;
        }
      for (idxX = 0; idxX <= maxX; idxX++)
        {

          // Lauren should this be the outer loop instead (better caching?)
          //outTensors->GetTuple(ptId,(float *)outT);

          // init output tensor to 0's for summing
          for (i = 0; i < 3; i++)
        {
          for (j = 0; j < 3; j++)
            {
              outT[i][j] = 0;
            }
        }


          // create tensor from combination of gradient inputs
          for (k = 0; k < numInputs; k++)
        {
          // diffusion from kth gradient
          Sk = (double)*inPtrs[k]/inputScaling;
          
          // make sure not less than 0
          if (Sk < 0)
            Sk = 0;

          fk = Sk;

          // add contribution in the proper direction
          gradientIdx = k;   // row of G is the current gradient
          idx = 0;           // step along columns of G
          for (i = 0; i < 3; i++)
            {
              for (j = 0; j < 3; j++)
            {
              val = fk*G[gradientIdx][idx];
              outT[i][j] += val;
              idx++;
            }
            }

          // increment the kth pointer
          inPtrs[k]++;
        }

          // Pixel operation          
          outTensors->SetTuple(ptId,(float *)outT);

          // use the trace as the scalar
          *outPtr = (outT[0][0]+outT[1][1]+outT[2][2]);
                 
          ptId ++;
          inPtrs[0]++;
          outPtr++;
        }
      outPtr += outIncY;
      ptId += outIncY;
      for (k = 0; k < numInputs; k++)
        {
          inPtrs[k] += inIncY;
        }
    }
      outPtr += outIncZ;
      ptId += outIncZ;

      for (k = 0; k < numInputs; k++)
    {
      inPtrs[k] += inIncZ;
    }
    }
}

//----------------------------------------------------------------------------
// This method is passed a input and output regions, and executes the filter
// algorithm to fill the output from the inputs.
// It just executes a switch statement to call the correct function for
// the regions data types.
void vtkLSDIreconTensor::ThreadedExecute(vtkImageData **inDatas, 
                          vtkImageData *outData,
                          int outExt[6], int id)
{
  int idx;
  void **inPtrs;
  void *outPtr = outData->GetScalarPointerForExtent(outExt);

  vtkDebugMacro("in threaded execute, " << this->GetNumberOfInputs() << " inputs ");


  // Lauren check they have set the first input for no diff

  if (this->NumberOfInputs < this->NumberOfRequiredInputs)
    {
      vtkErrorMacro(<< "Number of inputs (" << this->NumberOfInputs << 
      ") is less than the number of required inputs (" << 
      this->NumberOfRequiredInputs <<
      ") for this filter.");
      return;      
    }

  // Loop through checking all inputs 
  for (idx = 0; idx < this->NumberOfInputs; ++idx)
    {
      if (inDatas[idx] != NULL)
    {
      // this filter expects all inputs to have the same extent
      // Lauren check the above.

      // this filter expects 1 scalar component input
      if (inDatas[idx]->GetNumberOfScalarComponents() != 1)
        {
          vtkErrorMacro(<< "Execute: input" << idx << " has " << 
          inDatas[idx]->GetNumberOfScalarComponents() << 
          " instead of 1 scalar component");
          return;
        }


      // this filter expects that output is vtkFloatingPointType
      if (outData->GetScalarType() != VTK_FLOAT)
        {
          vtkErrorMacro(<< "Execute: output ScalarType (" << 
          outData->GetScalarType() << 
          "), must be float");
          return;
        }
      
    }
      else {
    vtkErrorMacro(<< "Execute: input" << idx << " is NULL");
      }
    }

  inPtrs = new void*[this->NumberOfInputs];

  // Loop through to fill input pointer array
  for (idx = 0; idx < this->NumberOfInputs; ++idx)
    {
      // Lauren should we use out ext here?
      inPtrs[idx] = inDatas[idx]->GetScalarPointerForExtent(outExt);
    }


  // call Execute method to handle all data at the same time
  switch (inDatas[0]->GetScalarType())
    {
      vtkTemplateMacro7(vtkLSDIreconTensorExecute, this, 
            inDatas, (VTK_TT **)(inPtrs),
            outData, (float *)(outPtr), 
            outExt, id);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
  
}


