/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageResliceST.cxx,v $
  Date:      $Date: 2006/02/01 15:36:50 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/
#include "vtkImageResliceST.h"
#include "vtkObjectFactory.h"
#include "vtkMath.h"
#include "vtkImageData.h"
#include "vtkMatrix4x4.h"
#include "vtkAbstractTransform.h"

#include <vtkStructuredPointsWriter.h>

static void Write(vtkImageData* image,const char* filename)
{
  vtkStructuredPointsWriter* writer = vtkStructuredPointsWriter::New();
  writer->SetFileTypeToBinary();
  writer->SetInput(image);
  writer->SetFileName(filename);
  writer->Write();
  writer->Delete();
}

//----------------------------------------------------------------------------
vtkImageResliceST* vtkImageResliceST::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageResliceST");
  if(ret)
    {
    return (vtkImageResliceST*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageResliceST;
}

//----------------------------------------------------------------------------
vtkImageResliceST::vtkImageResliceST()
{
}

//----------------------------------------------------------------------------
vtkImageResliceST::~vtkImageResliceST()
{
}

//----------------------------------------------------------------------------
void vtkImageResliceST::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageReslice::PrintSelf(os,indent);
}

//----------------------------------------------------------------------------
// Absolute value calculation of floats

inline float fastabs(const float f)
{int i=((*(int*)&f)&0x7fffffff);return (*(float*)&i);}


//----------------------------------------------------------------------------
// fast floor() function for converting a float to an int
// (the floor() implementation on some computers is much slower than this,
// because they require some 'exact' behaviour that we don't).

inline int vtkResliceFloor(float x, float &f)
{
  int ix = int(x);
  f = x-ix;
  if (f < 0) { f = x - (--ix); }

  return ix;
}

inline int vtkResliceFloor(float x)
{
  int ix = int(x);
  if (x-ix < 0) { ix--; }

  return ix;
}

inline int vtkResliceCeil(float x)
{
  int ix = int(x);
  if (x-ix > 0) { ix++; }

  return ix;
}

//----------------------------------------------------------------------------
//  Interpolation subroutines and associated code
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
// rounding functions, split and optimized for each type
// (because we don't want to round if the result is a float!)

// in the case of a tie between integers, the larger integer wins.

#ifdef VTK_SIGNED_CHAR
inline void vtkResliceRound(float val, signed char& rnd)
{
  rnd = (char)((int)(val+256.5f)-256);
}
#endif

inline void vtkResliceRound(float val, char& rnd)
{
  rnd = (char)((int)(val+256.5f)-256);
}

inline void vtkResliceRound(float val, unsigned char& rnd)
{
  rnd = (unsigned char)(val+0.5f);
}

inline void vtkResliceRound(float val, short& rnd)
{
  rnd = (short)((int)(val+32768.5f)-32768);
}

inline void vtkResliceRound(float val, unsigned short& rnd)
{
  rnd = (unsigned short)(val+0.5f);
}

inline void vtkResliceRound(float val, int& rnd)
{
  rnd = (int)(floor(val+0.5f));
}

inline void vtkResliceRound(float val, unsigned int& rnd)
{
  rnd = (unsigned int)(floor(val+0.5f));
}

inline void vtkResliceRound(float val, long& rnd)
{
  rnd = (long)(floor(val+0.5f));
}


inline void vtkResliceRound(float val, unsigned long& rnd)
{
  rnd = (unsigned long)(floor(val+0.5f));
}

#ifdef VTK_TYPE_USE_LONG_LONG
inline void vtkResliceRound(float val, long long& rnd)
{
  rnd = (long long)(floor(val+0.5f));
}

inline void vtkResliceRound(float val, unsigned long long& rnd)
{
  rnd = (unsigned long long)(floor(val+0.5f));
}
#endif

inline void vtkResliceRound(float val, float& rnd)
{
  rnd = (float)(val);
}

inline void vtkResliceRound(float val, double& rnd)
{
  rnd = (double)(val);
}

//----------------------------------------------------------------------------
// clamping functions for each type

#ifdef VTK_SIGNED_CHAR
template<class F>
inline void vtkResliceClamp(F val, signed char& clamp)
{
  if (val < VTK_SIGNED_CHAR_MIN)
    { 
    val = VTK_SIGNED_CHAR_MIN;
    }
  if (val > VTK_SIGNED_CHAR_MAX)
    { 
    val = VTK_SIGNED_CHAR_MAX;
    }
  vtkResliceRound(val,clamp);
}
#endif

template<class F>
inline void vtkResliceClamp(F val, char& clamp)
{
  if (val < VTK_CHAR_MIN)
    { 
    val = VTK_CHAR_MIN;
    }
  if (val > VTK_CHAR_MAX)
    { 
    val = VTK_CHAR_MAX;
    }
  vtkResliceRound(val,clamp);
}

template<class F>
inline void vtkResliceClamp(F val, unsigned char& clamp)
{
  if (val < VTK_UNSIGNED_CHAR_MIN)
    { 
    val = VTK_UNSIGNED_CHAR_MIN;
    }
  if (val > VTK_UNSIGNED_CHAR_MAX)
    { 
    val = VTK_UNSIGNED_CHAR_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, short& clamp)
{
  if (val < VTK_SHORT_MIN)
    { 
    val = VTK_SHORT_MIN;
    }
  if (val > VTK_SHORT_MAX)
    { 
    val = VTK_SHORT_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, unsigned short& clamp)
{
  if (val < VTK_UNSIGNED_SHORT_MIN)
    { 
    val = VTK_UNSIGNED_SHORT_MIN;
    }
  if (val > VTK_UNSIGNED_SHORT_MAX)
    { 
    val = VTK_UNSIGNED_SHORT_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, int& clamp)
{
  if (val < VTK_INT_MIN) 
    {
    val = VTK_INT_MIN;
    }
  if (val > VTK_INT_MAX) 
    {
    val = VTK_INT_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, unsigned int& clamp)
{
  if (val < VTK_UNSIGNED_INT_MIN)
    { 
    val = VTK_UNSIGNED_INT_MIN;
    }
  if (val > VTK_UNSIGNED_INT_MAX)
    { 
    val = VTK_UNSIGNED_INT_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, long& clamp)
{
  if (val < VTK_LONG_MIN) 
    {
    val = VTK_LONG_MIN;
    }
  if (val > VTK_LONG_MAX) 
    {
    val = VTK_LONG_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, unsigned long& clamp)
{
  if (val < VTK_UNSIGNED_LONG_MIN)
    { 
    val = VTK_UNSIGNED_LONG_MIN;
    }
  if (val > VTK_UNSIGNED_LONG_MAX)
    { 
    val = VTK_UNSIGNED_LONG_MAX;
    }
  vtkResliceRound(val,clamp);
}

#ifdef VTK_TYPE_USE_LONG_LONG
template <class F>
inline void vtkResliceClamp(F val, long long& clamp)
{
  if (val < VTK_LONG_LONG_MIN)
    { 
    val = VTK_LONG_LONG_MIN;
    }
  if (val > VTK_LONG_LONG_MAX)
    { 
    val = VTK_LONG_LONG_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, unsigned long long& clamp)
{
  if (val < VTK_UNSIGNED_LONG_LONG_MIN)
    { 
    val = VTK_UNSIGNED_LONG_LONG_MIN;
    }
  if (val > VTK_UNSIGNED_LONG_LONG_MAX)
    { 
    val = VTK_UNSIGNED_LONG_LONG_MAX;
    }
  vtkResliceRound(val,clamp);
}
#endif

template <class F>
inline void vtkResliceClamp(F val, float& clamp)
{
  if (val < VTK_FLOAT_MIN)
    { 
    val = VTK_FLOAT_MIN;
    }
  if (val > VTK_FLOAT_MAX) 
    {
    val = VTK_FLOAT_MAX;
    }
  vtkResliceRound(val,clamp);
}

template <class F>
inline void vtkResliceClamp(F val, double& clamp)
{
  if (val < VTK_FLOAT_MIN)
    { 
    val = VTK_FLOAT_MIN;
    }
  if (val > VTK_FLOAT_MAX) 
    {
    val = VTK_FLOAT_MAX;
    }
  vtkResliceRound(val,clamp);
}

//----------------------------------------------------------------------------
// copy a pixel, advance the output pointer but not the input pointer

template<class T>
inline void vtkCopyPixel(T *&out, T *in, int numscalars)
{
  do
    {
    *out++ = *in++;
    }
  while (--numscalars);
}

//----------------------------------------------------------------------------
// Perform a wrap to limit an index to [0,range).
// Ensures correct behaviour when the index is negative.
 
inline int vtkInterpolateWrap(int num, int range)
{
  if ((num %= range) < 0)
    {
    num += range; // required for some % implementations
    } 
  return num;
}

//----------------------------------------------------------------------------
// Perform a mirror to limit an index to [0,range).
 
inline int vtkInterpolateMirror(int num, int range)
{
  if (num < 0)
    {
    num = -num-1;
    }
  int count = num/range;
  num %= range;
  if (count & 0x1)
    {
    num = range-num-1;
    }
  return num;
}

//----------------------------------------------------------------------------
// Do trilinear interpolation of the input data 'inPtr' of extent 'inExt'
// at the 'point'.  The result is placed at 'outPtr'.  
// If the lookup data is beyond the extent 'inExt', set 'outPtr' to
// the background color 'background'.  
// The number of scalar components in the data is 'numscalars'
template <class T>
int vtkTrilinearInterpolation(float *point, T *inPtr, T *outPtr,
                     T *background, int numscalars, 
                     int inExt[6], int inInc[3])
{
  float fx,fy,fz;
  int floorX = vtkResliceFloor(point[0],fx);
  int floorY = vtkResliceFloor(point[1],fy);
  int floorZ = vtkResliceFloor(point[2],fz);

  int inIdX0 = floorX-inExt[0];
  int inIdY0 = floorY-inExt[2];
  int inIdZ0 = floorZ-inExt[4];

  int inIdX1 = inIdX0 + (fx != 0);
  int inIdY1 = inIdY0 + (fy != 0);
  int inIdZ1 = inIdZ0 + (fz != 0);
  
  if (inIdX0 < 0 || inIdX1 > inExt[1]-inExt[0]
      || inIdY0 < 0 || inIdY1 > inExt[3]-inExt[2]
      || inIdZ0 < 0 || inIdZ1 > inExt[5]-inExt[4] )
    {// out of bounds: clear to background color 
    if (background)
      {
      vtkCopyPixel(outPtr,background,numscalars);
      }
    return 0;
    }
  else 
    {// do trilinear interpolation
    int factX = inIdX0*inInc[0];
    int factY = inIdY0*inInc[1];
    int factZ = inIdZ0*inInc[2];

    int factX1 = inIdX1*inInc[0];
    int factY1 = inIdY1*inInc[1];
    int factZ1 = inIdZ1*inInc[2];
    
    int i000 = factX+factY+factZ;
    int i001 = factX+factY+factZ1;
    int i010 = factX+factY1+factZ;
    int i011 = factX+factY1+factZ1;
    int i100 = factX1+factY+factZ;
    int i101 = factX1+factY+factZ1;
    int i110 = factX1+factY1+factZ;
    int i111 = factX1+factY1+factZ1;

    float rx = 1.0f - fx;
    float ry = 1.0f - fy;
    float rz = 1.0f - fz;
      
    float ryrz = ry*rz;
    float ryfz = ry*fz;
    float fyrz = fy*rz;
    float fyfz = fy*fz;

    do
      {
      vtkResliceRound((rx*(ryrz*inPtr[i000]+ryfz*inPtr[i001]+
               fyrz*inPtr[i010]+fyfz*inPtr[i011])
               + fx*(ryrz*inPtr[i100]+ryfz*inPtr[i101]+
                 fyrz*inPtr[i110]+fyfz*inPtr[i111])),
              *outPtr++);
      inPtr++;
      }
    while (--numscalars);

    return 1;
    }
}              

// trilinear interpolation with wrap-around behaviour
template <class T>
int vtkTrilinearInterpolationRepeat(float *point, T *inPtr, T *outPtr,
                       T *mirror, int numscalars, 
                       int inExt[6], int inInc[3])
{
  float fx,fy,fz;
  int floorX = vtkResliceFloor(point[0],fx);
  int floorY = vtkResliceFloor(point[1],fy);
  int floorZ = vtkResliceFloor(point[2],fz);

  int inIdX = floorX-inExt[0];
  int inIdY = floorY-inExt[2];
  int inIdZ = floorZ-inExt[4];

  int inExtX = inExt[1]-inExt[0]+1;
  int inExtY = inExt[3]-inExt[2]+1;
  int inExtZ = inExt[5]-inExt[4]+1;

  int factX, factY, factZ;
  int factX1, factY1, factZ1;

  if (mirror)
    {
    factX = vtkInterpolateMirror(inIdX,inExtX)*inInc[0];
    factY = vtkInterpolateMirror(inIdY,inExtY)*inInc[1];
    factZ = vtkInterpolateMirror(inIdZ,inExtZ)*inInc[2];

    factX1 = vtkInterpolateMirror(inIdX+1,inExtX)*inInc[0];
    factY1 = vtkInterpolateMirror(inIdY+1,inExtY)*inInc[1];
    factZ1 = vtkInterpolateMirror(inIdZ+1,inExtZ)*inInc[2];
    }
  else
    {
    factX = vtkInterpolateWrap(inIdX,inExtX)*inInc[0];
    factY = vtkInterpolateWrap(inIdY,inExtY)*inInc[1];
    factZ = vtkInterpolateWrap(inIdZ,inExtZ)*inInc[2];

    factX1 = vtkInterpolateWrap(inIdX+1,inExtX)*inInc[0];
    factY1 = vtkInterpolateWrap(inIdY+1,inExtY)*inInc[1];
    factZ1 = vtkInterpolateWrap(inIdZ+1,inExtZ)*inInc[2];
    }

  int i000 = factX+factY+factZ;
  int i001 = factX+factY+factZ1;
  int i010 = factX+factY1+factZ;
  int i011 = factX+factY1+factZ1;
  int i100 = factX1+factY+factZ;
  int i101 = factX1+factY+factZ1;
  int i110 = factX1+factY1+factZ;
  int i111 = factX1+factY1+factZ1;

  float rx = 1.0f - fx;
  float ry = 1.0f - fy;
  float rz = 1.0f - fz;
  
  float ryrz = ry*rz;
  float ryfz = ry*fz;
  float fyrz = fy*rz;
  float fyfz = fy*fz;

  do
    {
    vtkResliceRound((rx*(ryrz*inPtr[i000]+ryfz*inPtr[i001]+
             fyrz*inPtr[i010]+fyfz*inPtr[i011])
             + fx*(ryrz*inPtr[i100]+ryfz*inPtr[i101]+
               fyrz*inPtr[i110]+fyfz*inPtr[i111])),
            *outPtr++);
    inPtr++;
    }
  while (--numscalars);

  return 1;
}              

// Do nearest-neighbor interpolation of the input data 'inPtr' of extent 
// 'inExt' at the 'point'.  The result is placed at 'outPtr'.  
// If the lookup data is beyond the extent 'inExt', set 'outPtr' to
// the background color 'background'.  
// The number of scalar components in the data is 'numscalars'

template <class T>
int vtkNearestNeighborInterpolation(float *point, T *inPtr, T *outPtr,
                                           T *background, int numscalars, 
                                           int inExt[6], int inInc[3])
{
  int inIdX = vtkResliceFloor(point[0]+0.5f)-inExt[0];
  int inIdY = vtkResliceFloor(point[1]+0.5f)-inExt[2];
  int inIdZ = vtkResliceFloor(point[2]+0.5f)-inExt[4];

  if (inIdX < 0 || inIdX > inExt[1]-inExt[0]
      || inIdY < 0 || inIdY > inExt[3]-inExt[2]
      || inIdZ < 0 || inIdZ > inExt[5]-inExt[4] )
    {
    if (background)
      {
      vtkCopyPixel(outPtr,background,numscalars);
      }
    return 0;
    }
  else 
    {
    inPtr += inIdX*inInc[0]+inIdY*inInc[1]+inIdZ*inInc[2];
    vtkCopyPixel(outPtr,inPtr,numscalars);

    return 1;
    }
} 

// nearest-neighbor interpolation with wrap-around behaviour
template <class T>
int vtkNearestNeighborInterpolationRepeat(float *point, T *inPtr, 
                         T *outPtr,
                         T *mirror, int numscalars, 
                         int inExt[6], int inInc[3])
{
  int inIdX = vtkResliceFloor(point[0]+0.5f)-inExt[0];
  int inIdY = vtkResliceFloor(point[1]+0.5f)-inExt[2];
  int inIdZ = vtkResliceFloor(point[2]+0.5f)-inExt[4];

  int inExtX = inExt[1]-inExt[0]+1;
  int inExtY = inExt[3]-inExt[2]+1;
  int inExtZ = inExt[5]-inExt[4]+1;

  if (mirror)
    {
    inIdX = vtkInterpolateMirror(inIdX,inExtX);
    inIdY = vtkInterpolateMirror(inIdY,inExtY);
    inIdZ = vtkInterpolateMirror(inIdZ,inExtZ);
    }
  else
    {
    inIdX = vtkInterpolateWrap(inIdX,inExtX);
    inIdY = vtkInterpolateWrap(inIdY,inExtY);
    inIdZ = vtkInterpolateWrap(inIdZ,inExtZ);
    }
  
  inPtr += inIdX*inInc[0]+inIdY*inInc[1]+inIdZ*inInc[2];
  vtkCopyPixel(outPtr,inPtr,numscalars);

  return 1; 
} 

// Do tricubic interpolation of the input data 'inPtr' of extent 'inExt' 
// at the 'point'.  The result is placed at 'outPtr'.  
// The number of scalar components in the data is 'numscalars'

// The tricubic interpolation ensures that both the intensity and
// the first derivative of the intensity are smooth across the
// image.  The first derivative is estimated using a 
// centered-difference calculation.


// helper function: set up the lookup indices and the interpolation 
// coefficients
static
void vtkImageResliceSetInterpCoeffs(float F[4],int *l, int *m, float f, 
                    int interpMode)
{   
  float fp1,fm1,fm2;

  switch (interpMode)
    {
    case 7:     // cubic interpolation
      *l = 0; *m = 4; 
      fm1 = f-1;
      F[0] = -f*fm1*fm1/2;
      F[1] = ((3*f-2)*f-2)*fm1/2;
      F[2] = -((3*f-4)*f-1)*f/2;
      F[3] = f*f*fm1/2;
      break;
    case 0:     // no interpolation
    case 2:
    case 4:
    case 6:
      *l = 1; *m = 2; 
      F[1] = 1;
      F[0] = F[2] = F[3] = 0.0f;
      break;
    case 1:     // linear interpolation
      *l = 1; *m = 3;
      F[0] = F[3] = 0.0;
      F[1] = 1-f;
      F[2] = f;
      break;
    case 3:     // quadratic interpolation
      *l = 1; *m = 4; 
      fm1 = f-1; fm2 = fm1-1;
      F[0] = 0.0f;
      F[1] = fm1*fm2/2;
      F[2] = -f*fm2;
      F[3] = f*fm1/2;
      break;
    case 5:     // quadratic interpolation
      *l = 0; *m = 3; 
      fp1 = f+1; fm1 = f-1; 
      F[0] = f*fm1/2;
      F[1] = -fp1*fm1;
      F[2] = fp1*f/2;
      F[3] = 0.0f;
      break;
    }
}

// tricubic interpolation
template <class T>
int vtkTricubicInterpolation(float *point, T *inPtr, T *outPtr,
                    T *background, int numscalars, 
                    int inExt[6], int inInc[3])
{
  float fx,fy,fz;
  int floorX = vtkResliceFloor(point[0],fx);
  int floorY = vtkResliceFloor(point[1],fy);
  int floorZ = vtkResliceFloor(point[2],fz);

  int inIdX = floorX-inExt[0];
  int inIdY = floorY-inExt[2];
  int inIdZ = floorZ-inExt[4];

  // the doInterpX,Y,Z variables are 0 if interpolation
  // does not have to be done in the specified direction,
  // i.e. if the x, y or z lookup indices have no fractional
  // component.   
  int doInterpX = (fx != 0);
  int doInterpY = (fy != 0);
  int doInterpZ = (fz != 0);

  // check whether we can do cubic interpolation, quadratic, linear, or none
  // in each of the three directions
  if (inIdX < 0 || inIdX+doInterpX > inExt[1]-inExt[0] ||
      inIdY < 0 || inIdY+doInterpY > inExt[3]-inExt[2] ||
      inIdZ < 0 || inIdZ+doInterpZ > inExt[5]-inExt[4])
    {// out of bounds: clear to background color
    if (background)
      {
      vtkCopyPixel(outPtr,background,numscalars);
      }
    return 0;
    }
  else 
    {// do tricubic interpolation
    float fX[4],fY[4],fZ[4];
    float vY,vZ,val;
    T *inPtr1, *inPtr2;
    int i,j,k,l,jl,jm,kl,km,ll,lm;
    int factX[4],factY[4],factZ[4];
    
    // depending on whether we are at the edge of the 
    // input extent, choose the appropriate interpolation
    // method to use

    int interpModeX = ((inIdX > 0) << 2) + 
      ((inIdX+2 <= inExt[1]-inExt[0]) << 1) +
      doInterpX;
    int interpModeY = ((inIdY > 0) << 2) + 
      ((inIdY+2 <= inExt[3]-inExt[2]) << 1) +
      doInterpY;
    int interpModeZ = ((inIdZ > 0) << 2) + 
      ((inIdZ+2 <= inExt[5]-inExt[4]) << 1) +
      doInterpZ;

    vtkImageResliceSetInterpCoeffs(fX,&ll,&lm,fx,interpModeX);
    vtkImageResliceSetInterpCoeffs(fY,&kl,&km,fy,interpModeY);
    vtkImageResliceSetInterpCoeffs(fZ,&jl,&jm,fz,interpModeZ);

    for (i = 0; i < 4; i++)
      {
      factX[i] = (inIdX+i-1)*inInc[0];
      factY[i] = (inIdY+i-1)*inInc[1];
      factZ[i] = (inIdZ+i-1)*inInc[2];
      }

    // set things up so that we can unroll the inner X loop safely
    for (l = 0; l < ll; l++)
      {
      factX[l] = inIdX*inInc[0];
      }
    for (l = lm; l < 4; l++)
      {
      factX[l] = inIdX*inInc[0];
      }

    // Finally, here is the tricubic interpolation
    // (or cubic-cubic-linear, or cubic-nearest-cubic, etc)
    do
      {
      val = 0;
      j = jl;
      do
        {
        inPtr1 = inPtr + factZ[j];
        vZ = 0;
        k = kl;
        do
          {
      inPtr2 = inPtr1 + factY[k];
      vY = *(inPtr2+factX[0]) * fX[0] +
        *(inPtr2+factX[1]) * fX[1] +
        *(inPtr2+factX[2]) * fX[2] +
        *(inPtr2+factX[3]) * fX[3];
      vZ += vY*fY[k]; 
          }
        while (++k < km);
        val += vZ*fZ[j];
        }
      while (++j < jm);
      vtkResliceClamp(val,*outPtr++); // clamp to limits of type
      inPtr++;
      }
    while (--numscalars);

    return 1;
    }
}          

// tricubic interpolation with wrap-around behaviour
template <class T>
int vtkTricubicInterpolationRepeat(float *point, T *inPtr, T *outPtr,
                      T *mirror, int numscalars, 
                      int inExt[6], int inInc[3])
{
  int factX[4],factY[4],factZ[4];

  float fx,fy,fz;
  int floorX = vtkResliceFloor(point[0],fx);
  int floorY = vtkResliceFloor(point[1],fy);
  int floorZ = vtkResliceFloor(point[2],fz);

  float fX[4],fY[4],fZ[4];
  float vY,vZ,val;
  T *inPtr1, *inPtr2;
  int i,j,k,jl,jm,kl,km;

  int inIdX = floorX-inExt[0];
  int inIdY = floorY-inExt[2];
  int inIdZ = floorZ-inExt[4];

  int inExtX = inExt[1]-inExt[0]+1;
  int inExtY = inExt[3]-inExt[2]+1;
  int inExtZ = inExt[5]-inExt[4]+1;

  if (mirror)
    {
    for (i = 0; i < 4; i++)
      {
      factX[i] = vtkInterpolateMirror(inIdX-1+i,inExtX)*inInc[0];
      factY[i] = vtkInterpolateMirror(inIdY-1+i,inExtY)*inInc[1];
      factZ[i] = vtkInterpolateMirror(inIdZ-1+i,inExtZ)*inInc[2];
      }
    }
  else
    {
    for (i = 0; i < 4; i++)
      {
      factX[i] = vtkInterpolateWrap(inIdX-1+i,inExtX)*inInc[0];
      factY[i] = vtkInterpolateWrap(inIdY-1+i,inExtY)*inInc[1];
      factZ[i] = vtkInterpolateWrap(inIdZ-1+i,inExtZ)*inInc[2];
      }
    }

  vtkImageResliceSetInterpCoeffs(fX,&i,&i,fx,7);
  vtkImageResliceSetInterpCoeffs(fY,&kl,&km,fy,6+(fy != 0));
  vtkImageResliceSetInterpCoeffs(fZ,&jl,&jm,fz,6+(fz != 0));

  // Finally, here is the tricubic interpolation
  do
    {
    val = 0;
    j = jl;
    do
      {
      inPtr1 = inPtr + factZ[j];
      vZ = 0;
      k = kl;
      do
        {
        inPtr2 = inPtr1 + factY[k];
        vY = *(inPtr2+factX[0]) * fX[0] +
      *(inPtr2+factX[1]) * fX[1] +
      *(inPtr2+factX[2]) * fX[2] +
      *(inPtr2+factX[3]) * fX[3];
        vZ += vY*fY[k]; 
        }
      while (++k < km);
      val += vZ*fZ[j];
      }
    while (++j < jm);
    vtkResliceClamp(val,*outPtr++); // clamp to limits of type
    inPtr++;
    }
  while (--numscalars);

  return 1;
}

//----------------------------------------------------------------------------
// Some helper functions
//----------------------------------------------------------------------------

// Convert background color from float to appropriate type, or set up
// the pointer to distinguish between Wrap and Mirror

template <class T>
static void vtkAllocBackground(vtkImageReslice *self, T **background_ptr, 
                   int numComponents)
{
  if (self->GetWrap() || self->GetMirror())
    {
    // kludge to differentiate between wrap and mirror
    *background_ptr = (T *)self->GetMirror();
    }
  else
    {
    int i;
    *background_ptr = new T[numComponents];
    T *background = *background_ptr;

    for (i = 0; i < numComponents; i++)
      {
      if (i < 4)
        {
        vtkResliceClamp(self->GetBackgroundColor()[i],background[i]);
        }
      else
        {
        background[i] = 0;
        }
      }
    }
}

template <class T>
static void vtkFreeBackground(vtkImageReslice *self, T **background_ptr)
{
  if (!(self->GetWrap() || self->GetMirror()))
    {
    delete [] *background_ptr;
    }
  *background_ptr = NULL;
}

// get appropriate interpolation function
template <class T>
static void vtkGetResliceInterpFunc(vtkImageReslice *self, 
                    int (**interpolate)(float *point, 
                            T *inPtr, T *outPtr,
                            T *background, 
                            int numscalars, 
                            int inExt[6], 
                            int inInc[3]))
{
  if (self->GetWrap() || self->GetMirror())
    {
    switch (self->GetInterpolationMode())
      {
      case VTK_RESLICE_NEAREST:
        *interpolate = &vtkNearestNeighborInterpolationRepeat;
        break;
      case VTK_RESLICE_LINEAR:
        *interpolate = &vtkTrilinearInterpolationRepeat;
        break;
      case VTK_RESLICE_CUBIC:
        *interpolate = &vtkTricubicInterpolationRepeat;
        break;
      }
    }
  else
    {
    switch (self->GetInterpolationMode())
      {
      case VTK_RESLICE_NEAREST:
        *interpolate = &vtkNearestNeighborInterpolation;
        break;
      case VTK_RESLICE_LINEAR:
        *interpolate = &vtkTrilinearInterpolation;
        break;
      case VTK_RESLICE_CUBIC:
        *interpolate = &vtkTricubicInterpolation;
        break;
      }
    }    
}


//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
// (this one function is pretty much the be-all and end-all of the
// filter)
template <class T>
static void vtkImageResliceSTExecute(vtkImageResliceST *self,
                     vtkImageData *inData, T *inPtr,
                     vtkImageData *outData, T *outPtr,
                     int outExt[6], int id)
{

  int numscalars; //, outvoxzero;
  int idX, idY, idZ;
  int outIncX, outIncY, outIncZ;
  int inExt[6], inInc[3];
  unsigned long count = 0;
  unsigned long target;
  float point[4];
  float f;
//  float *inSpacing,*inOrigin,*outSpacing,*outOrigin,inInvSpacing[3];
  vtkFloatingPointType *inSpacing,*inOrigin,*outSpacing,*outOrigin,inInvSpacing[3];
  T *background;
  int (*interpolate)(float *point, T *inPtr, T *outPtr,
                     T *background, int numscalars,
                     int inExt[6], int inInc[3]);
  float derivatives[3][3];
  float pi = 3.1415926535;
  vtkAbstractTransform *transform = self->GetResliceTransform();
  vtkMatrix4x4 *matrix = self->GetResliceAxes();

  inOrigin = inData->GetOrigin();
  inSpacing = inData->GetSpacing();
  outOrigin = outData->GetOrigin();
  outSpacing = outData->GetSpacing();

  // save effor later: invert inSpacing
  inInvSpacing[0] = 1.0f/inSpacing[0];
  inInvSpacing[1] = 1.0f/inSpacing[1];
  inInvSpacing[2] = 1.0f/inSpacing[2];

  // find maximum input range
  inData->GetExtent(inExt);
  
  target = (unsigned long)
    ((outExt[5]-outExt[4]+1)*(outExt[3]-outExt[2]+1)/50.0);
  target++;
  
  // Get Increments to march through data 
  inData->GetIncrements(inInc);
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
  numscalars = inData->GetNumberOfScalarComponents();
  
  // set color for area outside of input volume extent
  vtkAllocBackground(self,&background,numscalars);

  // Set interpolation method
  vtkGetResliceInterpFunc(self,&interpolate);

  // Setup SVD data
  //T outvox[numscalars];
  //Modified by Liu;
  T* outvox = NULL;
  if (numscalars > 0)
      outvox = new T[numscalars];
  int i;


  float U[3][3];
  float w[3];
  float VT[3][3];

  // Loop through output pixels
  for (idZ = outExt[4]; idZ <= outExt[5]; idZ++)
    {
    for (idY = outExt[2]; idY <= outExt[3]; idY++)
      {
      if (!id) 
        {
        if (!(count%target)) 
          {
          self->UpdateProgress(count/(50.0*target));
          }
        count++;
        }
      
      for (idX = outExt[0]; idX <= outExt[1]; idX++)
        {
        point[0] = idX*outSpacing[0] + outOrigin[0];
        point[1] = idY*outSpacing[1] + outOrigin[1];
        point[2] = idZ*outSpacing[2] + outOrigin[2];

        if (matrix)
          {
          point[3] = 1.0f;
          matrix->MultiplyPoint(point,point);
          f = 1.0f/point[3];
          point[0] *= f; // deal with w if the matrix
          point[1] *= f; //   was a Homogeneous transform
          point[2] *= f;
          }
        if (transform)
          {
          transform->InternalTransformDerivative(point,point,derivatives);
          }
        
        point[0] = (point[0] - inOrigin[0])*inInvSpacing[0];
        point[1] = (point[1] - inOrigin[1])*inInvSpacing[1];
        point[2] = (point[2] - inOrigin[2])*inInvSpacing[2];
        interpolate(point, inPtr, outvox, background, 
                numscalars, inExt, inInc);
    
        // Tensor reorientation using the Finite Strain method
        vtkMath::SingularValueDecomposition3x3(derivatives,U,w,VT);

        // VT=U.VT
        vtkMath::Multiply3x3(U,VT,VT);
        // U=VT^t  (in reality (U.VT)^t)
        //for(int i=0;i<3;++i)
        //Modofied by Liu
        for(i=0;i<3;++i)
          {
          U[i][i]=VT[i][i];
          for(int j=i+1;j<3;++j)
            {
            U[i][j]=VT[j][i];
            U[j][i]=VT[i][j];
            }
          }
         // derivatives=tensor
        derivatives[0][0]                  =outvox[numscalars-6];
        derivatives[0][1]=derivatives[1][0]=outvox[numscalars-5];
        derivatives[0][2]=derivatives[2][0]=outvox[numscalars-4];
        derivatives[1][1]                  =outvox[numscalars-3];
        derivatives[1][2]=derivatives[2][1]=outvox[numscalars-2];
        derivatives[2][2]                  =outvox[numscalars-1];

        // T'=(U.VT)^t . T . U.VT
        vtkMath::Multiply3x3(U,derivatives,U);
        vtkMath::Multiply3x3(U,VT,U); 

        for( i=0;i<numscalars-6;++i)
          {
          *outPtr++ = outvox[i];
          }
        *outPtr++ = T(U[0][0]);
        *outPtr++ = T(U[0][1]);
        *outPtr++ = T(U[0][2]);
        *outPtr++ = T(U[1][1]);
        *outPtr++ = T(U[1][2]);
        *outPtr++ = T(U[2][2]);
          //     interpolate(point, inPtr, outPtr, background, 
          //             numscalars, inExt, inInc);
          //         outPtr+=6;
        }
        outPtr += outIncY;
      }
      outPtr += outIncZ;
    }

  vtkFreeBackground(self,&background);

  // Modified by Liu
  if (outvox != NULL) 
      delete[] outvox;
} 

//----------------------------------------------------------------------------
// This method is passed a input and output region, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the regions data types.
void vtkImageResliceST::ThreadedExecute(vtkImageData *inData, 
                    vtkImageData *outData,
                    int outExt[6], int id)
{
  void *inPtr = inData->GetScalarPointerForExtent(inData->GetExtent());
  void *outPtr = outData->GetScalarPointerForExtent(outExt);
  
  vtkDebugMacro(<< "Execute: inData = " << inData 
        << ", outData = " << outData);
  
  // this filter expects that input is the same type as output.
  if (inData->GetScalarType() != outData->GetScalarType())
    {
    vtkErrorMacro(<< "Execute: input ScalarType, " << inData->GetScalarType()
          << ", must match out ScalarType " << outData->GetScalarType());
    return;
    }

  // this filter expects that input is the same type as output.
  if (inData->GetNumberOfScalarComponents() < 6)
    {
    vtkErrorMacro(<< "Execute: input NumberOfScalarCompoents, "
                  << inData->GetNumberOfScalarComponents()
                  << ", should be >= 6");
    return;
    }

  switch (inData->GetScalarType())
    {
    vtkTemplateMacro7(vtkImageResliceSTExecute, this, inData, (VTK_TT *)(inPtr),
              outData, (VTK_TT *)(outPtr), outExt, id);
    default:
      vtkErrorMacro(<< "Execute: Unknown input ScalarType");
    }
}
