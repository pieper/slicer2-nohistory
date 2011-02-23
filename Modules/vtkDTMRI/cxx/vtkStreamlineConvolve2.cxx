/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStreamlineConvolve2.cxx,v $
  Date:      $Date: 2006/08/15 16:43:39 $
  Version:   $Revision: 1.1 $
=========================================================================auto=*/

#include "vtkStreamlineConvolve2.h"

#include "vtkCellArray.h"
#include "vtkDataArray.h"
#include "vtkImageData.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkPoints.h"
#include "vtkPolyData.h"
#include "vtkMath.h"
#include "math.h"

vtkCxxRevisionMacro(vtkStreamlineConvolve2, "$Revision: 1.1 $");
vtkStandardNewMacro(vtkStreamlineConvolve2);


vtkStreamlineConvolve2::vtkStreamlineConvolve2()
{

  this->Transform = vtkTransform::New();
  this->KernelSize = 5;
  this->Sigma[0] = 1.5;
  this->Sigma[1] = 1.5;
  this->Sigma[2] = 3;
  this->Threader = vtkMultiThreader::New();
  this->NumberOfThreads = this->Threader->GetNumberOfThreads();
  
  this->Streamlines = NULL; 
}

//----------------------------------------------------------------------------
vtkStreamlineConvolve2::~vtkStreamlineConvolve2()
{
  this->Transform->Delete();
  this->Threader->Delete();
}  

template <class T>
void vtkStreamlineConvolve2Execute(vtkStreamlineConvolve2 *self, 
                                  vtkImageData *input, T *tmpPtr,int range[2],int id)
{
  int kernelSize;
  int kernelMiddle[3];
  int *neighPos;
  int *kernelId[3];
  double *kernelval;
  //Compute neigboors position
  cout <<"Building neigh position table"<<endl;
  kernelSize = (int) pow(self->GetKernelSize(),3);
  neighPos = new int[kernelSize];
  for (int k=0; k<3; k++) {
    kernelId[k] = new int[kernelSize];
  }
  kernelval = new double[kernelSize];
  int inc[3];
  input->GetIncrements(inc);
  neighPos[0]=0;
  kernelId[0][0] = 0;
  kernelId[1][0] = 0;
  kernelId[2][0] = 0;
  int bounds = (int) floor(self->GetKernelSize()/2.0);
  cout << "bounds: "<<bounds<<endl;
  cout <<" Kernel size: "<<kernelSize<<endl;
  cout <<" Incr: "<<inc[0]<<" "<<inc[1]<<" "<<inc[2]<<endl;
  int idx=1;
  for (int zA =-bounds; zA<=bounds;zA++) {
     for (int yA=-bounds; yA<=bounds; yA++) {
         for (int xA=-bounds; xA<=bounds; xA++) {
                if (xA==0 && yA==0 && zA==0) {
                    continue;
                }
            neighPos[idx]=xA*inc[0]+yA*inc[1]+zA*inc[2];
            kernelId[0][idx] = xA;
            kernelId[1][idx] = yA;
            kernelId[2][idx] = zA;
            idx++;
        }
     }
  }


 vtkIdType numPts;

  vtkPolyData *output = self->GetOutput();
  vtkPolyData *streamlines = self->GetStreamlines();

  numPts = streamlines->GetNumberOfPoints();
  // Pass to output only line information
  output->SetPoints(streamlines->GetPoints());
  output->SetLines(streamlines->GetLines());

  double *origin = input->GetOrigin();
  double *spacing = input->GetSpacing();

  double sigma[3];
  self->GetSigma(sigma);

  // Points of the streamline
  double globalpt[3],in[4],out[4];
  int roundpt[3];

  vtkDoubleArray *outScalars = (vtkDoubleArray *) self->GetOutput()->GetPointData()->GetScalars();

  // Foreacheach streamline point
  //   1. Compute streamline point in ijk coordinates
  //   2. Compute kernel (taking into account input values)
  // Foreach input component
  // Loop through the neighboorhood
     //3. Do convolution

  int abort=0;
  vtkIdType progressInterval = numPts/20+1;
  double x[3];
  int ijk[3];
  double pcoord[3];
  int pos;
  int numComp = input->GetNumberOfScalarComponents();
  double val, value,d;
  double Pi = vtkMath::Pi();
  int inPtrId;
  T *inPtr, *valPtr;
  int dims[3];
  input->GetDimensions(dims);
  cout <<" Starting streamline convolution"<<endl;
  cout<<" Range: "<<range[0]<<" "<<range[1]<<endl;

  int posmax = input->GetNumberOfPoints()*numComp;

  for (int ptId=range[0]; ptId <= range[1] && !abort; ptId++)
    {
    if ( !(ptId % progressInterval) && id == 0)
      {
      self->UpdateProgress((double)ptId/numPts);
      abort = self->GetAbortExecute();
      }
    //Streamline point in global coordinate system (scale IJK)
    streamlines->GetPoint(ptId,globalpt);
    cout<<"globalpt: "<<globalpt[0]<<" "<<globalpt[1]<<" "<<globalpt[2]<<endl;
    in[0] = globalpt[0];
    in[1] = globalpt[1];
    in[2] = globalpt[2];
    in[3] = 1;
    self->GetTransform()->MultiplyPoint(in,out);
    cout<<"out: "<<out[0]<<" "<<out[1]<<" "<<out[2]<<endl;
    // Get StructuredCoordinates for that point
    for (int k=0; k<3; k++) {
        x[k] = out[k]*spacing[k]+origin[k]; 
    }
    if (input->ComputeStructuredCoordinates(x,ijk,pcoord) ==0) {
        //Point is outside ROI, continue to next streamline point
        cout <<"Point outside ROI"<<endl;
        for (int comp =0; comp < numComp; comp++)
            outScalars->SetComponent(ptId,comp,0.0);
        continue;
    }
   cout<<" ijk: "<<ijk[0]<<" "<<ijk[1]<<" "<<ijk[2]<<endl;
   cout<<" pcoord: "<<pcoord[0]<<" "<<pcoord[1]<<" "<<pcoord[2]<<endl;
   // Choose Nearest Neigh
   for (int i = 0; i<3 ; i++) {
      if (pcoord[i]>0.5) {
         ijk[i] = ijk[i]+1;
         pcoord[i] = 1-pcoord[i];
      }
   }
   cout<<"Corrected ijk: "<<ijk[0]<<" "<<ijk[1]<<" "<<ijk[2]<<endl;
   cout<<"Corrected pcoord: "<<pcoord[0]<<" "<<pcoord[1]<<" "<<pcoord[2]<<endl;

   inPtrId = input->ComputePointId(ijk)*numComp;
   cout<<" inPtrId: "<<inPtrId<<endl;
   // GetInput pointer
   inPtr = (T *) input->GetScalarPointer();
   cout <<"Pointer"<<endl;

   //A compute kernel so we can apply to each component
   double sum = 0.0; 
   for (int kId = 0; kId < kernelSize; kId++) {
        // Reset previous kernelval to do multiplications.
        kernelval[kId] = 1.0;
        // Foreach Input component: compute input value
        val = 0;
        for (int comp = 0; comp < numComp; comp++) {
           //Foreach kernel point
           pos = inPtrId + neighPos[kId]+comp;
           if (pos < 0 || pos >= posmax)
                continue;
           valPtr = (T*) (inPtr + pos);
           val += fabs(*valPtr); 
        }
        // If all the components are zero; don't compute kernel there 
        if (val == 0) {
            kernelval[kId] = 0.0;
        } else {
            for (int aIdx = 0; aIdx < 3 ; aIdx++) {
                    d = (kernelId[aIdx][kId] - pcoord[aIdx]);
                    // d = (kernelId[aIdx][kId] - kernelId[aIdx][0]);
                    kernelval[kId] *= 1/(sigma[aIdx] *sqrt(2*Pi))*exp(- (d*d)/(2*sigma[aIdx]*sigma[aIdx]));
            }
            if (kId == 1) {
                cout <<"kernelId: "<<kernelId[0][kId]<<" "<<kernelId[0][kId]<<" "<<kernelId[0][kId]<<endl;
                cout <<"pcoord: "<<pcoord[0]<<" "<<pcoord[1]<<" "<<pcoord[2]<<endl;
                cout<<"kernelval: "<<kernelval[kId]<<endl;
            }
        }
     sum += kernelval[kId];
     }
     cout<<"Kernel sum: "<<sum<<endl;

   // Do convolution for each component
     for (int comp = 0; comp < numComp; comp++) {
        //Foreach kernel point
        value =0;
        for (int kId = 0; kId < kernelSize; kId++) {
           if (kernelval[kId] == 0)
             continue; 
           int pos = inPtrId + neighPos[kId]+comp;
           if (pos < 0 || pos >= posmax)
             continue;
           valPtr = (T*) (inPtr + pos);
           if (*valPtr == 0)
              continue;
           value += kernelval[kId]*(*valPtr);
        }
        outScalars->SetComponent(ptId,comp,value);
    }

} // Go to next point

//Deallocate data
delete kernelval;
delete neighPos;
for (int i=0; i<3; i++) {
    delete kernelId[i];
}

}


void vtkStreamlineConvolve2::Execute()
{

  vtkImageData *input = this->GetInput();
  void *inPtr = input->GetScalarPointer();
  
  if ( ! (input->GetPointData()->GetScalars()) )
    {
    vtkErrorMacro(<< "No scalar data to convolve");
    return;
    }

  vtkPolyData *str = this->GetStreamlines();
  if ( ! (str) ) 
    {
    vtkErrorMacro(<<"No streamlines to convolve with");
    }

  // Allocate output scalars
  if (this->GetOutput()->GetPointData()->GetScalars()) {
    this->GetOutput()->GetPointData()->GetScalars()->Delete();
  }
  vtkDoubleArray *outScalars = vtkDoubleArray::New();
  outScalars->SetNumberOfComponents(this->GetInput()->GetNumberOfScalarComponents());
  outScalars->SetNumberOfTuples(this->GetStreamlines()->GetNumberOfPoints());
  this->GetOutput()->GetPointData()->SetScalars(outScalars);
  outScalars->Delete();

  this->MultiThread((vtkImageData *) this->GetInput(), (vtkPolyData *) this->GetOutput());
}

struct vtkStreamlineConvolve2ThreadStruct
{
  vtkStreamlineConvolve2 *Filter;
  vtkImageData *Input;
  vtkPolyData *Output;
};

// this mess is really a simple function. All it does is call
// the ThreadedExecute method after setting the correct
// extent for this thread. Its just a pain to calculate
// the correct extent.
VTK_THREAD_RETURN_TYPE vtkStreamlineConvolve2ThreadedExecute( void *arg )
{
  vtkStreamlineConvolve2ThreadStruct *str;
  int  total;
  int threadId, threadCount;
  
  threadId = ((vtkMultiThreader::ThreadInfo *)(arg))->ThreadID;
  threadCount = ((vtkMultiThreader::ThreadInfo *)(arg))->NumberOfThreads;
  
  str = (vtkStreamlineConvolve2ThreadStruct *)(((vtkMultiThreader::ThreadInfo *)(arg))->UserData);
  


 // execute the actual tracking, assigning the appropriate range of paths
 // to each thread.
 total = str->Filter->GetNumberOfThreads();
 int np = str->Filter->GetStreamlines()->GetNumberOfPoints();

 int npperthread = (int) floor((double) (np / total));

 int range[2];
 cout<<" Number of Points: "<<np<<endl;
 cout<<" Number of Points per thread: "<<npperthread<<endl;

 range[0] = threadId*npperthread;
 range[1] = (threadId+1)*npperthread-1;
 
 // If this is the last thread, do the remaining job
 if (threadId == (np-1))
   range[1] = np-1;

 if (threadId < total)
    {
    str->Filter->ThreadedExecute(str->Input, str->Output, range, threadId);
    }
  // else
  //   {
  //   otherwise don't use this thread. Sometimes the threads dont
  //   break up very well and it is just as efficient to leave a 
  //   few threads idle.
  //   }

  return VTK_THREAD_RETURN_VALUE;
}


void vtkStreamlineConvolve2::MultiThread(vtkImageData *input, vtkPolyData *output)
{

  vtkStreamlineConvolve2ThreadStruct str;
  str.Filter = this;
  str.Input = input;
  str.Output = output;

  this->Threader->SetNumberOfThreads(this->NumberOfThreads);
  this->Threader->SetSingleMethod(vtkStreamlineConvolve2ThreadedExecute, &str);
  this->Threader->SingleMethodExecute();
}


//----------------------------------------------------------------------------
// This method is passed a input and output regions, and executes the filter
// algorithm to fill the output from the inputs.
// It just executes a switch statement to call the correct function for
// the regions data types.
void vtkStreamlineConvolve2::ThreadedExecute(vtkImageData *inData, 
                                              vtkPolyData *outData,
                                              int range[2], int id)
{
  void *inPtr = inData->GetScalarPointer();
  switch (inData->GetScalarType())
    {
    vtkTemplateMacro5(vtkStreamlineConvolve2Execute, this, inData, (VTK_TT *) (inPtr),
                      range,id);

    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }

}


void vtkStreamlineConvolve2::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  this->Superclass::PrintSelf(os, indent);
  
  os << indent << "Sigma: (" <<
    this->Sigma[0] << ", " <<
    this->Sigma[1] << ", " <<
    this->Sigma[2] << ")\n";

  os << indent << "Kernel Size: ";
        os << this->KernelSize;

}
