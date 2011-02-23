/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageZoom2D.cxx,v $
  Date:      $Date: 2006/02/23 01:43:34 $
  Version:   $Revision: 1.12 $

=========================================================================auto=*/
#include "vtkImageZoom2D.h"

#include "vtkObjectFactory.h"
#include "vtkImageData.h"

//------------------------------------------------------------------------------
vtkImageZoom2D* vtkImageZoom2D::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageZoom2D");
  if(ret)
  {
    return (vtkImageZoom2D*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageZoom2D;
}

//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageZoom2D::vtkImageZoom2D()
{
  this->Magnification = 1.0;
  this->AutoCenterOn();

  for (int i=0; i<2; i++) 
  {
    this->Step[i] = 0;
    this->Origin[i] = 0;
    this->Center[i] = 0;
    this->OrigPoint[i] = 0;
    this->ZoomPoint[i] = 0;
  }
}


//----------------------------------------------------------------------------

void vtkImageZoom2D::ExecuteInformation(vtkImageData *inData, 
                       vtkImageData *outData)
{
  int i;
  vtkFloatingPointType *spacing, outSpacing[3];

  // Change output spacing
  if (this->Magnification == 0.0) 
  {
    this->Magnification = 1.0;
  }
  spacing = inData->GetSpacing();
  for (i = 0; i < 3; i++) 
  {
    outSpacing[i] = spacing[i] / this->Magnification;
  }
  outData->SetSpacing(outSpacing);
}

//----------------------------------------------------------------------------

// x,y is a Zoom point
void vtkImageZoom2D::SetZoomPoint(int x, int y)
{
  this->ZoomPoint[0] = x;
  this->ZoomPoint[1] = y;
  this->OrigPoint[0] = (int)(this->Origin[0] + this->Step[0]*(vtkFloatingPointType)x + 0.49);
  this->OrigPoint[1] = (int)(this->Origin[1] + this->Step[1]*(vtkFloatingPointType)y + 0.49);
}

#define NBITS1            16
#define MULTIPLIER1       65536.0f
#define FLOAT_TO_FAST1(x) (int)((x) * MULTIPLIER1)
#define FAST1_TO_FLOAT(x) ((x) / MULTIPLIER1)
#define FAST1_TO_INT(x)   ((x) >> NBITS1)
#define INT_TO_FAST1(x)   ((x) << NBITS1)
#define FAST1_MULT(x, y)  (((x) * (y)) >> NBITS1)

//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageZoom2DExecute(vtkImageZoom2D *self,
  vtkImageData *inData, T *inPtr, int inExt[6],
  vtkImageData *outData, T* outPtr, 
  int outExt[6], int wExt[6], int id, int integerMath)
{
  int i, idxX, idxY, maxX, maxY, inRowLength, inMaxX, inMaxY;
  int outIncX, outIncY, outIncZ, numComps;
  vtkFloatingPointType scale, step[2], origin[2], center[2], xRewind, invMag;
  vtkFloatingPointType x, y;
  long idx, nx, ny, nx2, ny2, xi, yi;

  // find whole size of output for boundary checking
  nx = wExt[1] - wExt[0] + 1; 
  ny = wExt[3] - wExt[2] + 1; 
  nx2 = nx - 2;
  ny2 = ny - 2;

  // find the region to loop over
  numComps = inData->GetNumberOfScalarComponents();
  maxX = outExt[1];
  maxY = outExt[3];
  inMaxX = inExt[1] - inExt[0]; 
  inMaxY = inExt[3] - inExt[2]; 
  inRowLength = (inMaxX+1)*numComps;
  int scalarSize = numComps*sizeof(T);

  // We will walk through zoom space and calculate xy space
  // coordinates to obtain source pixels.

  invMag = self->GetMagnification();
  if (invMag == 0.0) 
  {
    invMag = 1.0;
  }
  invMag = 1.0 / invMag;

  // step vector
  step[0] = invMag;
  step[1] = invMag;
    
  // If AutoCenter is on, then use the center of the input
  if (self->GetAutoCenter()) 
  {
    self->SetCenter(nx/2, ny/2);
  }
  self->GetCenter(center);
  
  // Find origin (upper left) of zoom space in terms of xy space coordinates
  origin[0] = center[0] - nx*step[0] / 2.0;
  origin[1] = center[1] - ny*step[1] / 2.0;
    
  // Return points to the user
  for (i=0; i<2; i++) 
  {
    self->SetOrigin(origin);
    self->SetStep(step);
  }

  // Advance to the origin of this output extent (used for threading)
  // x
  scale = (vtkFloatingPointType)(outExt[0]-wExt[0])/(vtkFloatingPointType)(wExt[1]-wExt[0]+1);
  origin[0] = origin[0] + scale*nx*step[0];
  scale = (vtkFloatingPointType)(outExt[2]-wExt[2])/(vtkFloatingPointType)(wExt[3]-wExt[2]+1);    
  origin[1] = origin[1] + scale*ny*step[1];

  // Initialize zoom coords x, y to origin
  x = origin[0];
  y = origin[1];

  // Get increments to march through data 
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  if (integerMath)
  {
    int fround, fx, fy, fxStep, fyStep, fxRewind;
   
    // Convert vtkFloatingPointType to fast
    fx = FLOAT_TO_FAST1(x);
    fy = FLOAT_TO_FAST1(y);
    fxStep = FLOAT_TO_FAST1(step[0]);
    fyStep = FLOAT_TO_FAST1(step[1]);
    fround = FLOAT_TO_FAST1(0.49);

    // Loop through output pixels
    for (idxY = outExt[2]; idxY <= maxY; idxY++)
    {
      fxRewind = fx;

      for (idxX = outExt[0]; idxX <= maxX; idxX++)
      {
        // Compute integer parts of volume coordinates
        xi = FAST1_TO_INT(fx + fround);
        yi = FAST1_TO_INT(fy + fround);

        // Test if coordinates are outside volume
        if ((xi < 0) || (yi < 0) || (xi > nx2) || (yi > ny2))
        {
          memset(outPtr, 0, scalarSize);
        }
        else 
        {
          idx = yi*inRowLength + xi*numComps;
          memcpy(outPtr, &inPtr[idx], scalarSize);
        }
        outPtr += numComps;
        fx += fxStep;
      }
      outPtr += outIncY;
      fx = fxRewind;
      fy += fyStep;
    }
  }
  else
  {
    // Loop through output pixels
    for (idxY = outExt[2]; idxY <= maxY; idxY++)
    {
      xRewind = x;
      for (idxX = outExt[0]; idxX <= maxX; idxX++)
      {
        // Compute integer parts of volume coordinates
        xi = (int)(x + 0.49);
        yi = (int)(y + 0.49);

        // Test if coordinates are outside volume
        if ((xi < 0) || (yi < 0) || (xi > nx2) || (yi > ny2))
        {
          memset(outPtr, 0, scalarSize);
        }
        else 
        {
          idx = yi*inRowLength + xi*numComps;
          memcpy(outPtr, &inPtr[idx], scalarSize);
        }
        outPtr += numComps;
        x += step[0];
      }
      outPtr += outIncY;
      x = xRewind;
      y += step[1];
    }
  }
}


//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageZoom2D::ThreadedExecute(vtkImageData *inData, 
  vtkImageData *outData,
  int outExt[6], int id)
{
  int *inExt   = inData->GetExtent();
  void *inPtr  = inData->GetScalarPointerForExtent(inExt);
  void *outPtr = outData->GetScalarPointerForExtent(outExt);
  int wExt[6];
  outData->GetWholeExtent(wExt);
  
  // Ensure intput is 2D
  if (inExt[5] != inExt[4]) 
  {
    vtkErrorMacro("ThreadedExecute: Input must be 2D.");
    return;
  }

  switch (inData->GetScalarType())
  {
    case VTK_FLOAT:
      vtkImageZoom2DExecute(this, inData, (float *)(inPtr), inExt, 
        outData, (float *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_INT:
      vtkImageZoom2DExecute(this, inData, (int *)(inPtr),  inExt, 
        outData, (int *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_SHORT:
      vtkImageZoom2DExecute(this, inData, (short *)(inPtr),  inExt, 
        outData, (short *) outPtr, outExt, wExt, id, 1);
      break;
    case VTK_UNSIGNED_SHORT:
      vtkImageZoom2DExecute(this, inData, (unsigned short *)(inPtr),  inExt, 
        outData, (unsigned short *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_UNSIGNED_CHAR:
      vtkImageZoom2DExecute(this, inData, (unsigned char *)(inPtr), inExt,  
        outData, (unsigned char *) outPtr, outExt, wExt, id, 1);
      break;
    case VTK_CHAR:
      vtkImageZoom2DExecute(this, inData,  (char *)(inPtr), inExt,  
        outData, (char *) outPtr, outExt, wExt, id, 1);
      break;
    case VTK_UNSIGNED_LONG:
      vtkImageZoom2DExecute(this, inData, (unsigned long *)(inPtr), inExt,  
        outData, (unsigned long *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_LONG:
      vtkImageZoom2DExecute(this, inData, (long *)(inPtr), inExt,  
        outData, (long *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_DOUBLE:
      vtkImageZoom2DExecute(this, inData, (double *)(inPtr), inExt,  
        outData, (double *) outPtr, outExt, wExt, id, 0);
      break;
    case VTK_UNSIGNED_INT:
      vtkImageZoom2DExecute(this, inData, (unsigned int *)(inPtr), inExt,  
        outData, (unsigned int *) outPtr, outExt, wExt, id, 0);
      break;
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
      return;
  }  
}

//----------------------------------------------------------------------------
void vtkImageZoom2D::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);
  
  os << indent << "Zoom Point X:   " << this->ZoomPoint[0] << "\n";
  os << indent << "Zoom Point Y:   " << this->ZoomPoint[1] << "\n";
  os << indent << "Orig Point X:   " << this->OrigPoint[0] << "\n";
  os << indent << "Orig Point Y:   " << this->OrigPoint[1] << "\n";
  os << indent << "Center X:       " << this->Center[0] << "\n";
  os << indent << "Center Y:       " << this->Center[1] << "\n";
  os << indent << "AutoCenter:     " << this->AutoCenter << "\n";
  os << indent << "Magnification:  " << this->Magnification << "\n";
  os << indent << "Step:           " << this->Step[0] << "," << \
    this -> Step[1] << "\n";
  os << indent << "Origin:         " << this->Origin[0] << "," << \
    this -> Origin[1] << "\n";
}

