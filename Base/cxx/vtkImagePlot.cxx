/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImagePlot.cxx,v $
  Date:      $Date: 2006/02/27 19:21:50 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/
#include "vtkImagePlot.h"

#include "vtkObjectFactory.h"
#include "vtkScalarsToColors.h"
#include "vtkImageData.h"

#define SET_PIXEL(x,y,color){ptr=&outPtr[(y)*nxnc+(x)*nc];memcpy(ptr,color,3);}

vtkCxxSetObjectMacro(vtkImagePlot,LookupTable,vtkScalarsToColors);

//------------------------------------------------------------------------------
vtkImagePlot* vtkImagePlot::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImagePlot");
  if(ret)
  {
    return (vtkImagePlot*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkImagePlot;
}

//----------------------------------------------------------------------------
// Constructor: Sets default filter to be identity.
vtkImagePlot::vtkImagePlot()
{
  this->Height = 256;
  this->Thickness = 0;

  this->DataRange[0] = 0;
  this->DataRange[1] = 100;
  this->DataDomain[0] = 0;
  this->DataDomain[1] = 100;

    this->Color[0] = 1;
    this->Color[1] = 1;
    this->Color[2] = 0;

  this->LookupTable = NULL;
}

//----------------------------------------------------------------------------
int vtkImagePlot::MapBinToScalar(int bin)
{
  vtkFloatingPointType delta, v;
  int outExt[6];

  this->GetOutput()->GetWholeExtent(outExt);
  delta = (vtkFloatingPointType)(this->DataDomain[1]-this->DataDomain[0]) / 
    (vtkFloatingPointType)(outExt[1]-outExt[0]);
  v = (vtkFloatingPointType)this->DataDomain[0] + delta * bin;
  return (int)v;
}

//----------------------------------------------------------------------------
int vtkImagePlot::MapScalarToBin(int v)
{
  vtkFloatingPointType delta, bin;
  int outExt[6];

  this->GetOutput()->GetWholeExtent(outExt);
  delta = (vtkFloatingPointType)(this->DataDomain[1]-this->DataDomain[0]) / 
    (vtkFloatingPointType)(outExt[1]-outExt[0]);
  bin = (vtkFloatingPointType)(v - this->DataDomain[0]) / delta;
  return (int)bin;
}

//----------------------------------------------------------------------------
vtkImagePlot::~vtkImagePlot()
{
  if (this->LookupTable != NULL) 
  {
    this->LookupTable->UnRegister(this);
  }
}

//----------------------------------------------------------------------------
void vtkImagePlot::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);

  os << indent << "Thickness:     " << this->Thickness;
  os << indent << "Height:        " << this->Height;
  os << indent << "Color[0]:      " << this->Color[0];
  os << indent << "Color[1]:      " << this->Color[1];
  os << indent << "Color[2]:      " << this->Color[2];
  os << indent << "DataDomain[0]: " << this->DataDomain[0];
  os << indent << "DataDomain[1]: " << this->DataDomain[1];
  os << indent << "DataRange[0]:  " << this->DataRange[0];
  os << indent << "DataRange[1]:  " << this->DataRange[1];

  // vtkSetObjectMacro
  os << indent << "LookupTable: " << this->LookupTable << "\n";
  if (this->LookupTable)
  {
    this->LookupTable->PrintSelf(os,indent.GetNextIndent());
  }
}

//----------------------------------------------------------------------------
unsigned long vtkImagePlot::GetMTime()
{
  unsigned long t1, t2;

  t1 = this->Superclass::GetMTime();
  if (this->LookupTable)
  {
    t2 = this->LookupTable->GetMTime();
    if (t2 > t1)
    {
      t1 = t2;
    }
  }
  return t1;
}

//----------------------------------------------------------------------------
// Get ALL of the input.
// By default,this filter will try to fetch an input the same size as the
// output.  However, the output is 2D and the input is 1D.
// So we have to override this function here.
void vtkImagePlot::ComputeInputUpdateExtent(int inExt[6], 
                              int outExt[6])
{
  int *wholeExtent;

  wholeExtent = this->GetInput()->GetWholeExtent();
  memcpy(inExt, wholeExtent, 6*sizeof(int));
}

// Change the WholeExtent
//----------------------------------------------------------------------------
void vtkImagePlot::ExecuteInformation(vtkImageData *inData, 
                      vtkImageData *outData)
{
  int extent[6];
  vtkFloatingPointType spacing[3], origin[3];
  
  inData->GetWholeExtent(extent);
  inData->GetSpacing(spacing);
  inData->GetOrigin(origin);

  extent[2] = extent[4] = extent[5] = 0;
  extent[3] = this->Height - 1 ;

  outData->SetWholeExtent(extent);
  outData->SetSpacing(spacing);
  outData->SetOrigin(origin);
  outData->SetNumberOfScalarComponents(3);
  outData->SetScalarType(VTK_UNSIGNED_CHAR);
}

// Draw line including first, but not second end point
static void DrawThickLine(int xx1, int yy1, int xx2, int yy2, 
                          unsigned char color[3],
                          unsigned char *outPtr, int pNxnc, int pNc, int radius)
{
    unsigned char *ptr;
    int r, dx, dy, dy2, dx2, dydx2;
    int x, y, xInc;
    int nxnc = pNxnc, nc=pNc;
    int x1, y1, x2, y2;
    int rad=radius, rx1, rx2, ry1, ry2, rx, ry;

    // Sort points so x1,y1 is below x2,y2
    if (yy1 <= yy2) 
  {
        x1 = xx1;
        y1 = yy1;
        x2 = xx2;
        y2 = yy2;
    } 
  else 
  {
        x1 = xx2;
        y1 = yy2;
        x2 = xx1;
        y2 = yy1;
    }
    dx = abs(x2 - x1);
    dy = abs(y2 - y1);
    dx2 = dx << 1;
    dy2 = dy << 1;
    if (x1 < x2)
  {
        xInc = 1;
  }
    else
  {
        xInc = -1;
  }
    x = x1;
    y = y1;

    // Draw first point
    rx1 = x - rad; ry1 = y - rad;
    rx2 = x + rad; ry2 = y + rad;
  for (ry=ry1; ry <= ry2; ry++)
  {
        for (rx=rx1; rx <= rx2; rx++)
    {
            SET_PIXEL(rx, ry, color);
    }
  }

    // < 45 degree slope
    if (dy <= dx)
    {
        dydx2 = (dy-dx) << 1;
        r = dy2 - dx;

        // Draw up to (not including) end point
        if (x1 < x2)
        {
            while (x < x2)
            {
                x += xInc;
                if (r <= 0)
        {
                    r += dy2;
        }
                else 
        {
                    // Draw here for a thick line
                    rx1 = x - rad; ry1 = y - rad;
                    rx2 = x + rad; ry2 = y + rad;
                    for (ry=ry1; ry <= ry2; ry++)
          {
                        for (rx=rx1; rx <= rx2; rx++)
            {
                            SET_PIXEL(rx, ry, color);
            }
          }
                    y++;
                    r += dydx2;
                }
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
        {
                    for (rx=rx1; rx <= rx2; rx++)
          {
                        SET_PIXEL(rx, ry, color);
          }
        }
            }
        }
        else
        {
            while (x > x2)
            {
                x += xInc;
                if (r <= 0)
        {
                    r += dy2;
        }
                else 
        {
                    // Draw here for a thick line
                    rx1 = x - rad; ry1 = y - rad;
                    rx2 = x + rad; ry2 = y + rad;
                    for (ry=ry1; ry <= ry2; ry++)
          {
                        for (rx=rx1; rx <= rx2; rx++)
            {
                            SET_PIXEL(rx, ry, color);
            }
          }
                    y++;
                    r += dydx2;
                }
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
        {
                    for (rx=rx1; rx <= rx2; rx++)
          {
                        SET_PIXEL(rx, ry, color);
          }
        }
            }
        }
    }

    // > 45 degree slope
    else
    {
        dydx2 = (dx-dy) << 1;
        r = dx2 - dy;

        // Draw up to (not including) end point
        while (y < y2)
        {
            y++;
            if (r <= 0)
      {
                r += dx2;
      }
            else 
      {
                // Draw here for a thick line
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
        {
                    for (rx=rx1; rx <= rx2; rx++)
          {
                        SET_PIXEL(rx, ry, color);
          }
        }
                x += xInc;
                r += dydx2;
            }
            rx1 = x - rad; ry1 = y - rad;
            rx2 = x + rad; ry2 = y + rad;
            for (ry=ry1; ry <= ry2; ry++)
      {
                for (rx=rx1; rx <= rx2; rx++)
        {
                    SET_PIXEL(rx, ry, color);
        }
      }
        }
    }
}

//----------------------------------------------------------------------------
static void ConvertColor(vtkFloatingPointType *f, unsigned char *c)
{
    c[0] = (int)(f[0] * 255.0);
    c[1] = (int)(f[1] * 255.0);
    c[2] = (int)(f[2] * 255.0);
}

//----------------------------------------------------------------------------

// void vtkImagePlot::vtkImagePlotExecute(vtkImageData *inData,  unsigned char *inPtr,  int inExt[6], vtkImageData *outData, unsigned char *outPtr, int outExt[6])
template <class T> 
static  void vtkImagePlotExecute(vtkImagePlot *self, vtkImageData *inData,  T *inPtr,  int inExt[6], vtkImageData *outData, unsigned char *outPtr, int outExt[6]) {

  unsigned char color[3];
  int idxX, idxY, maxY, maxX;
  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;
  int nx, ny, nc, nxnc;
  int y1, y2, r=self->GetThickness();
  int range[2], domain[2];
  vtkFloatingPointType delta;
  vtkScalarsToColors *lookupTable = self->GetLookupTable();
  unsigned char *rgba;
  unsigned char *ptr;

  // find the region to loop over
  maxX = outExt[1] - outExt[0]; 
  maxY = outExt[3] - outExt[2]; 
  nx = maxX + 1;
  ny = maxY + 1;
  nc = outData->GetNumberOfScalarComponents();
  nxnc = nx*nc;

  ConvertColor(self->GetColor(), color);

  // Scale all bins
  self->GetDataDomain(domain);
  self->GetDataRange(range);
  
  // Get increments to march through data 
  inData->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);

  // Color scale
  // Loop through ouput pixels
  delta = (vtkFloatingPointType)(domain[1]-domain[0]) / (vtkFloatingPointType)(maxX);
  vtkFloatingPointType v;
  for (idxX = 0; idxX <= maxX; idxX++) 
  {
    v = (vtkFloatingPointType)domain[0] + delta * idxX;
    rgba = lookupTable->MapValue(v);

    for (idxY = 0; idxY <= maxY; idxY++)
    {
      SET_PIXEL(idxX, idxY, rgba);
    }
  }

  // Plot lines
  delta = (vtkFloatingPointType)(ny) / (vtkFloatingPointType)(range[1]-range[0]+1);

  for (idxX = 0; idxX <= maxX; idxX++) 
  {
    y1 = (int)(range[0] + delta * (vtkFloatingPointType)inPtr[0]);
    y2 = (int)(range[0] + delta * (vtkFloatingPointType)inPtr[1]);

    // Clip at boundary
    if (y1 < r)
    {
      y1 = r;
    }
    else if (y1 > maxY-r)
    {
      y1 = maxY-r;
    }
    if (y2 < r)
    {
      y2 = r;
    }
    else if (y2 > maxY-r)
    {
      y2 = maxY-r;
    }
    if (idxX >= r && idxX <= maxX-r-1)
    {
      DrawThickLine(idxX, y1, idxX+1, y2, color, outPtr, nxnc, nc, r);
    }
    inPtr++;
    }
}

//----------------------------------------------------------------------------
void vtkImagePlot::ExecuteData(vtkDataObject *)
{
  vtkImageData *inData = this->GetInput();
  vtkImageData *outData = this->GetOutput();
  outData->SetExtent(this->GetOutput()->GetWholeExtent());
  outData->AllocateScalars();

  int inExt[6], outExt[6];

  outData->GetExtent(outExt);
  this->ComputeInputUpdateExtent(inExt, outExt);
  void *inPtr = inData->GetScalarPointerForExtent(inExt);
  unsigned char *outPtr = (unsigned char*)
    outData->GetScalarPointerForExtent(outExt);
  
  // this filter expects that input is the same type as output.
  if (outData->GetScalarType() != VTK_UNSIGNED_CHAR) {
    vtkErrorMacro(<< "ExecuteData: output ScalarType, " << outData->GetScalarType() << ", must be VTK_UNSIGNED_CHAR (" << VTK_UNSIGNED_CHAR << ")" );
    return;
  }

  // You shold also check than if inPtr is of type unsigned char !    
  // vtkImagePlotExecute(inData, (unsigned char*)(inPtr), inExt, outData, outPtr, outExt);

  switch (inData->GetScalarType())
  {
    case VTK_DOUBLE:
      vtkImagePlotExecute(this, inData, (double *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_FLOAT:
      vtkImagePlotExecute(this, inData, (float *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_LONG:
      vtkImagePlotExecute(this, inData, (long *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_UNSIGNED_LONG:
      vtkImagePlotExecute(this, inData, (unsigned long *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_INT:
      vtkImagePlotExecute(this, inData, (int *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_UNSIGNED_INT:
      vtkImagePlotExecute(this, inData, (unsigned int *)(inPtr), inExt,outData, outPtr, outExt);
      break;
    case VTK_SHORT:
      vtkImagePlotExecute(this, inData, (short *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_UNSIGNED_SHORT:
      vtkImagePlotExecute(this, inData, (unsigned short *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_CHAR:
      vtkImagePlotExecute(this, inData, (char *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    case VTK_UNSIGNED_CHAR:
      vtkImagePlotExecute(this, inData, (unsigned char *)(inPtr), inExt, outData, outPtr, outExt);
      break;
    default:
      vtkErrorMacro(<< "ExecuteData: Unknown ScalarType");
      return;
   } 
}

