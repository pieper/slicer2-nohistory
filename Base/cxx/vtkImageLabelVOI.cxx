/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageLabelVOI.cxx,v $
  Date:      $Date: 2006/02/22 22:54:50 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#include "vtkImageLabelVOI.h"
#include "vtkObjectFactory.h"
#include "vtkImageData.h"

//------------------------------------------------------------------------------
vtkImageLabelVOI* vtkImageLabelVOI::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageLabelVOI");
  if(ret)
    {
    return (vtkImageLabelVOI*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageLabelVOI;
}


//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageLabelVOI::vtkImageLabelVOI()
{
  this->c1x = this->c1y = this->c1z = 0;
  this->c2x = this->c2y = this->c2z = 0;
}

//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageLabelVOIExecute(vtkImageLabelVOI *self,
                     vtkImageData *inData, T *inPtr,
                     vtkImageData *outData, 
                     int outExt[6], int id)
{
  T *outPtr = (T *)outData->GetScalarPointerForExtent(outExt);
  // looping
  int outIncX, outIncY, outIncZ;
  int idxX, idxY, idxZ, minX, minY, minZ, maxX, maxY, maxZ;
  
  // Get increments to march through data 
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
  
  int c1[3], c2[3];
  self->GetCorner1(c1);
  self->GetCorner2(c2);
  
  if(c1[0] < c2[0])
    {
      minX = c1[0];
      maxX = c2[0];
    }
  else
    {
      minX = c2[0];
      maxX = c1[0];
    }
  
  if(c1[1] < c2[1])
    {
      minY = c1[1];
      maxY = c2[1];
    }
  else
    {
      minY = c2[1];
      maxY = c1[1];
    }
  
  if(c1[2] < c2[2])
    {
      minZ = c1[2];
      maxZ = c2[2];
    }
  else
    {
      minZ = c2[2];
      maxZ = c1[2];
    }
  
  int method = self->GetMethod();
  // Loop through output pixels
  for (idxZ = outExt[4]; idxZ <= outExt[5]; idxZ++)
    {
      for (idxY = outExt[2]; !self->AbortExecute && idxY <= outExt[3]; idxY++)
    {
      for (idxX = outExt[0]; idxX <= outExt[1]; idxX++)
        {
          if((idxX >= minX) && (idxX <= maxX)
         && (idxY >= minY) && (idxY <= maxY)
         && (idxZ >= minZ) && (idxZ <= maxZ))
        {
          if(method == 0)
            *outPtr = *inPtr;
          else
            *outPtr = (T)0;
        }
          else
        {
          if(method == 0)
            *outPtr = (T)0;
          else
            *outPtr = *inPtr;
        }
          
          outPtr++;
          inPtr++;
        }
      outPtr += outIncY;
      inPtr += outIncY;
    }
      outPtr += outIncZ;
      inPtr += outIncZ;
    }
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageLabelVOI::ThreadedExecute(vtkImageData *inData, 
                       vtkImageData *outData,
                       int outExt[6], int id)
{
  // Check Single component
  int x1;
  x1 = inData->GetNumberOfScalarComponents();
  if (x1 != 1) {
    vtkErrorMacro(<<"Input has "<<x1<<" instead of 1 scalar component.");
    return;
  }
  
  void *inPtr = inData->GetScalarPointerForExtent(outExt);
  
  switch (inData->GetScalarType())
    {
    case VTK_DOUBLE:
      vtkImageLabelVOIExecute(this, inData, (double *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_FLOAT:
      vtkImageLabelVOIExecute(this, inData, (float *)(inPtr), 
                  outData, outExt, id);
      break;        
    case VTK_LONG:
      vtkImageLabelVOIExecute(this, inData, (long *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_UNSIGNED_LONG:
      vtkImageLabelVOIExecute(this, inData, (unsigned long *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_INT:
      vtkImageLabelVOIExecute(this, inData, (int *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_UNSIGNED_INT:
      vtkImageLabelVOIExecute(this, inData, (unsigned int *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_SHORT:
      vtkImageLabelVOIExecute(this, inData, (short *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_UNSIGNED_SHORT:
      vtkImageLabelVOIExecute(this, inData, (unsigned short *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_CHAR:
      vtkImageLabelVOIExecute(this, inData, (char *)(inPtr), 
                  outData, outExt, id);
      break;
    case VTK_UNSIGNED_CHAR:
      vtkImageLabelVOIExecute(this, inData, (unsigned char *)(inPtr), 
                  outData, outExt, id);
      break;
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
      return;
    }
}

void vtkImageLabelVOI::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);
  
  os << indent << "Corner1: " << this->c1x << " " << this->c1y << " " << this->c1z << "\n";
  os << indent << "Corner2: " << this->c2x << " " << this->c2y << " " << this->c2z << "\n";
}

