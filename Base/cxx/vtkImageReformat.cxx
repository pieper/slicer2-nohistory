/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageReformat.cxx,v $
  Date:      $Date: 2006/03/06 19:02:26 $
  Version:   $Revision: 1.37 $

=========================================================================auto=*/
#include "vtkImageReformat.h"

#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkTransform.h"
#include "vtkImageData.h"
#include "vtkFloatArray.h"

#include <time.h>
#include <math.h>

vtkCxxSetObjectMacro(vtkImageReformat, WldToIjkMatrix, vtkMatrix4x4);
vtkCxxSetObjectMacro(vtkImageReformat, ReformatMatrix, vtkMatrix4x4);

//------------------------------------------------------------------------------
vtkImageReformat* vtkImageReformat::New()
{
    // First try to create the object from the vtkObjectFactory
    vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageReformat");
    if(ret)
    {
        return (vtkImageReformat*)ret;
    }
    // If the factory was unable to create the object, then create it here.
    return new vtkImageReformat;
}


//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageReformat::vtkImageReformat()
{
    this->InterpolateOn();
    this->ReformatMatrix = NULL;
    this->WldToIjkMatrix = NULL;
    this->Resolution = 256;
    this->FieldOfView = 240.0;
    this->RunTime = 0;

    for (int i=0; i<3; i++) 
    {
        this->XStep[i] = 0;
        this->YStep[i] = 0;
        this->Origin[i] = 0;
        this->WldPoint[i] = 0;
        this->IjkPoint[i] = 0;
    }

    // >> AT 11/07/01
    this->OriginShift[0] = this->OriginShift[1] = 0.0;
    this->Zoom = 1.0;
    this->PanScale = this->FieldOfView / (this->Resolution * this->Zoom);
    this->OriginShiftMtx = vtkMatrix4x4::New();
    // << AT 11/07/01
}

//----------------------------------------------------------------------------
vtkImageReformat::~vtkImageReformat()
{
    // Delete ImageData if self-created or if no one else is using it
    if (this->ReformatMatrix != NULL) 
    {
        // Signal that we're no longer using it
        this->ReformatMatrix->UnRegister(this);
    }
    if (this->WldToIjkMatrix != NULL) 
    {
        this->WldToIjkMatrix->UnRegister(this);
    }

    // >> AT 11/07/01
    this->OriginShiftMtx->Delete();
    // << AT 11/07/01
}

//----------------------------------------------------------------------------
void vtkImageReformat::PrintSelf(ostream& os, vtkIndent indent)
{
    Superclass::PrintSelf(os,indent);

    os << indent << "YStep[0]:    " << this->YStep[0] << "\n";
    os << indent << "YStep[1]:    " << this->YStep[1] << "\n";
    os << indent << "YStep[2]:    " << this->YStep[2] << "\n";
    os << indent << "XStep[0]:    " << this->XStep[0] << "\n";
    os << indent << "XStep[1]:    " << this->XStep[1] << "\n";
    os << indent << "XStep[2]:    " << this->XStep[2] << "\n";
    os << indent << "Origin[0]:   " << this->Origin[0] << "\n";
    os << indent << "Origin[1]:   " << this->Origin[1] << "\n";
    os << indent << "Origin[2]:   " << this->Origin[2] << "\n";
    os << indent << "RunTime:     " << this->RunTime << "\n";

    // >> AT 11/07/01
    os << indent << "OriginShift[0]:" << this->OriginShift[0] << "\n";
    os << indent << "OriginShift[1]:" << this->OriginShift[1] << "\n";    
    os << indent << "Zoom: " << this->Zoom << "\n";
    os << indent << "PanScale:" << this->PanScale << "\n";
    // << AT 11/07/01

    os << indent << "IjkPoint[0]: " << this->IjkPoint[0] << "\n";
    os << indent << "IjkPoint[1]: " << this->IjkPoint[1] << "\n";
    os << indent << "IjkPoint[2]: " << this->IjkPoint[2] << "\n";
    os << indent << "WldPoint[0]: " << this->WldPoint[0] << "\n";
    os << indent << "WldPoint[1]: " << this->WldPoint[1] << "\n";
    os << indent << "WldPoint[2]: " << this->WldPoint[2] << "\n";

    os << indent << "Resolution:  " << this->Resolution << "\n";
    os << indent << "FieldOfView: " << this->FieldOfView << "\n";
    os << indent << "Interpolate: " << this->Interpolate << "\n";

    if (this->ReformatMatrix)
    {
        os << indent << "ReformatMatrix:\n";
        this->ReformatMatrix->PrintSelf (os, indent.GetNextIndent ());
    }
    else
    {
        os << indent << "ReformatMatrix: (none)\n";
    }

    if (this->WldToIjkMatrix)
    {
        os << indent << "WldToIjkMatrix:\n";
        this->WldToIjkMatrix->PrintSelf (os, indent.GetNextIndent ());
    }
    else
    {
        os << indent << "WldToIjkMatrix: (none)\n";
    }
}

//----------------------------------------------------------------------------
void vtkImageReformat::ExecuteInformation(vtkImageData *inData, vtkImageData *outData)
{
    int ext[6];
    vtkFloatingPointType pix;

    // Set output to 2D, size specified by user
    ext[1] = this->Resolution - 1;
    ext[3] = this->Resolution - 1;
    ext[0] = ext[2] = ext[5] = ext[4] = 0;

    outData->SetWholeExtent(ext);

    // We don't use these anyway since we handle obliques with the
    // WldToIjkMatrix
    //
    pix = this->FieldOfView / this->Resolution;
    outData->SetSpacing(pix, pix, 1.0);
    if (inData->GetPointData()->GetTensors() == NULL) {
        outData->SetOrigin(0, 0, 0);
     } else {
         // Set the origin explicitly so structured points tensors 
         // will align with image data
         int wExt[6];
         // int ext[6];
         outData->GetWholeExtent(wExt);
         outData->SetOrigin(-wExt[1]*pix/2, -wExt[3]*pix/2, 0.0);
    }
}

//----------------------------------------------------------------------------
void vtkImageReformat::ComputeInputUpdateExtent(int inExt[6], int outExt[6])
{
    // Use full input extent
    this->GetInput()->GetWholeExtent(inExt);
}

//----------------------------------------------------------------------------
// >> jc - 5.9.05  for slicer 2.4
//    from float* to vtkFloatingPointType*

void vtkImageReformat::CrossProduct(vtkFloatingPointType* v1, vtkFloatingPointType* v2, vtkFloatingPointType* v3) {
  v3[0]=v1[1]*v2[2]-v1[2]*v2[1];
  v3[1]=v1[2]*v2[0]-v1[0]*v2[2];
  v3[2]=v1[0]*v2[1]-v1[1]*v2[0];
  v3[3]=0;
}

//----------------------------------------------------------------------------
// Karl - for new draw
void vtkImageReformat::SetPoint(int x, int y)
{
    vtkFloatingPointType point[4],zstep[4], ras[4];
    vtkMatrix4x4* m1;
    int i;

    point[0]=x;
    point[1]=y;
    point[2]=0;
    point[3]=1;
    m1= vtkMatrix4x4::New();
    
    this->CrossProduct(this->XStep,this->YStep,zstep);
    
    for (i=0; i<3; i++) 
    {
      m1->SetElement(i,0,this->XStep[i]);
      m1->SetElement(i,1,this->YStep[i]);
      m1->SetElement(i,2,zstep[i]);
      m1->SetElement(i,3,this->Origin[i]);
    }

    m1->MultiplyPoint(point,ras);
     
    /* for (i=0; i<3; i++) 
    {
        this->WldPoint[i] = this->Origin[i] + this->XStep[i]*(vtkFloatingPointType)x + 
            this->YStep[i]*(vtkFloatingPointType)y;
    }

    for (i=0; i<3; i++) 
    {
        ras[i] = this->WldPoint[i];
    }
    ras[3] = 1.0;*/
    
    this->WldToIjkMatrix->MultiplyPoint(ras, this->IjkPoint);

    // set the world point
    for (i=0; i<3; i++) 
    {
        this->WldPoint[i] = ras[i];
    }
   // << 
}
//----------------------------------------------------------------------------
// Karl - 2D to 3D
void vtkImageReformat::Slice2IJK(int slice_x, int slice_y, float& x, float& y, float& z)
{
    vtkFloatingPointType point[4],zstep[4], ras[4];
    vtkMatrix4x4* m1;
    int i;
    point[0]=slice_x;
    point[1]=slice_y;
    point[2]=0;
    point[3]=1;
    m1= vtkMatrix4x4::New();
    
    //Karl - 5.16.05
    m1->Identity();
    this->CrossProduct(this->XStep,this->YStep,zstep);
    for (i=0; i<3; i++) 
    {
      m1->SetElement(i,0,this->XStep[i]);
      m1->SetElement(i,1,this->YStep[i]);
      m1->SetElement(i,2,zstep[i]);
      m1->SetElement(i,3,this->Origin[i]);
    }
    m1->MultiplyPoint(point,ras);
    this->WldToIjkMatrix->MultiplyPoint(ras, point);
    x=point[0];
    y=point[1];
    z=point[2];
}
//----------------------------------------------------------------------------
//Karl - 3D to 2D
void vtkImageReformat::IJK2Slice( float x, float y, float z, int& slice_x, int& slice_y)
{
    vtkFloatingPointType point[4],zstep[4],ras[4],slicepoint[4];
    vtkMatrix4x4* m1;
    vtkMatrix4x4* m2;
    int i;

    point[0]=x;
    point[1]=y;
    point[2]=z;
    point[3]=1;
    m1= vtkMatrix4x4::New();
        
    m1->Identity();
    m2= vtkMatrix4x4::New();

    this->CrossProduct(this->XStep,this->YStep,zstep);

    for (i=0; i<3; i++) 
    {
      m1->SetElement(i,0,this->XStep[i]);
      m1->SetElement(i,1,this->YStep[i]);
      m1->SetElement(i,2,zstep[i]);
      m1->SetElement(i,3,this->Origin[i]);
    }

    m1->Invert();
    m2->DeepCopy( this->WldToIjkMatrix);
    m2->Invert();
 
    m2->MultiplyPoint(point, ras);
    m1->MultiplyPoint(ras,   slicepoint);

    slice_x=(int)(slicepoint[0]+0.5);
    slice_y=(int)(slicepoint[1]+0.5);
}

// FAST1 (for indices) uses more bits of precision to the right
// of the decimal point than FAST2 (for data) because indices
// can only be as large as 512, but data can be 32767.
// We want more bits to reduce quantization errors.
//
#define NBITS1            16
#define MULTIPLIER1       65536.0f
#define FLOAT_TO_FAST1(x) (int)((x) * MULTIPLIER1)
#define FAST1_TO_FLOAT(x) ((x) / MULTIPLIER1)
#define FAST1_TO_INT(x)   ((x) >> NBITS1)
#define INT_TO_FAST1(x)   ((x) << NBITS1)
#define FAST1_MULT(x, y)  (((x) * (y)) >> NBITS1)

#define NBITS2            8
#define MULTIPLIER2       256.0f
#define FLOAT_TO_FAST2(x) (int)((x) * MULTIPLIER2)
#define FAST2_TO_FLOAT(x) ((x) / MULTIPLIER2)
#define FAST2_TO_INT(x)   ((x) >> NBITS2)
#define INT_TO_FAST2(x)   ((x) << NBITS2)
#define FAST2_MULT(x, y)  (((x) * (y)) >> NBITS2)

#define FAST1_TO_FAST2(x) ((x) >> (NBITS1-NBITS2))

// with interpolation
#define CoordOut1(x,y,z) ((x<inExt[0])||(y<inExt[2])||(z<inExt[4])||\
                          (x>nx2     )||(y> ny2    )||(z>nz1     ))

// without interpolation
#define CoordOut2(x,y,z) ( (x<inExt[0])||(y<inExt[2])||(z<inExt[4]) || \
                           (x>nx2)     ||(y> ny2)    ||(z > nz2)       )

#define VolIndex(x,y,z)  z*nxy + y*nx + x + idx_shift;

//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageReformatExecuteInt(vtkImageReformat *self,
                     vtkImageData *inData, int *inExt, T *inPtr,
                     vtkImageData *outData, 
                     int outExt[6], int wExt[6], int id)
{
    int res, i, idx, nxy, idxX, idxY, maxY, maxX;
    int inIncX, inIncY, inIncZ, outIncX, outIncY, outIncZ;
    vtkFloatingPointType begin[4], origin[4], mx[4], my[4], mc[4], zero[4]={0.0,0.0,0.0,1.0};
    vtkFloatingPointType originIJK[4], mxIJK[4], myIJK[4], zeroIJK[4];
    vtkFloatingPointType xStep[3], yStep[3], xRewind[3];
    vtkFloatingPointType x, y, z, scale;
    int nx, ny, nz, nx2, ny2, nz2, nz1, xi, yi, zi;
    T *ptr, *outPtr;
    vtkMatrix4x4 *mat = self->GetReformatMatrix();
    vtkMatrix4x4 *world = self->GetWldToIjkMatrix();
    //fast
    int fround, fx, fy, fz, fxStep[3], fyStep[3], fxRewind[3];
    int fone, fx0, fy0, fz0, fx1, fy1, fz1, fdx0, fdx1, fdxy0, fdxy1;
    int idx_shift;
    // time
    clock_t tStart=0;
    if (id == 0) {tStart = clock();}

    // Find input dimensions
    nz = inExt[5] - inExt[4] + 1;
    ny = inExt[3] - inExt[2] + 1;
    nx = inExt[1] - inExt[0] + 1;
    nxy = nx * ny;
    nx2 = nx-2;
    ny2 = ny-2;
    nz2 = nz-2;
    nz1 = nz-1;

    // When the input extent is 0-based, then an index into it can be calculated as:
    // idx = zi*nxy + ni*nx + x
    // instead of the slower:
    // idx = (zi-inExt[4])*nxy + (yi-inExt[2])*nx + (xi-inExt[0])
    // so we'll only handle 0-based for now.
    //
    // Karl Krissian: added this functionality:
    // idx = (zi-inExt[4])*nxy + (yi-inExt[2])*nx + (xi-inExt[0])
    //     = zi*nxy + ni*nx + x + idx_shift
    //  where idx_shift = -(inExt[4]*nxy+inExt[2]*ny+inExt[0])
    idx_shift=-(inExt[4]*nxy+inExt[2]*ny+inExt[0]);

    //if (inExt[0] != 0 || inExt[2] != 0 || inExt[4] != 0)
    //{
    //    fprintf(stderr, "Change vtkImageReformat to handle non-0-based extents.\n");
    //    return;
    // }

    // find the region to loop over: this is the max pixel coordinate
    maxX = outExt[1]; 
    maxY = outExt[3];

    // Get pointer to output for this extent
    outPtr = (T*)outData->GetScalarPointerForExtent(outExt);

    // Get increments to march through data 
    outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
    inData->GetContinuousIncrements(inExt, inIncX, inIncY, inIncZ);

    // RAS-to-IJK Matrix looks like:
    //
    // mx0 my0 mz0 mc0
    // mx1 my1 mz1 mc1
    // mx2 my2 mz2 mc3
    //   0   0   0   1
    //
    // Where:
    // mx = normal vector along the x-direction of the output image
    // my = normal vector along the y-direction of the output image
    // mc = center of image
    //
    // Note:
    // The bottom row of the matrix needs to be "1"s
    // to treat each column as a homogeneous point for
    // matrix multiplication.
    //

    // Scale mx, my by FOV/RESOLUTION
    res = self->GetResolution();
    ///Raul: Compute that in Execute
    //if(self->GetZoom() < 0.0001)
    //    self->SetZoom(0.0001);
    //scale = self->GetFieldOfView() / (res * self->GetZoom());

    //self->PanScale = self->GetFieldOfView() / (res * self->Zoom);
    //self->SetPanScale(scale);
    
    scale=self->GetPanScale();

    mx[0] = mat->Element[0][0] * scale;
    mx[1] = mat->Element[1][0] * scale;
    mx[2] = mat->Element[2][0] * scale;
    mx[3] = 1.0;
    my[0] = mat->Element[0][1] * scale;
    my[1] = mat->Element[1][1] * scale;
    my[2] = mat->Element[2][1] * scale;
    my[3] = 1.0;
    mc[0] = mat->Element[0][3];
    mc[1] = mat->Element[1][3];
    mc[2] = mat->Element[2][3];
    mc[3] = 1.0;

    // Find the RAS origin (lower-left corner of reformated image).
    // The direction from the center to the origin is backwards from
    // the sum of the x-dir, y-dir vectors.
    // The length is half the OUTPUT image size.

    //vtkFloatingPointType originshiftX, originshiftY, originshiftZ;
    vtkFloatingPointType originshift1[4], originshift2[4];
    //originshift1[0] = self->OriginShift[0];
    //originshift1[1] = self->OriginShift[1];
    vtkMatrix4x4 *originshiftmtx = self->GetOriginShiftMtx();
    //Raul: These operations are not thread safe. Move to Execute
    //originshiftmtx->DeepCopy(mat);
    //originshiftmtx->Element[0][3] = 0.0;
    //originshiftmtx->Element[1][3] = 0.0;
    //originshiftmtx->Element[2][3] = 0.0;
    self->GetOriginShift(originshift1);
    originshift1[2] = 0.0;
    originshift1[3] = 1.0;
    originshiftmtx->MultiplyPoint(originshift1, originshift2);

    origin[0] = originshift2[0] + mc[0] - (mx[0] + my[0]) * res / 2.0;
    origin[1] = originshift2[1] + mc[1] - (mx[1] + my[1]) * res / 2.0;
    origin[2] = originshift2[2] + mc[2] - (mx[2] + my[2]) * res / 2.0;
    origin[3] = 1.0;

    /*origin[0] = mc[0] - (mx[0] + my[0]) * res / 2.0;
      origin[1] = mc[1] - (mx[1] + my[1]) * res / 2.0;
      origin[2] = mc[2] - (mx[2] + my[2]) * res / 2.0;
      origin[3] = 1.0;*/

    // Advance to the origin of this output extent (used for threading)
    // x
    scale = (vtkFloatingPointType)(outExt[0]-wExt[0]);
    begin[0] = origin[0] + scale*mx[0];
    begin[1] = origin[1] + scale*mx[1];
    begin[2] = origin[2] + scale*mx[2];
    begin[3] = 1.0;
    // y
    scale = (vtkFloatingPointType)(outExt[2]-wExt[2]);    
    begin[0] = begin[0] + scale*my[0];
    begin[1] = begin[1] + scale*my[1];
    begin[2] = begin[2] + scale*my[2];
    begin[3] = 1.0;

    // Convert origin from RAS IJK space
    world->MultiplyPoint(begin, originIJK);
    world->MultiplyPoint(zero,  zeroIJK);
    world->MultiplyPoint(mx,    mxIJK);
    world->MultiplyPoint(my,    myIJK);

    // step vector in x direction
    xStep[0] = mxIJK[0] - zeroIJK[0];
    xStep[1] = mxIJK[1] - zeroIJK[1];
    xStep[2] = mxIJK[2] - zeroIJK[2];

    // step vector in y direction
    yStep[0] = myIJK[0] - zeroIJK[0];
    yStep[1] = myIJK[1] - zeroIJK[1];
    yStep[2] = myIJK[2] - zeroIJK[2];

    // Initialize volume coords x, y, z to origin
    x = originIJK[0];
    y = originIJK[1];
    z = originIJK[2];

    // rewind steps in x direction
    xRewind[0] = xStep[0] * (maxX+1);
    xRewind[1] = xStep[1] * (maxX+1);
    xRewind[2] = xStep[2] * (maxX+1);

    // Prepare to convert and return points to the user
    if (id == 0) 
    {
      for (i=0; i<3; i++) 
        {
          self->Origin[i] = origin[i];
          self->XStep[i] = mx[i] - zero[i];
          self->YStep[i] = my[i] - zero[i];
        }
    }    

    // Convert float to fast
    fx = FLOAT_TO_FAST1(x);
    fy = FLOAT_TO_FAST1(y);
    fz = FLOAT_TO_FAST1(z);
    for (i=0; i<3; i++) 
    {
        fxStep[i] = FLOAT_TO_FAST1(xStep[i]);
        fyStep[i] = FLOAT_TO_FAST1(yStep[i]);
        fxRewind[i] = FLOAT_TO_FAST1(xRewind[i]);
    }
    fround = FLOAT_TO_FAST1(0.49);
    fone = FLOAT_TO_FAST2(1.0);

    //
    // Interpolation
    //
    if (self->GetInterpolate())
    {
        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            fxRewind[0] = fx;
            fxRewind[1] = fy;
            fxRewind[2] = fz;

            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
                xi = FAST1_TO_INT(fx);
                yi = FAST1_TO_INT(fy);
                zi = FAST1_TO_INT(fz);

                // Test if coordinates are outside volume
                if CoordOut1(xi,yi,zi)
                    // Indicate out of bounds with a -1
                    *outPtr = 0;
                // Handle the case of being on the last slice
                else if (zi == nz1)
                {
                    fx1 = FAST1_TO_FAST2(fx) - INT_TO_FAST2(xi);
                    fy1 = FAST1_TO_FAST2(fy) - INT_TO_FAST2(yi);

                    fx0 = fone - fx1;
                    fy0 = fone - fy1;

                    // Interpolate in X and Y at Z0
                    //
                    idx = VolIndex(xi,yi,zi);
                    ptr = &inPtr[idx];

                    fdx0 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));
                    ptr += nx;
                    fdx1 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));

                    fdxy0 = FAST2_MULT(fy0, fdx0) + FAST2_MULT(fy1, fdx1);

                    *outPtr = (T)FAST2_TO_FLOAT(fdxy0);
                }
                else 
                {
                    fx1 = FAST1_TO_FAST2(fx) - INT_TO_FAST2(xi);
                    fy1 = FAST1_TO_FAST2(fy) - INT_TO_FAST2(yi);
                    fz1 = FAST1_TO_FAST2(fz) - INT_TO_FAST2(zi);

                    fx0 = fone - fx1;
                    fy0 = fone - fy1;
                    fz0 = fone - fz1;

                    // Interpolate in X and Y at Z0
                    //
                    idx = VolIndex(xi,yi,zi);
                    ptr = &inPtr[idx];

                    fdx0 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));
                    ptr += nx;
                    fdx1 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));

                    fdxy0 = FAST2_MULT(fy0, fdx0) + FAST2_MULT(fy1, fdx1);

                    // Interpolate in X and Y at Z1
                    //
                    ptr = &inPtr[idx+nxy];

                    fdx0 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));
                    ptr += nx;
                    fdx1 = FAST2_MULT(fx0, INT_TO_FAST2((int)ptr[0])) + 
                        FAST2_MULT(fx1, INT_TO_FAST2((int)ptr[1]));

                    fdxy1 = FAST2_MULT(fy0, fdx0) + FAST2_MULT(fy1, fdx1);

                    // Interpolate in Z
                    //
                    *outPtr = (T)(FAST2_TO_FLOAT(
                                FAST2_MULT(fz0, fdxy0) + FAST2_MULT(fz1, fdxy1)));
                }
                outPtr++;

                // Step volume coordinates in xs direction
                fx += fxStep[0];
                fy += fxStep[1];
                fz += fxStep[2];
            }
            outPtr  += outIncY;

            // Rewind volume coordinates back to first column and step in y
            fx = fxRewind[0] + fyStep[0];
            fy = fxRewind[1] + fyStep[1];
            fz = fxRewind[2] + fyStep[2];
        }
    }//interp

    //
    // Without interpolation 
    //
    else 
    {
        nx2 = nx-1;
        ny2 = ny-1;
        nz2 = nz-1;

        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            fxRewind[0] = fx;
            fxRewind[1] = fy;
            fxRewind[2] = fz;

            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
                xi = FAST1_TO_INT(fx + fround);
                yi = FAST1_TO_INT(fy + fround);
                zi = FAST1_TO_INT(fz + fround);

                // Test if coordinates are outside volume
                if CoordOut2(xi,yi,zi)
                    *outPtr = 0; 
                else {
                    // Compute 'idx', the index into the input volume
                    // where the output pixel value comes from.
                    idx = VolIndex(xi,yi,zi);
                    *outPtr = inPtr[idx];
                }
                outPtr++;

                // Step volume coordinates in xs direction
                fx += fxStep[0];
                fy += fxStep[1];
                fz += fxStep[2];
            }
            outPtr  += outIncY;

            // Rewind volume coordinates back to first column and step in y
            fx = fxRewind[0] + fyStep[0];
            fy = fxRewind[1] + fyStep[1];
            fz = fxRewind[2] + fyStep[2];
        }
    }//withoutInterpolation

    if (id == 0) 
    {
        self->SetRunTime(clock() - tStart);
    }
}

//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of data.
template <class T>
static void vtkImageReformatExecute(vtkImageReformat *self,
                     vtkImageData *inData, int *inExt, T *inPtr,
                     vtkImageData *outData, 
                     int outExt[6], int wExt[6], int id)
{
    int res, i, idx, nxy, idxX, idxY, maxY, maxX;
    int inIncX, inIncY, inIncZ, outIncX, outIncY, outIncZ;
    vtkFloatingPointType begin[4], origin[4], mx[4], my[4], mc[4], zero[4]={0.0,0.0,0.0,1.0};
    vtkFloatingPointType originIJK[4], mxIJK[4], myIJK[4], zeroIJK[4];
    vtkFloatingPointType xStep[3], yStep[3], xRewind[3];
    vtkFloatingPointType x, y, z, scale;
    vtkFloatingPointType x0, y0, z0, x1, y1, z1, dx0, dx1, dxy0, dxy1;
    int nx, ny, nz, nx2, ny2, nz2, nz1, xi, yi, zi;
    T *ptr, *outPtr;
    vtkMatrix4x4 *mat = self->GetReformatMatrix();
    vtkMatrix4x4 *world = self->GetWldToIjkMatrix();
    // multiple components
    int nxc, idxC, numComps, scalarSize, inRowLength;
    int idx_shift;
    // time
    clock_t tStart=0;
    if (id == 0)
        tStart = clock();

    // Find input dimensions
    numComps = inData->GetNumberOfScalarComponents();
    // This must include all components or we will see red.
    scalarSize = sizeof(T)*numComps;
    inRowLength = (inExt[1] - inExt[0]+1);
    nz = inExt[5] - inExt[4] + 1;
    ny = inExt[3] - inExt[2] + 1;
    nx = inExt[1] - inExt[0] + 1;
    nxc = nx * numComps;
    nxy = nx * ny;
    nx2 = nx-2;
    ny2 = ny-2;
    nz2 = nz-2;
    nz1 = nz-1;

    // When the input extent is 0-based, then an index into it can be calculated as:
    // idx = zi*nxy + ni*nx + x
    // instead of the slower:
    // idx = (zi-inExt[4])*nxy + (yi-inExt[2])*nx + (xi-inExt[0])
    // so we'll only handle 0-based for now.
    //
    // Karl Krissian: added this functionality:
    // idx = (zi-inExt[4])*nxy + (yi-inExt[2])*nx + (xi-inExt[0])
    //     = zi*nxy + ni*nx + x + idx_shift
    //  where idx_shift = -(inExt[4]*nxy+inExt[2]*ny+inExt[0])
    idx_shift=-(inExt[4]*nxy+inExt[2]*ny+inExt[0]);
    //if (inExt[0] != 0 || inExt[2] != 0 || inExt[4] != 0)
    //{
    //    fprintf(stderr, "Change vtkImageReformat to handle non-0-based extents.\n");
    //    return;
    // }

    // find the region to loop over: this is the max pixel coordinate
    maxX = outExt[1]; 
    maxY = outExt[3];

    // Get pointer to output for this extent
    outPtr = (T*)outData->GetScalarPointerForExtent(outExt);

    // Get increments to march through data 
    outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
    inData->GetContinuousIncrements(inExt, inIncX, inIncY, inIncZ);

    // RAS-to-IJK Matrix looks like:
    //
    // mx0 my0 mz0 mc0
    // mx1 my1 mz1 mc1
    // mx2 my2 mz2 mc3
    //   0   0   0   1
    //
    // Where:
    // mx = normal vector along the x-direction of the output image
    // my = normal vector along the y-direction of the output image
    // mc = center of image
    //
    // Note:
    // The bottom row of the matrix needs to be "1"s
    // to treat each column as a homogeneous point for
    // matrix multiplication.
    //

    // Scale mx, my by FOV/RESOLUTION
    res = self->GetResolution();
    ///Raul: Compute that in Execute
    //if(self->GetZoom() < 0.0001)
    //    self->SetZoom(0.0001);
    //scale = self->GetFieldOfView() / (res * self->GetZoom());
    //    scale = self->GetFieldOfView() / res;

    //self->PanScale = self->GetFieldOfView() / (res * self->Zoom);
    //self->SetPanScale(scale);

    scale=self->GetPanScale();
    
    mx[0] = mat->Element[0][0] * scale;
    mx[1] = mat->Element[1][0] * scale;
    mx[2] = mat->Element[2][0] * scale;
    mx[3] = 1.0;
    my[0] = mat->Element[0][1] * scale;
    my[1] = mat->Element[1][1] * scale;
    my[2] = mat->Element[2][1] * scale;
    my[3] = 1.0;
    mc[0] = mat->Element[0][3];
    mc[1] = mat->Element[1][3];
    mc[2] = mat->Element[2][3];
    mc[3] = 1.0;

    // Find the RAS origin (upper-left corner of reformated image).
    // The direction from the center to the origin is backwards from
    // the sum of the x-dir, y-dir vectors.
    // The length is half the OUTPUT image size.

    vtkFloatingPointType originshift1[4], originshift2[4];
    vtkMatrix4x4 *originshiftmtx = self->GetOriginShiftMtx();
    //Raul: These operations are not thread safe. Move to Execute
    //originshiftmtx->DeepCopy(mat);
    //originshiftmtx->Element[0][3] = 0.0;
    //originshiftmtx->Element[1][3] = 0.0;
    //originshiftmtx->Element[2][3] = 0.0;
    self->GetOriginShift(originshift1);
    originshift1[2] = 0.0;
    originshift1[3] = 1.0;
    originshiftmtx->MultiplyPoint(originshift1, originshift2);

    origin[0] = originshift2[0] + mc[0] - (mx[0] + my[0]) * res / 2.0;
    origin[1] = originshift2[1] + mc[1] - (mx[1] + my[1]) * res / 2.0;
    origin[2] = originshift2[2] + mc[2] - (mx[2] + my[2]) * res / 2.0;
    origin[3] = 1.0;

    /*origin[0] = mc[0] - (mx[0] + my[0]) * res / 2.0;
      origin[1] = mc[1] - (mx[1] + my[1]) * res / 2.0;
      origin[2] = mc[2] - (mx[2] + my[2]) * res / 2.0;
      origin[3] = 1.0;*/

    // Advance to the origin of this output extent (used for threading)
    // x
    scale = (vtkFloatingPointType)(outExt[0]-wExt[0]);
    begin[0] = origin[0] + scale*mx[0];
    begin[1] = origin[1] + scale*mx[1];
    begin[2] = origin[2] + scale*mx[2];
    begin[3] = 1.0;
    // y
    scale = (vtkFloatingPointType)(outExt[2]-wExt[2]);    
    begin[0] = begin[0] + scale*my[0];
    begin[1] = begin[1] + scale*my[1];
    begin[2] = begin[2] + scale*my[2];
    begin[3] = 1.0;

    // Convert origin from RAS IJK space
    world->MultiplyPoint(begin, originIJK);
    world->MultiplyPoint(zero,  zeroIJK);
    world->MultiplyPoint(mx,    mxIJK);
    world->MultiplyPoint(my,    myIJK);

    // step vector in x direction
    xStep[0] = mxIJK[0] - zeroIJK[0];
    xStep[1] = mxIJK[1] - zeroIJK[1];
    xStep[2] = mxIJK[2] - zeroIJK[2];

    // step vector in y direction
    yStep[0] = myIJK[0] - zeroIJK[0];
    yStep[1] = myIJK[1] - zeroIJK[1];
    yStep[2] = myIJK[2] - zeroIJK[2];

    // Initialize volume coords x, y, z to origin
    x = originIJK[0];
    y = originIJK[1];
    z = originIJK[2];

    // rewind steps in x direction
    xRewind[0] = xStep[0] * (maxX+1);
    xRewind[1] = xStep[1] * (maxX+1);
    xRewind[2] = xStep[2] * (maxX+1);

    // Prepare to convert and return points to the user
    if ( id ==0 ) 
    {
      for (i=0; i<3; i++) 
        {
          self->Origin[i] = origin[i];
          self->XStep[i] = mx[i] - zero[i];
          self->YStep[i] = my[i] - zero[i];
        }
    }    

    //
    // Interpolation
    //
    if (self->GetInterpolate())
    {
        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
          // Karl Krissian: if we don't use floor() to convert, 
          // there can be some problems at the borders: values between ]-1;0[
          // can be processed
                xi = (int)floor((double)x);
                yi = (int)floor((double)y);
                zi = (int)floor((double)z);

                // Test if coordinates are outside volume
                if CoordOut1(xi,yi,zi)
                {
                    // Indicate out of bounds with a -1
                    memset(outPtr, 0, scalarSize);
                    outPtr += numComps;
                }
                // Handle the case of being on the last slice
                else if (zi == nz1)
                {
                    x1 = x - xi;
                    y1 = y - yi;

                    x0 = 1.0 - x1;
                    y0 = 1.0 - y1;

                    idx = VolIndex(xi,yi,zi);
                    idx *= numComps;

                    for (idxC = 0; idxC < numComps; idxC++)
                    {
                        // Interpolate in X and Y at Z0
                        //
                        ptr = &inPtr[idx+idxC];
                        dx0 = x0*ptr[0] + x1*ptr[numComps]; ptr += nxc;
                        dx1 = x0*ptr[0] + x1*ptr[numComps];

                        dxy0 = y0*dx0 + y1*dx1;

                        *outPtr = (T)dxy0;
                        outPtr++;
                    }//for c
                }
                else 
                {
                    x1 = x - xi;
                    y1 = y - yi;
                    z1 = z - zi;

                    x0 = 1.0 - x1;
                    y0 = 1.0 - y1;
                    z0 = 1.0 - z1;

                    idx = VolIndex(xi,yi,zi);
                    idx *= numComps;

                    for (idxC = 0; idxC < numComps; idxC++)
                    {
                        // Interpolate in X and Y at Z0
                        //
                        ptr = &inPtr[idx+idxC];
                        dx0 = x0*ptr[0] + x1*ptr[numComps]; ptr += nxc;
                        dx1 = x0*ptr[0] + x1*ptr[numComps];

                        dxy0 = y0*dx0 + y1*dx1;

                        // Interpolate in X and Y at Z1
                        //
                        ptr = &inPtr[idx+idxC+nxy*numComps];
                        dx0 = x0*ptr[0] + x1*ptr[numComps]; ptr += nxc;
                        dx1 = x0*ptr[0] + x1*ptr[numComps];

                        dxy1 = y0*dx0 + y1*dx1;

                        // Interpolate in Z
                        //
                        *outPtr = (T)(z0*dxy0 + z1*dxy1);
                        outPtr++;
                    }//for c
                }// else

                // Step volume coordinates in xs direction
                x += xStep[0];
                y += xStep[1];
                z += xStep[2];
            }
            outPtr  += outIncY;

            // Rewind volume coordinates back to first column
            x -= xRewind[0];
            y -= xRewind[1];
            z -= xRewind[2];

            // Step volume coordinates in y direction
            x += yStep[0];
            y += yStep[1];
            z += yStep[2];
        }
    }//interp

    //
    // Without interpolation 
    //
    else 
    {
        nx2 = nx-1;
        ny2 = ny-1;
        nz2 = nz-1;

        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
                xi = (int)(x + 0.5);
                yi = (int)(y + 0.5);
                zi = (int)(z + 0.5);

                // Test if coordinates are outside volume
                if CoordOut2(xi,yi,zi)
                    memset(outPtr, 0, scalarSize);
                else {
                    // Compute 'idx', the index into the input volume
                    // where the output pixel value comes from.
                    idx = VolIndex(xi,yi,zi);
                    idx *= numComps;
                    ptr = &inPtr[idx];
                    memcpy(outPtr, ptr, scalarSize);
                }
                outPtr += numComps;

                // Step volume coordinates in xs direction
                x += xStep[0];
                y += xStep[1];
                z += xStep[2];
            }
            outPtr  += outIncY;

            // Rewind volume coordinates back to first column
            x -= xRewind[0];
            y -= xRewind[1];
            z -= xRewind[2];

            // Step volume coordinates in ys direction
            x += yStep[0];
            y += yStep[1];
            z += yStep[2];
        }
    }//withoutInterpolation

    if (id == 0) 
    {
        self->SetRunTime(clock() - tStart);
    }
}


//----------------------------------------------------------------------------
// Description:
// This templated function executes the filter for any type of 
// (scalar) data, and floating-point vtkDataArray.
//
// This is copied from the other reformat functions in this
// file, and just modified to reformat tensors.
//
// Scalars are ignored for now.
//
template <class T>
static void vtkImageReformatExecuteTensor(vtkImageReformat *self,
                                          vtkImageData *inData, 
                                          int *inExt, T *inPtr,
                                          vtkImageData *outData, 
                                          int outExt[6], int wExt[6], 
                                          int id)
{
    int res, i, idx, nxy, idxX, idxY, maxY, maxX;
    int inIncX, inIncY, inIncZ, outIncX, outIncY, outIncZ;
    vtkFloatingPointType begin[4], origin[4], mx[4], my[4], mc[4], zero[4]={0.0,0.0,0.0,1.0};
    vtkFloatingPointType originIJK[4], mxIJK[4], myIJK[4], zeroIJK[4];
    vtkFloatingPointType xStep[3], yStep[3], xRewind[3];
    vtkFloatingPointType x, y, z, scale;
    vtkFloatingPointType x0, y0, z0, x1, y1, z1, dx0, dx1, dxy0, dxy1;
    int nx, ny, nz, nx2, ny2, nz2, nz1, xi, yi, zi;
    T *outPtr;
    vtkMatrix4x4 *mat = self->GetReformatMatrix();
    vtkMatrix4x4 *world = self->GetWldToIjkMatrix();
    // multiple components
    int nxc, numComps, scalarSize, inRowLength;
    // time
    clock_t tStart=0;
    // tensors 
    int numCompsI, numCompsJ;
    int outTensorIdx, j;
    vtkDataArray *inTensorData, *outTensorData;
    vtkFloatingPointType outT[3][3];

    // execution time 
    if (id == 0)
        tStart = clock();

    // Number of tensor components.
    // Do all 9 tensor components for now, though
    // optimally should do only 6.
    numCompsI = 3;
    numCompsJ = 3;

    inRowLength = (inExt[1] - inExt[0]+1);
    nz = inExt[5] - inExt[4] + 1;
    ny = inExt[3] - inExt[2] + 1;
    nx = inExt[1] - inExt[0] + 1;
    nxy = nx * ny;
      
       
    // If there are no scalars in the input, clear the output scalars
    if ((inData->GetPointData()->GetScalars() == NULL) ||
            (inData->GetPointData()->GetScalars()->GetNumberOfTuples() == 0))
    {
        vtkGenericWarningMacro("Execute: no scalars with tensors in input image data");

        // account for multiple scalars per pixel
        numComps = inData->GetNumberOfScalarComponents();
        scalarSize = sizeof(T)*numComps;
        nxc = nx * numComps;

        // Get pointer to output for this extent
        outPtr = (T*)outData->GetScalarPointerForExtent(outExt);

        memset(outPtr, 0, nxc*ny*nz*sizeof(T));   
    }

    // this is max index for bounds checking.
    // -2 since we access each pixel and the next for interpolating
    // (this copied code is dumb since this is re-assigned for 
    // no interpolation, but keep things consistent)
    nx2 = nx-2;
    ny2 = ny-2;
    nz2 = nz-2;
    nz1 = nz-1;

    // Get input pointer to tensor data, which is always float
    inTensorData = inData->GetPointData()->GetTensors();
    outTensorData = outData->GetPointData()->GetTensors();

    // When the input extent is 0-based, then an index into it can be calculated as:
    // idx = zi*nxy + ni*nx + x
    // instead of the slower:
    // idx = (zi-inExt[4])*nxy + (yi-inExt[2])*nx + (xi-inExt[0])
    // so we'll only handle 0-based for now.
    //
    if (inExt[0] != 0 || inExt[2] != 0 || inExt[4] != 0)
    {
        fprintf(stderr, "Change vtkImageReformat to handle non-0-based extents.\n");
        return;
    }

    // find the region to loop over: this is the max pixel coordinate
    maxX = outExt[1]; 
    maxY = outExt[3];

    // Get index into output tensor data for this output extent
    // Lauren if multithread breaks look here first
    outTensorIdx = outExt[0] + outExt[2]*(nx) + outExt[4]*(nxy);
    //cout << "START IDX " << outTensorIdx << endl;

    // Get increments to march through data 
    outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
    inData->GetContinuousIncrements(inExt, inIncX, inIncY, inIncZ);

    // RAS-to-IJK Matrix looks like:
    //
    // mx0 my0 mz0 mc0
    // mx1 my1 mz1 mc1
    // mx2 my2 mz2 mc3
    //   0   0   0   1
    //
    // Where:
    // mx = normal vector along the x-direction of the output image
    // my = normal vector along the y-direction of the output image
    // mc = center of image
    //
    // Note:
    // The bottom row of the matrix needs to be "1"s
    // to treat each column as a homogeneous point for
    // matrix multiplication.
    //

    // Scale mx, my by FOV/RESOLUTION  (size of a pixel in output image)
    res = self->GetResolution();
    scale = self->GetFieldOfView() / res;

    mx[0] = mat->Element[0][0] * scale;
    mx[1] = mat->Element[1][0] * scale;
    mx[2] = mat->Element[2][0] * scale;
    mx[3] = 1.0;
    my[0] = mat->Element[0][1] * scale;
    my[1] = mat->Element[1][1] * scale;
    my[2] = mat->Element[2][1] * scale;
    my[3] = 1.0;
    mc[0] = mat->Element[0][3];
    mc[1] = mat->Element[1][3];
    mc[2] = mat->Element[2][3];
    mc[3] = 1.0;

    // Find the RAS origin (upper-left corner of reformatted image).
    // The direction from the center to the origin is backwards from
    // the sum of the x-dir, y-dir vectors.
    // The length is half the OUTPUT image size.

    origin[0] = mc[0] - (mx[0] + my[0]) * res / 2.0;
    origin[1] = mc[1] - (mx[1] + my[1]) * res / 2.0;
    origin[2] = mc[2] - (mx[2] + my[2]) * res / 2.0;
    origin[3] = 1.0;

    // Advance to the origin of this output extent (used for threading)
    // x
    scale = (vtkFloatingPointType)(outExt[0]-wExt[0]);
    begin[0] = origin[0] + scale*mx[0];
    begin[1] = origin[1] + scale*mx[1];
    begin[2] = origin[2] + scale*mx[2];
    begin[3] = 1.0;
    // y
    scale = (vtkFloatingPointType)(outExt[2]-wExt[2]);   
    begin[0] = begin[0] + scale*my[0];
    begin[1] = begin[1] + scale*my[1];
    begin[2] = begin[2] + scale*my[2];
    begin[3] = 1.0;

    // Convert origin from RAS to IJK space
    world->MultiplyPoint(begin, originIJK);
    world->MultiplyPoint(zero,  zeroIJK);
    world->MultiplyPoint(mx,    mxIJK);
    world->MultiplyPoint(my,    myIJK);

    // step vector in x direction
    xStep[0] = mxIJK[0] - zeroIJK[0];
    xStep[1] = mxIJK[1] - zeroIJK[1];
    xStep[2] = mxIJK[2] - zeroIJK[2];

    // step vector in y direction
    yStep[0] = myIJK[0] - zeroIJK[0];
    yStep[1] = myIJK[1] - zeroIJK[1];
    yStep[2] = myIJK[2] - zeroIJK[2];

    // Initialize volume coords x, y, z to origin
    x = originIJK[0];
    y = originIJK[1];
    z = originIJK[2];

    // rewind steps in x direction
    xRewind[0] = xStep[0] * (maxX+1);
    xRewind[1] = xStep[1] * (maxX+1);
    xRewind[2] = xStep[2] * (maxX+1);

    // Prepare to convert and return points to the user
    for (i=0; i<3; i++) 
    {
        self->Origin[i] = origin[i];
        self->XStep[i] = mx[i] - zero[i];
        self->YStep[i] = my[i] - zero[i];
    }


    //
    // Interpolation
    //
    if (self->GetInterpolate())
    {
        //cout << "Reformatting tensors with interpolation" << endl;
        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
                xi = (int)x;
                yi = (int)y;
                zi = (int)z;

                // Test if coordinates are outside volume
                if ((xi < 0) || (yi < 0) || (zi < 0) ||
                        (xi > nx2) || (yi > ny2) || (zi > nz1))
                {

                    //-TENSOR- vtkTensor *tensor = outTensorData->GetTuple(outTensorIdx);

                    //              // set all components to 0
                    //              for (i = 0; i < numCompsI; i++)
                    //                {
                    //                  for (j = 0; j < numCompsJ; j++)
                    //                    {
                    //                      tensor->SetComponent(i, j, 0);
                    //                    }
                    //                }
                    //-TENSOR- tensor->Initialize();
                    for (i = 0; i < numCompsI; i++)
                    {
                        for (j = 0; j < numCompsJ; j++)
                        {
                            outT[i][j] = 0;
                        }
                    }
                }
                // Handle the case of being on the last slice
                else if (zi == nz1)
                {
                    // point we want, x, falls between two indices
                    // x1 is fractional distance to first index             
                    // x0 is fractional distance to the other
                    x1 = x - xi;
                    y1 = y - yi;

                    x0 = 1.0 - x1;
                    y0 = 1.0 - y1;

                    // closest integer index into volume
                    // (corresponds to x1 above)
                    idx = zi*nxy + yi*nx + xi;

                    // tensor indices.  Grab 4 tensors for interpolation.
                    int idx1 = zi*nxy + yi*nx + xi;
                    int idx2 = idx1 + 1;
                    int idx3 = idx1 + nx;
                    int idx4 = idx2 + nx;

                    // get the tensors at these image indices
                    //-TENSOR- vtkTensor *tensor1 = inTensorData->GetTuple(idx1);
                    //-TENSOR- vtkTensor *tensor2 = inTensorData->GetTuple(idx2);
                    //-TENSOR- vtkTensor *tensor3 = inTensorData->GetTuple(idx3);
                    //-TENSOR- vtkTensor *tensor4 = inTensorData->GetTuple(idx4);

                    vtkFloatingPointType inT1[3][3], inT2[3][3], inT3[3][3], inT4[3][3];
                    inTensorData->GetTuple(idx1,(vtkFloatingPointType *)inT1);
                    inTensorData->GetTuple(idx2,(vtkFloatingPointType *)inT2);
                    inTensorData->GetTuple(idx3,(vtkFloatingPointType *)inT3);
                    inTensorData->GetTuple(idx4,(vtkFloatingPointType *)inT4);

                    // find output location
                    //-TENSOR- vtkTensor *tensor = outTensorData->GetTuple(outTensorIdx);

                    // go through output tensor components
                    for (i = 0; i < numCompsI; i++)
                    {
                        for (j = 0; j < numCompsJ; j++)
                        {
                            // Interpolate in X and Y at Z0
                            //
                            //-TENSOR- float comp1 = tensor1->GetComponent(i,j);
                            //-TENSOR- float comp2 = tensor2->GetComponent(i,j);
                            //-TENSOR- float comp3 = tensor3->GetComponent(i,j);
                            //-TENSOR- float comp4 = tensor4->GetComponent(i,j);

                            // interpolate in x
                            //-TENSOR- dx0 = x0*comp1 + x1*comp2; 
                            //-TENSOR- dx1 = x0*comp3 + x1*comp4;

                            dx0 = x0*inT1[i][j] + x1*inT2[i][j]; 
                            dx1 = x0*inT3[i][j] + x1*inT4[i][j];

                            // and interpolate in y
                            dxy0 = y0*dx0 + y1*dx1;

                            // Set output tensor value
                            //-TENSOR- tensor->SetComponent(i, j, dxy0);
                            outT[i][j] = dxy0;
                        }
                    }
                }
                // Not out of bounds or last slice
                else 
                {
                    x1 = x - xi;
                    y1 = y - yi;
                    z1 = z - zi;

                    x0 = 1.0 - x1;
                    y0 = 1.0 - y1;
                    z0 = 1.0 - z1;

                    idx = zi*nxy + yi*nx + xi;

                    // tensor indices.  Grab 8 tensors for interpolation.
                    int idx1 = zi*nxy + yi*nx + xi;
                    int idx2 = idx1 + 1;
                    int idx3 = idx1 + nx;
                    int idx4 = idx2 + nx;

                    int idx5 = idx1 + nxy;
                    int idx6 = idx5 + 1;
                    int idx7 = idx5 + nx;
                    int idx8 = idx6 + nx;

                    // get the tensors at these image indices
                    //-TENSOR- vtkTensor *tensor1 = inTensorData->GetTuple(idx1);
                    //-TENSOR- vtkTensor *tensor2 = inTensorData->GetTuple(idx2);
                    //-TENSOR- vtkTensor *tensor3 = inTensorData->GetTuple(idx3);
                    //-TENSOR- vtkTensor *tensor4 = inTensorData->GetTuple(idx4);
                    //-TENSOR- vtkTensor *tensor5 = inTensorData->GetTuple(idx5);
                    //-TENSOR- vtkTensor *tensor6 = inTensorData->GetTuple(idx6);
                    //-TENSOR- vtkTensor *tensor7 = inTensorData->GetTuple(idx7);
                    //-TENSOR- vtkTensor *tensor8 = inTensorData->GetTuple(idx8);

                    vtkFloatingPointType inT1[3][3], inT2[3][3], inT3[3][3], inT4[3][3];
                    vtkFloatingPointType inT5[3][3], inT6[3][3], inT7[3][3], inT8[3][3];
                    inTensorData->GetTuple(idx1,(vtkFloatingPointType *)inT1);
                    inTensorData->GetTuple(idx2,(vtkFloatingPointType *)inT2);
                    inTensorData->GetTuple(idx3,(vtkFloatingPointType *)inT3);
                    inTensorData->GetTuple(idx4,(vtkFloatingPointType *)inT4);
                    inTensorData->GetTuple(idx5,(vtkFloatingPointType *)inT5);
                    inTensorData->GetTuple(idx6,(vtkFloatingPointType *)inT6);
                    inTensorData->GetTuple(idx7,(vtkFloatingPointType *)inT7);
                    inTensorData->GetTuple(idx8,(vtkFloatingPointType *)inT8);

                    // find output location
                    //-TENSOR- vtkTensor *tensor = outTensorData->GetTuple(outTensorIdx);

                    // go through tensor components
                    for (i = 0; i < numCompsI; i++)
                    {
                        for (j = 0; j < numCompsJ; j++)
                        {
                            // Interpolate in X and Y at Z0
                            //
                            //-TENSOR- float comp1 = tensor1->GetComponent(i,j);
                            //-TENSOR- float comp2 = tensor2->GetComponent(i,j);
                            //-TENSOR- float comp3 = tensor3->GetComponent(i,j);
                            //-TENSOR- float comp4 = tensor4->GetComponent(i,j);

                            // interpolate in x
                            //-TENSOR- dx0 = x0*comp1 + x1*comp2; 
                            //-TENSOR- dx1 = x0*comp3 + x1*comp4;                      

                            dx0 = x0*inT1[i][j] + x1*inT2[i][j]; 
                            dx1 = x0*inT3[i][j] + x1*inT4[i][j];

                            // and interpolate in y
                            dxy0 = y0*dx0 + y1*dx1;

                            // Interpolate in X and Y at Z1
                            //
                            //-TENSOR- float comp5 = tensor5->GetComponent(i,j);
                            //-TENSOR- float comp6 = tensor6->GetComponent(i,j);
                            //-TENSOR- float comp7 = tensor7->GetComponent(i,j);
                            //-TENSOR- float comp8 = tensor8->GetComponent(i,j);

                            // interpolate in x
                            //-TENSOR- dx0 = x0*comp5 + x1*comp6; 
                            //-TENSOR- dx1 = x0*comp7 + x1*comp8;      
                            dx0 = x0*inT5[i][j] + x1*inT6[i][j]; 
                            dx1 = x0*inT7[i][j] + x1*inT8[i][j];

                            // and interpolate in y
                            dxy1 = y0*dx0 + y1*dx1;

                            // Interpolate in Z
                            //
                            //-TENSOR- tensor->SetComponent(i, j, z0*dxy0 + z1*dxy1);
                            outT[i][j] = z0*dxy0 + z1*dxy1;
                        }
                    }

                } // else

                // copy outT to output
                outTensorData->SetTuple(outTensorIdx,(vtkFloatingPointType *)outT);
                // test
                // outTensorData->SetTuple9(outTensorIdx,
                //                                     outT[0][0],
                //                                     outT[0][1],
                //                                     outT[0][2],
                //                                     outT[1][0],
                //                                     outT[1][1],
                //                                     outT[1][2],
                //                                     outT[2][0],
                //                                     outT[2][1],
                //                                     outT[2][2]);

                //outTensorData->SetTuple9(outTensorIdx,1,0,0,0.0,1.0,0.0,0.0,0.0,1.0);

                // go to next output tensor
                outTensorIdx++;

                // Step volume coordinates in xs direction
                x += xStep[0];
                y += xStep[1];
                z += xStep[2];

            }  // end loop over X (row)

            // Rewind volume coordinates back to first column
            x -= xRewind[0];
            y -= xRewind[1];
            z -= xRewind[2];

            // Step volume coordinates in y direction
            x += yStep[0];
            y += yStep[1];
            z += yStep[2];
        }
    }//interp

    //
    // Without interpolation 
    //
    else 
    {
        //cout << "Reformatting tensors without interpolation" << endl;
        nx2 = nx-1;
        ny2 = ny-1;
        nz2 = nz-1;

        // Loop through output pixels
        for (idxY = outExt[2]; idxY <= maxY; idxY++)
        {
            for (idxX = outExt[0]; idxX <= maxX; idxX++)
            {
                // Compute integer parts of volume coordinates
                xi = (int)(x + 0.5);
                yi = (int)(y + 0.5);
                zi = (int)(z + 0.5);

                // Test if coordinates are outside volume
                if ((xi < 0) || (yi < 0) || (zi < 0) ||
                        (xi > nx2) || (yi > ny2) || (zi > nz2))
                {
                    //-TENSOR- outTensorData->GetTuple(outTensorIdx)->Initialize();
                    for (i = 0; i < numCompsI; i++)
                    {
                        for (j = 0; j < numCompsJ; j++)
                        {
                            outT[i][j] = 0;
                        }
                    }
                    outTensorData->SetTuple(outTensorIdx,(vtkFloatingPointType *)outT);
                }
                else {
                    // Compute 'idx', the index into the input volume
                    // where the output pixel value comes from.
                    idx = zi*nxy + yi*nx + xi;

                    // Set output tensor value to match
                    outTensorData->SetTuple(outTensorIdx,inTensorData->GetTuple(idx));

                }

                // go to next output tensor
                outTensorIdx ++;

                // Step volume coordinates in xs direction
                x += xStep[0];
                y += xStep[1];
                z += xStep[2];
            }

            // Rewind volume coordinates back to first column
            x -= xRewind[0];
            y -= xRewind[1];
            z -= xRewind[2];

            // Step volume coordinates in ys direction
            x += yStep[0];
            y += yStep[1];
            z += yStep[2];
        }
    }//withoutInterpolation

    // keep track of run time (of one thread at least)
    if (id == 0) 
    {
        self->SetRunTime(clock() - tStart);
        // testing
        cout << "tensor reformat time: " << clock() - tStart << endl;
    }
}

//----------------------------------------------------------------------------
// Replace superclass Execute with a function that allocates tensors
// as well as scalars.  This gets called before multithreader starts
// (after which we can't allocate, for example in ThreadedExecute).
// Note we return to the regular pipeline at the end of this function.
// 
// A. Guimond did something similar in the ExecuteData function 
// available in vtk4.0.
//
//void vtkImageReformat::Execute()
void vtkImageReformat::ExecuteData(vtkDataObject *out)
{
    int i,ext[6];
    vtkImageData *input = this->GetInput();
    vtkImageData *output = vtkImageData::SafeDownCast(out);

    output->SetExtent(output->GetUpdateExtent());
    //output->AllocateScalars();  (done by superclass)

    // If we have tensors in the input
    if (input->GetPointData()->GetTensors() != NULL) {

        if (input->GetPointData()->GetTensors()->GetNumberOfTuples() > 0)
        {
            // allocate output tensors
            vtkFloatArray *data = vtkFloatArray::New(); 
            data->SetNumberOfComponents(9);
            int* dims = output->GetDimensions();
            data->SetNumberOfTuples(dims[0]*dims[1]*dims[2]);
            output->GetPointData()->SetTensors(data);
            data->Delete();
        }
    }
    
    //Set up common information: reformat, matrices, res, scale...
    // If no matrices provided, then create defaults
    if (!this->ReformatMatrix) 
    {
        // If the user has not set the ReformatMatrix, then create it.
        // The key is to perform: New(), Register(), Delete().
        // Then we can call UnRegister() in the destructor, and it will delete
        // the object if no one else is using it.  We don't have to distinguish
        // between whether we created the object, or someone else did!
        this->ReformatMatrix = vtkMatrix4x4::New();
        this->ReformatMatrix->Register(this);
        this->ReformatMatrix->Delete();
    }
    if (!this->WldToIjkMatrix) 
    {
        this->WldToIjkMatrix = vtkMatrix4x4::New();
        this->WldToIjkMatrix->Register(this);
        this->WldToIjkMatrix->Delete();

        this->GetInput()->GetWholeExtent(ext);
        for (i=0; i<3; i++)
        {
            this->WldToIjkMatrix->SetElement(i, 3, 
                    (ext[i*2+1] - ext[i*2] + 1) / 2.0);
        }
    }
    
    //Set up Zoom to 0.0001 if it's too small.
    if(this->GetZoom() < 0.0001)
      this->SetZoom(0.0001);
  
    this->SetPanScale(this->GetFieldOfView() / (this->GetResolution() * this->GetZoom()));
  
    //Set up originShiftMtx so all the threads see the same
    this->OriginShiftMtx->DeepCopy(this->ReformatMatrix);
    this->OriginShiftMtx->Element[0][3] = 0.0;
    this->OriginShiftMtx->Element[1][3] = 0.0;
    this->OriginShiftMtx->Element[2][3] = 0.0;
    
    // jump back into normal pipeline: call standard superclass method here
    //this->vtkImageToImageFilter::Execute(this->GetInput(), output);
    //this->vtkImageToImageFilter::Execute();
    this->Superclass::ExecuteData(output);
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkImageReformat::ThreadedExecute(vtkImageData *inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
    int *inExt = inData->GetExtent();
    void *inPtr = inData->GetScalarPointerForExtent(inExt);
    int wExt[6];
    // int ext[6];
    this->GetOutput()->GetWholeExtent(wExt);
    int numComps = inData->GetNumberOfScalarComponents();

    // Example values for the extents (for a 4-processor machine on a 124 slice volume) are:
    // id: 0 outExt: 0 255 0 63 0 0,    inExt: 0 255 0 255 0 123  wExt: 0 255 0 255 0 0
    // id: 1 outExt: 0 255 64 127 0 0,  inExt: 0 255 0 255 0 123  wExt: 0 255 0 255 0 0
    // id: 2 outExt: 0 255 128 191 0 0, inExt: 0 255 0 255 0 123  wExt: 0 255 0 255 0 0
    // id: 3 outExt: 0 255 192 255 0 0, inExt: 0 255 0 255 0 123  wExt: 0 255 0 255 0 0

    // If we have tensors in the input
    if (inData->GetPointData()->GetTensors() != NULL) {

        if (inData->GetPointData()->GetTensors()->GetNumberOfTuples() > 0)
        {
            vtkDebugMacro("Execute: tensors  in input image data");

            // For now just reformat tensors, ignore scalars
            vtkImageReformatExecuteTensor(this, inData, inExt, 
                    (short *)(inPtr), 
                    outData, outExt, wExt, id);
            // just remove this return to do scalars too
            // (inefficiently)
            return;
        }
    }


    // Use integer math for short and unsigned char data.
  int type = inData->GetScalarType();

#ifdef SLICER_VTK5
  //TODO type access is broken on vtk5?
  if ( type != VTK_SHORT )
  {
      vtkErrorMacro( "setting input data type to VTK_SHORT (4), was " << type);
      type = VTK_SHORT;
  }
#endif

    switch (type)
    {
        case VTK_DOUBLE:
            vtkImageReformatExecute(this, inData, inExt, (double *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_FLOAT:
            vtkImageReformatExecute(this, inData, inExt, (float*)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_LONG:
            vtkImageReformatExecute(this, inData, inExt, (long *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_UNSIGNED_LONG:
            vtkImageReformatExecute(this, inData, inExt, (unsigned long *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_INT:
            vtkImageReformatExecute(this, inData, inExt, (int *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_UNSIGNED_INT:
            vtkImageReformatExecute(this, inData, inExt, (unsigned int *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_SHORT:
            if (numComps == 1) {
                vtkImageReformatExecuteInt(this, inData, inExt, (short *)(inPtr), outData, outExt, wExt, id);
            } else {
                vtkImageReformatExecute(this, inData, inExt, (short *)(inPtr), outData, outExt, wExt, id);
            }
            break;
        case VTK_UNSIGNED_SHORT:
            vtkImageReformatExecute(this, inData, inExt, (unsigned short *)(inPtr), 
                    outData, outExt, wExt, id);
            break;
        case VTK_CHAR:
            if (numComps == 1) {
                vtkImageReformatExecuteInt(this, inData, inExt, (char *)(inPtr), outData, outExt, wExt, id);
            } else {
                vtkImageReformatExecute(this, inData, inExt, (char *)(inPtr), outData, outExt, wExt, id);
            }
            break;
        case VTK_UNSIGNED_CHAR:
            if (numComps == 1) {
                vtkImageReformatExecuteInt(this, inData, inExt, (unsigned char *)(inPtr), outData, outExt, wExt, id);
            } else {
                vtkImageReformatExecute(this, inData, inExt, (unsigned char *)(inPtr), outData, outExt, wExt, id);
            }
            break;
        default:
            vtkErrorMacro(<< "Execute: Unknown input ScalarType");
            return;
    }
}



//----------------------------------------------------------------------------
// Account for the MTime of the transform and its matrix when determinging
// the MTime of the filter
unsigned long vtkImageReformat::GetMTime()
{
    unsigned long mTime=this->vtkObject::GetMTime();
    unsigned long time;

    if ( this->ReformatMatrix != NULL )
    {
        time = this->ReformatMatrix->GetMTime();
        mTime = ( time > mTime ? time : mTime );
    }
    if ( this->WldToIjkMatrix != NULL)
    {
        time = this->WldToIjkMatrix->GetMTime();
        mTime = ( time > mTime ? time : mTime );
    }

    return mTime;
}
