/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageBandedDistanceMap.cxx,v $
  Date:      $Date: 2006/01/06 17:56:38 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/
#include "vtkImageBandedDistanceMap.h"
#include <time.h>
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkImageBandedDistanceMap* vtkImageBandedDistanceMap::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageBandedDistanceMap");
  if(ret)
    {
    return (vtkImageBandedDistanceMap*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageBandedDistanceMap;
}


//----------------------------------------------------------------------------



//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageBandedDistanceMap::vtkImageBandedDistanceMap()
{

  this->Background = 0;
  this->Foreground = 1;
  this->HandleBoundaries = 1;
  this->Dimensionality = 2;
  this->SetMaximumDistanceToCompute(1);
}


//----------------------------------------------------------------------------
vtkImageBandedDistanceMap::~vtkImageBandedDistanceMap()
{

}

//----------------------------------------------------------------------------
// Description:
// Set up the kernel and matching mask (which contains distance from the
// center of the mask to each pixel in the mask). 
void vtkImageBandedDistanceMap::SetMaximumDistanceToCompute(int distance)
{
  if (distance < 1)
    {
      vtkErrorMacro (" can't compute a distance smaller than 1. ");
      distance = 1;
    }

  int kernelDim = 1 + 2*distance;

  if (this->Dimensionality != 3)
    {
      // don't bother with a 3-dimensional kernel
      this->SetKernelSize(kernelDim, kernelDim, 1);
    }
  else
    {
      this->SetKernelSize(kernelDim, kernelDim, kernelDim);
    }


  // for looping through mask:
  unsigned char *maskPtr = (unsigned char *)(this->GetMaskPointer());
  int maskInc0, maskInc1, maskInc2;
  this->GetMaskIncrements(maskInc0, maskInc1, maskInc2);
  int hoodIdx0, hoodIdx1, hoodIdx2;
  unsigned char *maskPtr0, *maskPtr1, *maskPtr2;

  //cout << "inc: " << maskInc0 << maskInc1 << maskInc2 << endl;
  //cout << "middle: " << this->KernelMiddle[0] << this->KernelMiddle[1] << this->KernelMiddle[2] <<endl;
  // set up the mask:
  maskPtr2 = maskPtr;
  for (hoodIdx2 = 0; hoodIdx2 < this->KernelSize[2]; ++hoodIdx2)
    {
      maskPtr1 = maskPtr2;
      for (hoodIdx1 = 0; hoodIdx1 < this->KernelSize[1]; ++hoodIdx1)
    {
      maskPtr0 = maskPtr1;
      for (hoodIdx0 = 0; hoodIdx0 < this->KernelSize[0]; ++hoodIdx0)
        {
          // calculate distance to center pixel of 'hood'.
          int dx = this->KernelMiddle[0] - hoodIdx0;
          int dy = this->KernelMiddle[1] - hoodIdx1;
          int dz = this->KernelMiddle[2] - hoodIdx2;

          //cout << "idx0: " << hoodIdx0 << " idx1: " << hoodIdx1 << " idx2: " << hoodIdx2 << " d: " << dist << endl;

          //*maskPtr0 = (unsigned char)sqrt(dx*dx + dy*dy + dz*dz);

          *maskPtr0 = (unsigned char)sqrt(dx*dx + dy*dy + dz*dz);

          maskPtr0 += maskInc0;
        }//for0
      maskPtr1 += maskInc1;
    }//for1
      maskPtr2 += maskInc2;
    }//for2        
  //cout << "done setting up mask!" << endl;
}

//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
// For every pixel in the foreground, if a neighbor is in the background,
// then the pixel becomes background.
template <class T>
static void vtkImageBandedDistanceMapExecute(vtkImageBandedDistanceMap *self,
                     vtkImageData *inData, T *inPtr,
                     vtkImageData *outData,
                     int outExt[6], int id)
{
  // For looping though output (and input) pixels.
  int outMin0, outMax0, outMin1, outMax1, outMin2, outMax2;
  int outIdx0, outIdx1, outIdx2;
  int inInc0, inInc1, inInc2;
  int outInc0, outInc1, outInc2;
  T *inPtr0, *inPtr1, *inPtr2;
  T *outPtr0, *outPtr1, *outPtr2;
  // For looping through hood pixels
  int hoodMin0, hoodMax0, hoodMin1, hoodMax1, hoodMin2, hoodMax2;
  int hoodIdx0, hoodIdx1, hoodIdx2;
  T *hoodPtr0, *hoodPtr1, *hoodPtr2;
  // For looping through the mask.
  unsigned char *maskPtr, *maskPtr0, *maskPtr1, *maskPtr2;
  int maskInc0, maskInc1, maskInc2;
  // The extent of the whole input image
  int inImageMin0, inImageMin1, inImageMin2;
  int inImageMax0, inImageMax1, inImageMax2;
  // Other
  //T backgnd = (T)(self->GetBackground());
  T foregnd = (T)(self->GetForeground());
  T pix;
  T *outPtr = (T*)outData->GetScalarPointerForExtent(outExt);
  unsigned long count = 0;
  unsigned long target;

  clock_t tStart, tEnd, tDiff;
  tStart = clock();

  // Get information to march through data
  inData->GetIncrements(inInc0, inInc1, inInc2); 
  self->GetInput()->GetWholeExtent(inImageMin0, inImageMax0, inImageMin1,
                   inImageMax1, inImageMin2, inImageMax2);
  outData->GetIncrements(outInc0, outInc1, outInc2); 
  outMin0 = outExt[0];   outMax0 = outExt[1];
  outMin1 = outExt[2];   outMax1 = outExt[3];
  outMin2 = outExt[4];   outMax2 = outExt[5];
    
  // Neighborhood around current voxel
  self->GetRelativeHoodExtent(hoodMin0, hoodMax0, hoodMin1, 
                  hoodMax1, hoodMin2, hoodMax2);

  // Set up mask info
  maskPtr = (unsigned char *)(self->GetMaskPointer());
  self->GetMaskIncrements(maskInc0, maskInc1, maskInc2);

  // in and out should be marching through corresponding pixels.
  inPtr = (T *)(inData->GetScalarPointer(outMin0, outMin1, outMin2));

  target = (unsigned long)((outMax2-outMin2+1)*(outMax1-outMin1+1)/50.0);
  target++;

  // Default output equal to the max distance+1
  int sizeX, sizeY, sizeZ;
  sizeX = outExt[1] - outExt[0] + 1; 
  sizeY = outExt[3] - outExt[2] + 1; 
  sizeZ = outExt[5] - outExt[4] + 1;
  memset(outPtr, self->GetMaximumDistanceToCompute()+1, sizeX*sizeY*sizeZ*sizeof(T));
  //memset(outPtr, 3, sizeX*sizeY*sizeZ*sizeof(T));
    
  // loop through pixels of output
  outPtr2 = outPtr;
  inPtr2 = inPtr;
  for (outIdx2 = outMin2; outIdx2 <= outMax2; outIdx2++)
    {
      outPtr1 = outPtr2;
      inPtr1 = inPtr2;
      for (outIdx1 = outMin1; 
       !self->AbortExecute && outIdx1 <= outMax1; outIdx1++)
    {
      if (!id) {
        if (!(count%target))
          self->UpdateProgress(count/(50.0*target));
        count++;
      }
      outPtr0 = outPtr1;
      inPtr0 = inPtr1;
      for (outIdx0 = outMin0; outIdx0 <= outMax0; outIdx0++)
        {
          pix = *inPtr0;

          // if this pixel is on the boundary
          if (pix == foregnd)
        {
          // Loop through neighborhood pixels of OUTPUT
          // Note: input pointer marches out of bounds.
          hoodPtr2 = outPtr0 + outInc0*hoodMin0 + outInc1*hoodMin1 
            + outInc2*hoodMin2;
          maskPtr2 = maskPtr;
          for (hoodIdx2 = hoodMin2; hoodIdx2 <= hoodMax2; ++hoodIdx2)
            {
              hoodPtr1 = hoodPtr2;
              maskPtr1 = maskPtr2;
              for (hoodIdx1 = hoodMin1; hoodIdx1 <= hoodMax1;    ++hoodIdx1)
            {
              hoodPtr0 = hoodPtr1;
              maskPtr0 = maskPtr1;
              for (hoodIdx0 = hoodMin0; hoodIdx0 <= hoodMax0; ++hoodIdx0)
                {
                  // handle boundaries
                  if (outIdx0 + hoodIdx0 >= inImageMin0 &&
                  outIdx0 + hoodIdx0 <= inImageMax0 &&
                  outIdx1 + hoodIdx1 >= inImageMin1 &&
                  outIdx1 + hoodIdx1 <= inImageMax1 &&
                  outIdx2 + hoodIdx2 >= inImageMin2 &&
                  outIdx2 + hoodIdx2 <= inImageMax2)
                {
                  // if distance from current pixel is less
                  // than previously found distance at this
                  // neighbor (in output image)
                  if (*maskPtr0 < *hoodPtr0)
                    {
                      *hoodPtr0 = *maskPtr0;
                    }
                }
                  hoodPtr0 += outInc0;
                  maskPtr0 += maskInc0;
                }//for0
              hoodPtr1 += outInc1;
              maskPtr1 += maskInc1;
            }//for1
              hoodPtr2 += outInc2;
              maskPtr2 += maskInc2;
            }//for2
        }//if
          inPtr0 += inInc0;
          outPtr0 += outInc0;
        }//for0
      inPtr1 += inInc1;
      outPtr1 += outInc1;
    }//for1
      inPtr2 += inInc2;
      outPtr2 += outInc2;
    }//for2

  tEnd = clock();
  tDiff = tEnd - tStart;
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageBandedDistanceMap::ThreadedExecute(vtkImageData *inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
    void *inPtr = inData->GetScalarPointerForExtent(outExt);
  
    switch (inData->GetScalarType())
    {
    case VTK_DOUBLE:
        vtkImageBandedDistanceMapExecute(this, inData, (double *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_FLOAT:
        vtkImageBandedDistanceMapExecute(this, inData, (float *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_LONG:
        vtkImageBandedDistanceMapExecute(this, inData, (long *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_INT:
        vtkImageBandedDistanceMapExecute(this, inData, (int *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_UNSIGNED_INT:
        vtkImageBandedDistanceMapExecute(this, inData, (unsigned int *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_SHORT:
        vtkImageBandedDistanceMapExecute(this, inData, (short *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_UNSIGNED_SHORT:
        vtkImageBandedDistanceMapExecute(this, inData, (unsigned short *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_CHAR:
        vtkImageBandedDistanceMapExecute(this, inData, (char *)(inPtr), 
            outData, outExt, id);
        break;
    case VTK_UNSIGNED_CHAR:
        vtkImageBandedDistanceMapExecute(this, inData, (unsigned char *)(inPtr), 
            outData, outExt, id);
        break;
    default:
        vtkErrorMacro(<< "Execute: Unknown input ScalarType");
        return;
    }
}
