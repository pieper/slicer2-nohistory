/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageMosaik.cxx,v $
  Date:      $Date: 2006/01/06 17:57:22 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
#include "vtkImageMosaik.h"
#include "stdlib.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkImageMosaik* vtkImageMosaik::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageMosaik");
  if(ret)
  {
    return (vtkImageMosaik*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageMosaik;
}

// Description:
// Construct object to set initial opacity and rectangular subdivision width/height
//----------------------------------------------------------------------------
vtkImageMosaik::vtkImageMosaik()
{
  this->opacity = 1;

  this->divisionWidth = 126;
  this->divisionHeight = 126;
}

//----------------------------------------------------------------------------
vtkImageMosaik::~vtkImageMosaik()
{
}

//----------------------------------------------------------------------------
// return mosaik opacity
double vtkImageMosaik::GetOpacity()
{
  return this->opacity;
}

//----------------------------------------------------------------------------
// set mosaik opacity
void vtkImageMosaik::SetOpacity(double newOpacity)
{
  this->opacity = newOpacity;
  this->Modified();
}

//----------------------------------------------------------------------------
// return mosaik subdivision width
int vtkImageMosaik::GetDivisionWidth()
{
  return this->divisionWidth;
}

//----------------------------------------------------------------------------
// return mosaik subdivision height
int vtkImageMosaik::GetDivisionHeight()
{
  return this->divisionHeight;
}

//----------------------------------------------------------------------------
// set mosaik subdivision width
void vtkImageMosaik::SetDivisionWidth(int width)
{
  this->divisionWidth = width;
  this->Modified();
}

//----------------------------------------------------------------------------
// set mosaik subdivision height
void vtkImageMosaik::SetDivisionHeight(int height)
{
  this->divisionHeight = height;
  this->Modified();
}


//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data
template <class T>
static void vtkImageMosaikExecute(vtkImageMosaik *self,
  vtkImageData *inData, T *inPtr, int inExt[6],
  vtkImageData *outData, T* outPtr,
  int outExt[6], int layer, int firstLayer)
{
  // c is a counter over image components
  // idxX, idxY and idxZ are counters to move the data pointer over
  // the image pixels
  // maxX, maxY and maxZ represent the number of pixels in a row
  // following respectively X, Y and Z
  int c, idxX, idxY, idxZ, maxX, maxY, maxZ;

  // ncomp is the number of components per pixel
  // rowLength is the number of values in a pixel row ((maxX+1) * ncomp)
  // size is the scalar size
  // row size is number of bytes in a pixel row (rowLength * size)
  // pixSize is the number of bytes in a pixel (ncomp * size)
  int ncomp, rowLength, size, rowSize, pixSize;

  // inIncX, inIncY and inIncZ are increments to march through input data
  // outIncX, outIncY and outIncZ are increments to march through output data
  int inIncX, inIncY, inIncZ, outIncX, outIncY, outIncZ, cpyIncY, cpyIncZ;

  // alpha is the opacity coefficient of the Fore volume (belongs to [0,1])
  // beta (= 1 - alpha) is the opacity coefficient of the Back volume (belongs to [0,1])
  double alpha, beta;

  // width and height are the number of pixel for the mosaik subdivisions
  int width, height;

  // Those values indicate if pixels have to be blended/overwrited with/by
  // the fore layer. As a matter of fact, the pixels values corresponding to some
  // mosaik subdivision contain only back layer values, while others are the result
  // of a blending between back and fore layer.
  // divX (resp. divY) is the result of an integer division between pixel coordinates
  // following X (resp. Y) and width (resp. height).
  // remX (resp. remY) is the parity of divX (resp. divY). It is the remainder of
  // an integer division of divX (resp. divY) per 2.
  int divX, divY;
  int remX, remY;

  // find the region to loop over
  maxX = outExt[1] - outExt[0];
  maxY = inExt[3] - inExt[2];
  maxZ = inExt[5] - inExt[4];

  // compute variables used cpying the first layer
  ncomp = inData->GetNumberOfScalarComponents();
  rowLength = (maxX+1)*ncomp;
  size = inData->GetScalarSize();
  rowSize = rowLength * size;
  pixSize = ncomp * size;

  // get increments to loop over image data
  inData->GetContinuousIncrements(inExt, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // adjust increments for copying loop
  cpyIncY = outIncY + rowLength;
  cpyIncZ = outIncZ * size;

  inPtr  = (T*)inData->GetScalarPointerForExtent(outExt);
  outPtr = (T*)outData->GetScalarPointerForExtent(outExt);

  // The first layer just gets copied
  if (firstLayer)
  {
    for (idxZ = 0; idxZ <= maxZ; idxZ++)
    {
      //cout << "idxZ : "<<idxZ<<endl;
      for (idxY = 0; idxY <= maxY; idxY++)
      {
        memcpy(outPtr, inPtr, rowSize);
        inPtr += cpyIncY;
        outPtr += cpyIncY;
      }//for y
      outPtr += cpyIncZ;
      inPtr += cpyIncZ;
    }//for z
  }

  // Blend wherever alpha is not 0.
  // If there is no alpha (ie: not 4 components), then blend wherever
  // there is a non-zero component.
  // Speed up the special cases by doing nothing when opacity=0, and
  // overwriting when opacity=1.
  else
  {
    alpha = self->GetOpacity();
    beta = 1.0 - alpha;
    width = self->GetDivisionWidth();
    height = self->GetDivisionHeight();

    // Overwrite
    if (alpha == 1.0)
    {
       for (idxZ = 0; idxZ <= maxZ; idxZ++) {
          for (idxY = 0; idxY <= maxY; idxY++) {
             for (idxX = 0; idxX <= maxX; idxX++)
             {
                divX = idxX / width;
                divY = idxY / height;
                remX = divX % 2;
                remY = divY % 2;
                if ((remX && remY) || (!remX && !remY))
                {
                   memcpy(outPtr, inPtr, pixSize);
                }
                inPtr  += ncomp;
                outPtr += ncomp;
             }//for x
             outPtr += outIncY;
             inPtr += outIncY;
          }//for y
          outPtr += outIncZ;
          inPtr += outIncZ;
       }//for z
    }
    // Blend (alpha != 1 && alpha != 0)
    // implicitely, whan alpha is null, do nothing
    else if (alpha != 0)
    {
       for (idxZ = 0; idxZ <= maxZ; idxZ++) {
          for (idxY = 0; idxY <= maxY; idxY++) {
             for (idxX = 0; idxX <= maxX; idxX++)
             {
                divX = idxX / width;
                divY = idxY / height;
                remX = divX % 2;
                remY = divY % 2;

                if ((remX && remY) || (!remX && !remY))
                {
                   for (c=0; c<ncomp; c++)
                   {
                      outPtr[c] = (T)(outPtr[c]*beta + inPtr[c]*alpha);
                   }
                }
                inPtr  += ncomp;
                outPtr += ncomp;
             }//for x
             outPtr += outIncY;
             inPtr += outIncY;
          }//for y
          outPtr += outIncZ;
          inPtr += outIncZ;
       }//for z
    }//blend
  }//not first layer
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output regions, and executes the filter
// algorithm to fill the output from the inputs.
// It just executes a switch statement to call the correct function for
// the regions data types.

void vtkImageMosaik::ExecuteData(vtkDataObject *data)
{
  int inExt[6];
  int outExt[6];
  int firstFound, first;
  int layer, x1, y1, z1, x2, y2, z2, s1, s2, c1, c2;
  void *inPtr, *outPtr;

  vtkImageData **inData = (vtkImageData**)this->GetInputs();
  vtkImageData *outData = this->AllocateOutputData(data);

  outData->GetExtent(outExt);

  s1 = outData->GetScalarType();
  c1 = outData->GetNumberOfScalarComponents();
  x1 = outExt[1]-outExt[0]+1;
  y1 = outExt[3]-outExt[2]+1;
  z1 = outExt[5]-outExt[4]+1;

  // Loop thru each layer (input)
  firstFound = first = 0;
  for (layer=0; layer < this->NumberOfInputs; layer++)
  {
    // If layer exists
    if (inData[layer] != NULL)
    {
      // See if this is the first non-NULL layer
      if (firstFound == 0)
      {
        firstFound = 1;
        first = 1;
      }
      else
      {
        first = 0;
      }

      // Check that the extent, scalar type, and number of components
      // matches what the output has

      memcpy(inExt, outExt, 6*sizeof(int));
      this->ComputeInputUpdateExtent(inExt, outExt, layer);
      s2 = inData[layer]->GetScalarType();
      c2 = inData[layer]->GetNumberOfScalarComponents();
      x2 = inExt[1]-inExt[0]+1;
      y2 = inExt[3]-inExt[2]+1;
      z2 = inExt[5]-inExt[4]+1;

      // Extent
      if (x1 != x2 || y1 != y2 || z1 != z2)
      {
        vtkErrorMacro(<< "Layer "<<layer<<" extent is "<<x2<<"x"<<y2<<"x"<<z2
          << " instead of "<<x1<<"x"<<y1<<"x"<<z1);
        return;
      }

      // components
      if (c2 != c1)
      {
        vtkErrorMacro(<<"Layer "<<layer<<" Input has "<<c2<<
          " instead of "<<c1<<" scalar components.");
         return;
      }

      // scalar type
      if (s2 != s1)
      {
        vtkErrorMacro(<<"Layer "<<layer<<" Input has "<<s2<<
          " instead of "<<s1<<" scalar type.");
         return;
      }

      inPtr  = inData[layer]->GetScalarPointerForExtent(inExt);
      outPtr = outData->GetScalarPointerForExtent(outExt);

      // Execute
      switch (inData[layer]->GetScalarType())
      {
        case VTK_FLOAT:
          vtkImageMosaikExecute(this, inData[layer], (float *)(inPtr),
            inExt, outData, (float *) outPtr, outExt, layer, first);
          break;
        case VTK_INT:
          vtkImageMosaikExecute(this, inData[layer], (int *)(inPtr),
            inExt, outData, (int *) outPtr, outExt, layer, first);
          break;
        case VTK_SHORT:
          vtkImageMosaikExecute(this, inData[layer], (short *)(inPtr),
            inExt, outData, (short *) outPtr, outExt, layer, first);
          break;
        case VTK_UNSIGNED_SHORT:
          vtkImageMosaikExecute(this, inData[layer], (unsigned short *)(inPtr),
            inExt, outData, (unsigned short *) outPtr, outExt, layer, first);
          break;
        case VTK_UNSIGNED_CHAR:
          vtkImageMosaikExecute(this, inData[layer], (unsigned char *)(inPtr),
            inExt, outData, (unsigned char *) outPtr, outExt, layer, first);
          break;
        case VTK_CHAR:
          vtkImageMosaikExecute(this, inData[layer],  (char *)(inPtr),
            inExt, outData, (char *) outPtr, outExt, layer, first);
          break;
        case VTK_UNSIGNED_LONG:
          vtkImageMosaikExecute(this, inData[layer], (unsigned long *)(inPtr),
            inExt, outData, (unsigned long *) outPtr, outExt, layer, first);
          break;
        case VTK_LONG:
          vtkImageMosaikExecute(this, inData[layer], (long *)(inPtr),
            inExt, outData, (long *) outPtr, outExt, layer, first);
          break;
        case VTK_DOUBLE:
          vtkImageMosaikExecute(this, inData[layer], (double *)(inPtr),
            inExt, outData, (double *) outPtr, outExt, layer, first);
          break;
        case VTK_UNSIGNED_INT:
          vtkImageMosaikExecute(this, inData[layer], (unsigned int *)(inPtr),
            inExt, outData, (unsigned int *) outPtr, outExt, layer, first);
          break;
        default:
          vtkErrorMacro(<< "Execute: Unknown input ScalarType");
          return;
      }
    }
  }
}

void vtkImageMosaik::PrintSelf(ostream& os, vtkIndent indent)
{
  os << indent << "vtkImageMosaik\n";
  vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "Opacity: " << this->opacity<< "\n";

  os << indent << "Division width : " << this->divisionWidth<< "\n";

  os << indent << "Division height : " << this->divisionHeight<< "\n";
}

