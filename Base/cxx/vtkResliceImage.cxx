/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkResliceImage.cxx,v $
  Date:      $Date: 2006/03/06 19:02:27 $
  Version:   $Revision: 1.15 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Samson Timoner TetraMesh Library
  Module:    $RCSfile: vtkResliceImage.cxx,v $
  Language:  C++
  Date:      $Date: 2006/03/06 19:02:27 $
  Version:   $Revision: 1.15 $
  
Copyright (c) 2001 Samson Timoner

This software is not to be edited, distributed, copied, moved, etc.
without express permission of the author. 

========================================================================= */

#include "vtkResliceImage.h"

#include "vtkObjectFactory.h"
#include "vtkMatrix4x4.h"
#include "vtkImageData.h"

#define vtkTrilinFuncMacro(v,x,y,z,a,b,c,d,e,f,g,h)         \
        t00 =   a + (x)*(b-a);      \
        t01 =   c + (x)*(d-c);      \
        t10 =   e + (x)*(f-e);      \
        t11 =   g + (x)*(h-g);      \
        t0  = t00 + (y)*(t01-t00);  \
        t1  = t10 + (y)*(t11-t10);  \
        v   = (T)( t0 + (z)*(t1-t0));

vtkCxxSetObjectMacro(vtkResliceImage,TransformOutputToInput,vtkMatrix4x4);

//------------------------------------------------------------------------------
vtkResliceImage* vtkResliceImage::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkResliceImage");
  if(ret)
    {
    return (vtkResliceImage*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkResliceImage;
}

//----------------------------------------------------------------------------
vtkResliceImage::vtkResliceImage()
{
  Background = 0;
  OutSpacing[0] = OutSpacing[1] = OutSpacing[2] = 1.0;
  OutOrigin[0] = OutOrigin[1] = OutOrigin[2] = 0.0;
  OutExtent[0] = OutExtent[2] = OutExtent[4] = 0;
  OutExtent[1] = OutExtent[3] = OutExtent[5] = 1;
  TransformOutputToInput = NULL;
}
//----------------------------------------------------------------------------
void vtkResliceImage::SetOutputImageParam(vtkImageData *VolumeToCopyParam)
{
  VolumeToCopyParam->GetSpacing(this->OutSpacing);
  VolumeToCopyParam->GetOrigin(this->OutOrigin);
  VolumeToCopyParam->GetWholeExtent(this->OutExtent);
}
//----------------------------------------------------------------------------
vtkMatrix4x4 *vtkResliceImage::GetIJKtoIJKMatrix(vtkFloatingPointType Spacing2[3],
                                                 vtkFloatingPointType Origin2[3],
                                                 vtkMatrix4x4 *MM2toMM1,
                                                 vtkFloatingPointType Spacing1[3],
                                                 vtkFloatingPointType Origin1[3])
{
  // The IJK to MM matrix for Coordinate System 2
  vtkMatrix4x4 *XformIJKtoMM = vtkMatrix4x4::New();

  // First Adjust for Spacing2 and Origin2
  XformIJKtoMM->Identity();
  XformIJKtoMM->Element[0][0] = Spacing2[0];
  XformIJKtoMM->Element[1][1] = Spacing2[1];
  XformIJKtoMM->Element[2][2] = Spacing2[2];

  XformIJKtoMM->Element[0][3] = Origin2[0];
  XformIJKtoMM->Element[1][3] = Origin2[1];
  XformIJKtoMM->Element[2][3] = Origin2[2];

  // The MM to IJK on coordinate system 1
  vtkMatrix4x4 *XformMMtoIJK = vtkMatrix4x4::New();
  XformMMtoIJK->Identity();
  XformMMtoIJK->Element[0][0] = 1/Spacing1[0];
  XformMMtoIJK->Element[1][1] = 1/Spacing1[1];
  XformMMtoIJK->Element[2][2] = 1/Spacing1[2];

  XformMMtoIJK->Element[0][3] = Origin1[0]/Spacing1[0];
  XformMMtoIJK->Element[1][3] = Origin1[1]/Spacing1[1];
  XformMMtoIJK->Element[2][3] = Origin1[2]/Spacing1[2];

  //  XformIJKtoMM->Print(cout);
  //  XformMMtoIJK->Print(cout);
  vtkMatrix4x4 *Xform2to1 = vtkMatrix4x4::New();

  // If the MM2toMM1 transform is NULL, assume the identity
  if (MM2toMM1 != NULL)
    {
      vtkMatrix4x4::Multiply4x4(MM2toMM1,XformIJKtoMM,Xform2to1);
    }
  else
    {
      Xform2to1->DeepCopy(XformIJKtoMM);
    }
  //  Xform2to1->Print(cout);
  vtkMatrix4x4::Multiply4x4(XformMMtoIJK,Xform2to1,Xform2to1);
  Xform2to1->Print(cout);
  XformIJKtoMM->Delete();
  XformMMtoIJK->Delete();
  return Xform2to1;
}
//----------------------------------------------------------------------------
inline void vtkResliceImage::FindInputIJK(vtkFloatingPointType OtherIJK[4],
                                          vtkMatrix4x4 *IJKtoIJK,
                                          int i, int j, int k)
{
  vtkFloatingPointType inpoint[4];
  inpoint[0] = (vtkFloatingPointType) i; 
  inpoint[1] = (vtkFloatingPointType) j; 
  inpoint[2] = (vtkFloatingPointType) k;
  inpoint[3] = 1;
  IJKtoIJK->MultiplyPoint(inpoint,OtherIJK);
//  IJKtoIJK->Print(cout);
//  cout << inpoint[0] << ' ' << inpoint[1] << ' ' << inpoint[2] 
//       << ' ' << inpoint[3] <<'\n';
//  cout << OtherIJK[0] << ' ' << OtherIJK[1] << ' ' << OtherIJK[2] << ' ' 
//       << OtherIJK[3] << '\n';
}

//----------------------------------------------------------------------------
void vtkResliceImage::ExecuteInformation(vtkImageData *inData, 
                      vtkImageData *outData)
{
  outData->SetOrigin(this->OutOrigin);
  outData->SetWholeExtent(this->OutExtent);
  outData->SetSpacing(this->OutSpacing);

  outData->SetNumberOfScalarComponents(inData->GetNumberOfScalarComponents());
  outData->SetScalarType(inData->GetScalarType());
}

//----------------------------------------------------------------------------
// What input should be requested.
// To be very conservative, I need the entire input range.
void vtkResliceImage::ComputeInputUpdateExtent(int InExt[6], 
                                               int OutExt[6])
{

  vtkImageData *input = this->GetInput();
  vtkFloatingPointType InSpace[3];   input ->GetSpacing(InSpace);
  vtkFloatingPointType OutSpace[3];  this->GetOutput()->GetSpacing(OutSpace);
  vtkFloatingPointType InOrigin[3];  input ->GetOrigin(InOrigin);
  vtkFloatingPointType OutOrigin_[3]; this->GetOutput()->GetOrigin(OutOrigin_);

  vtkMatrix4x4 *IJKtoIJK_ = 
    vtkResliceImage::GetIJKtoIJKMatrix(OutSpace,OutOrigin_,
                                       this->GetTransformOutputToInput(),
                                       InSpace,InOrigin);

  // Get the wholeExtent
  int WholeExt[6];
  this->GetInput()->GetWholeExtent(WholeExt);

  InExt[0] = InExt[2] = InExt[4] = VTK_INT_MAX;
  InExt[1] = InExt[3] = InExt[5] = VTK_INT_MIN;

  vtkFloatingPointType point[4],result[4];
  point[3] = 1;

  for(int i=0;i<2;i++)
    for(int j=0;j<2;j++)
      for(int k=0;k<2;k++)
        {
          point[0]=(vtkFloatingPointType)OutExt[0+i];
          point[1]=(vtkFloatingPointType)OutExt[2+j];
          point[2]=(vtkFloatingPointType)OutExt[4+k];
          IJKtoIJK_->MultiplyPoint(point,result);
          if (floor(result[0]) < InExt[0]) InExt[0] = (int)floor(result[0]);
          if (floor(result[1]) < InExt[2]) InExt[2] = (int)floor(result[1]);
          if (floor(result[2]) < InExt[4]) InExt[4] = (int)floor(result[2]);

          if (ceil(result[0]) > InExt[1]) InExt[1] = (int)ceil(result[0]);
          if (ceil(result[1]) > InExt[3]) InExt[3] = (int)ceil(result[1]);
          if (ceil(result[2]) > InExt[5]) InExt[5] = (int)ceil(result[2]);
        }
  if(InExt[0] < WholeExt[0]) InExt[0] = WholeExt[0];
  if(InExt[2] < WholeExt[2]) InExt[2] = WholeExt[2];
  if(InExt[4] < WholeExt[4]) InExt[4] = WholeExt[4];

  if(InExt[1] > WholeExt[1]) InExt[1] = WholeExt[1];
  if(InExt[3] > WholeExt[3]) InExt[3] = WholeExt[3];
  if(InExt[5] > WholeExt[5]) InExt[5] = WholeExt[5];

  IJKtoIJK_->Delete();
}


//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
template <class T>
void vtkResliceImageExecute(vtkResliceImage *self, int id,
                            vtkImageData *inData, T *inPtr,
                            int *InExt,
                            vtkImageData *outData, T *outPtr,
                            int *OutExt)
{
  //
  // Variables for handling the image data
  //

  int inIncX, inIncY, inIncZ;
  int outIncX, outIncY, outIncZ;

  // Get increments to march through data
  // Number of scalars had better be 1
  inData->GetIncrements(inIncX, inIncY, inIncZ);
  outData->GetIncrements(outIncX, outIncY, outIncZ);

//  cout << "Input Extent: ";
//  cout << InExt[0] << ' ' << InExt[1] << ' ' << InExt[2] << ' '
//       << InExt[3] << ' ' << InExt[4] << ' ' << InExt[5] << '\n';
//
//  cout << "Output Extent: ";
//  cout << OutExt[0] << ' ' << OutExt[1] << ' ' << OutExt[2] << ' '
//       << OutExt[3] << ' ' << OutExt[4] << ' ' << OutExt[5] << '\n';

  vtkFloatingPointType InSpace[3];   inData->GetSpacing(InSpace);
  vtkFloatingPointType OutSpace[3]; outData->GetSpacing(OutSpace);
  vtkFloatingPointType InOrigin[3];  inData->GetOrigin(InOrigin);
  vtkFloatingPointType OutOrigin[3]; outData->GetOrigin(OutOrigin);

  vtkMatrix4x4 *IJKtoIJK = 
    vtkResliceImage::GetIJKtoIJKMatrix(OutSpace,OutOrigin,
                                       self->GetTransformOutputToInput(),
                                       InSpace,InOrigin);

  //  vtkFloatingPointType InputIJK[4];
  T *outVol1,*outVol2;
  T *InVol, *OutVol;
  OutVol = outVol2 = outVol1 = outPtr;
  T min,max;

  max = (T) inData->GetScalarTypeMin();
  min = (T) inData->GetScalarTypeMax();

  //  cout << "Increments:" << outIncX << ' ' << outIncY << ' ' << outIncZ << '\n';

  //
  // This is interesting
  // Rather than doing lots of matrix multiplies, simply pick off
  // the results of the matrix to a bunch of basis vectors and add
  //
  vtkFloatingPointType InijkX[4],InijkY[4],InijkZ[4]; // the position vectors
  vtkFloatingPointType ijkIncrementX[3],ijkIncrementY[3],ijkIncrementZ[3];
  vtkResliceImage::FindInputIJK(InijkX,IJKtoIJK,OutExt[0],OutExt[2],OutExt[4]);
  for(int p=0;p<3;p++)
    {
      InijkY[p] = InijkZ[p] = InijkX[p];
      ijkIncrementX[p] = IJKtoIJK->GetElement(p,0);
      ijkIncrementY[p] = IJKtoIJK->GetElement(p,1);
      ijkIncrementZ[p] = IJKtoIJK->GetElement(p,2);
    }

  for(int k=OutExt[4];k<=OutExt[5];k++)  
    {
      for(int j=OutExt[2];j<=OutExt[3];j++)  
        {
          for(int i=OutExt[0];i<=OutExt[1];i++)
            {
              //  vtkResliceImage::FindInputIJK(InputIJK,IJKtoIJK,i,j,k);
//              cout << i << ' ' << j << ' ' << k << ":"
//                   << InputIJK[0] - InijkX[0] << ' '
//                   << InputIJK[1] - InijkX[1] << ' '
//                   << InputIJK[2] - InijkX[2] << '\n';

              if ((InijkX[0] >= InExt[0])&&(InijkX[0] <= InExt[1])&&
                  (InijkX[1] >= InExt[2])&&(InijkX[1] <= InExt[3])&&
                  (InijkX[2] >= InExt[4])&&(InijkX[2] <= InExt[5]))
                {
                  int x0 = (int) floor(InijkX[0]);
                  vtkFloatingPointType x = InijkX[0] - x0;
                  int y0 = (int) floor(InijkX[1]);
                  vtkFloatingPointType y = InijkX[1] - y0;
                  int z0 = (int) floor(InijkX[2]);
                  vtkFloatingPointType z = InijkX[2] - z0;
                  
                  InVol = inPtr + (x0-InExt[0])*inIncX
                    +(y0-InExt[2])*inIncY
                    +(z0-InExt[4])*inIncZ;

                  double a,b,c,d,e,f,g,h,t00,t01,t11,t10,t0,t1;
                  
                  // a = ?[x0  ][y0  ][z0  ];
                  a = (double) *InVol;
                  // b = ?[x0+1][y0  ][z0  ];
                  b = (double) *(InVol + inIncX);
                  // c = ?[x0  ][y0+1][z0  ];
                  c = (double) *(InVol          + inIncY);
                  // d = ?[x0+1][y0+1][z0  ];
                  d = (double) *(InVol + inIncX + inIncY);
                  // e = ?[x0  ][y0  ][z0+1];
                  e = (double) *(InVol                    + inIncZ);
                  // f = ?[x0+1][y0  ][z0+1];
                  f = (double) *(InVol + inIncX          + inIncZ);
                  // g = ?[x0  ][y0+1][z0+1];
                  g = (double) *(InVol +        + inIncY + inIncZ);
                  // h = ?[x0+1][y0+1][z0+1];
                  h = (double) *(InVol + inIncX + inIncY + inIncZ);
                  
                  vtkTrilinFuncMacro(*OutVol,x,y,z,a,b,c,d,e,f,g,h);

//                  cout << x << ' ' << y << ' ' << z << ' ' << '\n';
//                  cout << a << ' '
//                       << b << ' '
//                       << c << ' '
//                       << d << ' '
//                       << e << ' '
//                       << f << ' '
//                       << g << '\n';
//

//                  cout << i << ' ' << j << ' ' << k << ":" 
//                       << InijkX[0] << ' ' << InijkX[1] << ' ' 
//                       << InijkX[2] << ": ";
//                  cout << *OutVol << '\n';
                }
              else
                {
                  *(OutVol) = (T) self->GetBackground();
                }
              if (*(OutVol) > max) max = *OutVol;
              if (*(OutVol) < min) min = *OutVol;
              OutVol += outIncX;
              InijkX[0] += ijkIncrementX[0];
              InijkX[1] += ijkIncrementX[1];
              InijkX[2] += ijkIncrementX[2];
            }
          outVol2 += outIncY;
          OutVol = outVol2;
          InijkY[0] += ijkIncrementY[0];
          InijkY[1] += ijkIncrementY[1];
          InijkY[2] += ijkIncrementY[2];

          InijkX[0] = InijkY[0];
          InijkX[1] = InijkY[1];
          InijkX[2] = InijkY[2];
        }
      InijkZ[0] += ijkIncrementZ[0];
      InijkZ[1] += ijkIncrementZ[1];
      InijkZ[2] += ijkIncrementZ[2];

      InijkY[0] = InijkX[0] = InijkZ[0];
      InijkY[1] = InijkX[1] = InijkZ[1];
      InijkY[2] = InijkX[2] = InijkZ[2];

      outVol1 += outIncZ;
      OutVol = outVol2 = outVol1;
    }
  cout << "min: " << min << '\n';
  cout << "max: " << max << '\n';
  IJKtoIJK->Delete();
}

/* ====================================================================== */


void vtkResliceImage::ThreadedExecute(vtkImageData *inData, 
                      vtkImageData *outData,
                      int outExt[6], int id)
{
  int inExt[6];
  this->ComputeInputUpdateExtent(inExt,outExt);
  void *inPtr = inData->GetScalarPointerForExtent(inExt);
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
  
  switch (inData->GetScalarType())
    {
    vtkTemplateMacro8(vtkResliceImageExecute, this, id, inData, 
                      (VTK_TT *)(inPtr), inExt, 
                      outData, (VTK_TT *)(outPtr), outExt);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}

void vtkResliceImage::PrintSelf(ostream& os, vtkIndent indent)
{
  Superclass::PrintSelf(os,indent);

  os << indent << "Matrix is Null: " << 
    (this->TransformOutputToInput == NULL) << '\n';
  if (this->TransformOutputToInput != NULL)
    this->TransformOutputToInput->PrintSelf(os,indent);
  os << indent << "Background Scalar: " << Background << '\n';
  os << indent << "Output Spacing" 
     << OutSpacing[0] << ' ' << OutSpacing[1] << ' ' 
     << OutSpacing[2] << '\n';

  os << indent << "Output Origin: " 
     << OutOrigin[0] << ' ' << OutOrigin[1]<< ' ' 
     << OutOrigin[2] << '\n';

  os << indent << "Output Extent: " 
     << OutExtent[0] << ' ' << OutExtent[1] << ' ' << OutExtent[2] << ' '
     << OutExtent[3] << ' ' << OutExtent[4] << ' ' << OutExtent[5] << '\n';
}

