/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageDouble2D.cxx,v $
  Date:      $Date: 2006/02/23 01:43:32 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
#include "vtkImageDouble2D.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"


//------------------------------------------------------------------------------
vtkImageDouble2D* vtkImageDouble2D::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageDouble2D");
  if(ret)
    {
    return (vtkImageDouble2D*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageDouble2D;
}


//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageDouble2D::vtkImageDouble2D()
{
}

//----------------------------------------------------------------------------
void vtkImageDouble2D::ExecuteInformation(vtkImageData *inData,
    vtkImageData *outData)
{
    vtkFloatingPointType *spacing, outSpacing[3];
    int idx, *inExt, outExt[6], mag[3];

    inExt = inData->GetWholeExtent();
    spacing = inData->GetSpacing();

    mag[0] = mag[1] = 2;
    mag[2] = 1;
    
    // Magnify the output size
    for (idx = 0; idx < 3; idx++)
    {
        // Scale the output extent
        outExt[idx*2]   = inExt[idx*2] * mag[idx];
        outExt[idx*2+1] = outExt[idx*2] + 
            (inExt[idx*2+1] - inExt[idx*2] + 1) * mag[idx] - 1;
    
        // Change the data spacing
        outSpacing[idx] = spacing[idx] / (vtkFloatingPointType)mag[idx];
    }
  
    outData->SetWholeExtent(outExt);
    outData->SetSpacing(outSpacing);
}

void vtkImageDouble2D::ComputeInputUpdateExtent(int inExt[6], int outExt[6])
{
  int idx;
  
  for (idx = 0; idx < 3; idx++)
  {
    inExt[idx*2]   = outExt[idx*2]   / 2;
    inExt[idx*2+1] = outExt[idx*2+1] / 2;
  }
}

template <class T>
static void vtkImageDouble2DExecute(vtkImageDouble2D *self,
                     vtkImageData *inData, T *inPtr, int *inExt,
                     vtkImageData *outData, T *outPtr, int outExt[6], int id)
{
    int idxX, inMaxX, idxY, inMaxY, outMaxX, outMaxY, numComps, numComps2;
  int rowLength, inRowLength, yum, scalarSize, inX, inY;
    int outIncX, outIncY, outIncZ, inIncX, inIncY, inIncZ;
  T *ptr;

    // find the region to loop over
    numComps = inData->GetNumberOfScalarComponents();
  numComps2 = numComps*2;
    scalarSize = numComps*sizeof(T);
  rowLength = (outExt[3]-outExt[2]+1)*numComps;
    inRowLength = (inExt[1]-inExt[0]+1)*numComps;
  yum = rowLength + numComps;

    // Get increments to march through data 
    outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
    inData->GetContinuousIncrements(inExt, inIncX, inIncY, inIncZ);

    inMaxX  = inExt[1]-inExt[0]; 
    inMaxY  = inExt[3]-inExt[2];
    outMaxX = outExt[1]-outExt[0]; 
    outMaxY = outExt[3]-outExt[2];

  // If the input extent is half the output extent, then go fast
  if ((inMaxX+1)*2 == outMaxX+1 && (inMaxY+1)*2 == outMaxY+1)
  {
    // Loop through input pixels
      for (idxY = 0; !self->AbortExecute && idxY <= inMaxY; idxY++)
      {
          for (idxX = 0; idxX <= inMaxX; idxX++)
          {
        memcpy(outPtr,             inPtr, scalarSize);
        memcpy(&outPtr[numComps],  inPtr, scalarSize);
        memcpy(&outPtr[rowLength], inPtr, scalarSize);
        memcpy(&outPtr[yum],       inPtr, scalarSize);

        outPtr += numComps2;
        inPtr += numComps;
      }
      inPtr += inIncY;
      outPtr += outIncY*2 + rowLength;
    }
  } 
  else 
  {
      // Loop through output pixels
      for (idxY = outExt[2]; idxY <= outExt[3]; idxY++)
      {
          for (idxX = outExt[0]; idxX <= outExt[1]; idxX++)
          {
              inX = idxX >> 1;
              inY = idxY >> 1;

              ptr = &inPtr[inY*inRowLength + inX*numComps];
              memcpy(outPtr, ptr, scalarSize);
              outPtr += numComps;
          }
          outPtr += outIncY;
      }
  }
}


//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageDouble2D::ThreadedExecute(vtkImageData *inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
    int *inExt = inData->GetExtent();
    void *inPtr = inData->GetScalarPointerForExtent(inExt);
    void *outPtr = outData->GetScalarPointerForExtent(outExt);

    // Ensure input is 2D
    if (inExt[5] != inExt[4]) {
        vtkErrorMacro("ExecuteImageInformation: Input must be 2D.");
        return;
    }

  switch (inData->GetScalarType())
    {
    case VTK_DOUBLE:
        vtkImageDouble2DExecute(this, inData, (double *)inPtr, inExt,
            outData, (double *)(outPtr), outExt, id);
        break;
    case VTK_FLOAT:
        vtkImageDouble2DExecute(this, inData, (float *)inPtr, inExt,
            outData, (float *)(outPtr), outExt, id);
        break;
    case VTK_LONG:
        vtkImageDouble2DExecute(this, inData, (long *)inPtr, inExt,
            outData, (long *)(outPtr), outExt, id);
        break;
    case VTK_UNSIGNED_LONG:
        vtkImageDouble2DExecute(this, inData, (unsigned long *)inPtr, inExt,
            outData, (unsigned long *)(outPtr), outExt, id);
        break;
    case VTK_INT:
        vtkImageDouble2DExecute(this, inData, (int *)inPtr,  inExt,
            outData, (int *)(outPtr), outExt, id);
        break;
    case VTK_UNSIGNED_INT:
        vtkImageDouble2DExecute(this, inData, (unsigned int *)inPtr,  inExt,
            outData, (unsigned int *)(outPtr), outExt, id);
        break;
    case VTK_SHORT:
        vtkImageDouble2DExecute(this, inData, (short *)inPtr,  inExt,
            outData, (short *)(outPtr), outExt, id);
        break;
    case VTK_UNSIGNED_SHORT:
        vtkImageDouble2DExecute(this, inData, (unsigned short *)inPtr, 
             inExt,outData, (unsigned short *)(outPtr), outExt, id);
        break;
    case VTK_CHAR:
        vtkImageDouble2DExecute(this, inData, (char *)inPtr, 
             inExt,outData, (char *)(outPtr), outExt, id);
        break;
    case VTK_UNSIGNED_CHAR:
        vtkImageDouble2DExecute(this, inData, (unsigned char *)inPtr, 
             inExt,outData, (unsigned char *)(outPtr), outExt, id);
        break;
    default:
        vtkGenericWarningMacro("Execute: Unknown input ScalarType");
        return;
    }
}

//----------------------------------------------------------------------------
void vtkImageDouble2D::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);
}

