/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkLTSPolynomialIT.cxx,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkLTSPolynomialIT.h"
#include "vtkObjectFactory.h"
#include "vtkMath.h"

#include <algorithm>
#include <numeric>
#include <vector>

using namespace std;

// point1 point2 distance (between points)
struct ppd
{
  float x;
  float y;
  float d;
  void updateDist(float const* f, int degree);
};

inline void ppd::updateDist(float const* f, int degree)
{
  float xx=this->x;
  float res=f[0];
  for(int j=1;j<=degree;++j)
    {
    res += f[j]*xx;
    xx *= this->x;
    }
  this->d=pow(y-res,2);
}

bool operator<(ppd const& a,ppd const& b)
{
  return a.d < b.d;
}

bool operator==(ppd const& a,ppd const& b)
{
  return a.d == b.d;
}

static float addDist(float a,ppd const& c)
{
  return a+c.d;
}

// There should be at least a ref to my paper
// Modified by Liu
//static void polynomialFit(vector<ppd> const& c,float* F,int degree,
//              float ratio=1.0)
static void polynomialFit(std::vector<ppd> const& c,float* F,int degree,
              float ratio=1.0)
{
  long numberOfPoints = long(c.size()*ratio);
  //double vals[2*degree+1];
  //double f[degree+1];
  // Modified by Liu
  int i;

  double* vals = new double[2*degree+1];
  double* f = new double[degree+1];

  if(numberOfPoints==0)
    {
    vtkGenericWarningMacro("number of points used is 0!");
    return;
    }

  std::fill_n(f,degree+1,0);
  std::fill_n(vals,2*degree+1,0);
  vals[0]=numberOfPoints;
  std::vector<ppd>::const_iterator ci=c.begin();

  // vals[j] = sum_{i}{x_i^j}
  // f[j] = sum_{i}{x_i^j * y_i}
  // Modified by Liu
  //for(int i=0 ; i < numberOfPoints ; ++i)
  for( i=0 ; i < numberOfPoints ; ++i)  
  {
    double sv=1;
    double tv=ci->y;
    int j=0;

    f[j++]+=tv;
    while(j<degree+1)
      {
      vals[j]+=(sv*=ci->x);
      f[j++]+=(tv*=ci->x);
      }
      
    while(j<2*degree+1)
      {
      vals[j++]+=(sv*=ci->x);
      }
    ++ci;
    }
   
  double** A = new double*[degree+1];

  // Modified by Liu
//  for(int i = 0 ; i < degree + 1 ; ++i)
  for( i = 0 ; i < degree + 1 ; ++i)
    {
    A[i] = new double[degree+1];
    }

  // A[j][k] = sum_{i}{x_i^{j+k}} = vals[j+k]
// Modified by Liu
//  for(int i = 0 ; i < degree + 1 ; ++i)
  for( i = 0 ; i < degree + 1 ; ++i)
    {
    for(int j = i ; j < degree + 1 ; ++j)
      {
      A[i][j] = A[j][i] = vals[i+j];
      }
    }

  if(!vtkMath::SolveLinearSystem(A,f,degree+1))
    {
    vtkGenericWarningMacro("vtkMath::SolveLinearSystem failed");
    return;
    }
  // Modified by Liu
  //for(int i = 0 ; i < degree + 1 ; ++i)
  for( i = 0 ; i < degree + 1 ; ++i)
    {
    delete[] A[i];
    }
  delete[] A;

  // Modified by Liu
  //for(int i=0;i<=degree;++i)
  for( i=0;i<=degree;++i)
    {
    F[i]=f[i];
    }

    // Modified by Liu

  if (vals != NULL) 
      delete[] vals;
  if (f != NULL)
      delete[] f;
}
//Modified by Liu
//static void polynomialFitNoBias(vector<ppd> const& c,float* F,int degree,
//                float ratio=1.0)

static void polynomialFitNoBias(std::vector<ppd> const& c,float* F,int degree,
 float ratio=1.0)

{
  long numberOfPoints = long(c.size()*ratio);
  
  //Modified by Liu
  //double vals[2*degree];
  // double f[degree];

  long i;
  
  double* vals = NULL;
  double* f = NULL;

  if ( degree > 0)
  {
      vals = new double[2*degree];
      f = new double[degree];
  }


  
  if(numberOfPoints==0)
    {
    vtkGenericWarningMacro("number of points used is 0!");
    return;
    }

  std::fill_n(f,degree,0);
  std::fill_n(vals,2*degree,0);
  std::vector<ppd>::const_iterator ci=c.begin();

  // vals[j] = sum_{i}{x_i^{j+2}}
  // f[j] = sum_{i}{x_i^{j+1} * y_i}
  // Modified by Liu
  //for(long i = 0 ; i < numberOfPoints ; ++i)
  for( i = 0 ; i < numberOfPoints ; ++i)
    {
    double sv=ci->x*ci->x;
    double tv=ci->y*ci->x;
    int j=0;
      
    vals[j]+=sv;
    f[j++]+=tv;
    while(j < degree)
      {
      vals[j] += (sv*=ci->x);
      f[j++] += (tv*=ci->x);
      }
      
    while(j < 2*degree)
      {
      vals[j++]+=(sv*=ci->x);
      }
    ++ci;
    }

  double** A = new double*[degree];
  // Modified by Liu
  // for(int i = 0 ; i < degree ; ++i)
  for( i = 0 ; i < degree ; ++i)
    {
    A[i] = new double[degree];
    }

  // A[j][k] = sum_{i}{x_i^{j+k}}
  // Modified by Liu
  //for(int i = 0 ; i < degree ; ++i)
  for(i = 0 ; i < degree ; ++i)
  {
    for(int j = i ; j < degree ; ++j)
      {
      A[i][j] = A[j][i] = vals[i+j];
      }
    }

  if(!vtkMath::SolveLinearSystem(A,f,degree))
    {
    vtkGenericWarningMacro("vtkMath::SolveLinearSystem failed");
    return;
    }
// Modified by Liu
  //for(int i = 0 ; i < degree ; ++i)
  for ( i = 0 ; i < degree ; ++i)
    {
    delete[] A[i];
    }
  delete[] A;

  // Modiified by Liu
  // for(int i=1;i<=degree;++i)
  for( i=1;i<=degree;++i)
    {
    F[i]=f[i-1];
    }
  F[0]=0;

    //Modified by Liu
  if (vals != NULL)
      delete[] vals;
  if ( f != NULL)
      delete[] f;

}

vtkLTSPolynomialIT* vtkLTSPolynomialIT::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkLTSPolynomialIT");
  if(ret)
    {
    return (vtkLTSPolynomialIT*)ret;
    }
  // If the factory was unable to create the object, then create it here.
    return new vtkLTSPolynomialIT;
}

vtkLTSPolynomialIT::vtkLTSPolynomialIT()
{
  this->Ratio=1;
  this->UseBias=false;
}

vtkLTSPolynomialIT::~vtkLTSPolynomialIT()
{
}

void vtkLTSPolynomialIT::PrintSelf(::ostream& os, vtkIndent indent)
{
  vtkPolynomialIT::PrintSelf(os, indent);
  os << indent << "Ratio: " << this->GetRatio() << "\n";
  os << indent << "UseBias: " << (this->GetUseBias() ? "On" : "Off") << "\n";
}

template <class T1,class T2>
static void vtkLTSPolynomialITExecute(vtkLTSPolynomialIT *self,
                      vtkImageData *in1Data, T1 *in1Ptr,
                      vtkImageData *in2Data, T2 *in2Ptr,
                      vtkImageData *in3Data, unsigned char *in3Ptr,
                      float* f)
{
  float sratio = self->GetRatio();
  int degree = self->GetDegree();
  float sigcor=5.67444069799612371 - 7.66557402756860817*sratio +
    3.05817457731290609*sratio*sratio;

  int* outExt = in1Data->GetExtent();
  int maxX = outExt[1] - outExt[0]; 
  int maxY = outExt[3] - outExt[2]; 
  int maxZ = outExt[5] - outExt[4];

  // Get increments to march through data 
  int in1IncX, in1IncY, in1IncZ;
  int in2IncX, in2IncY, in2IncZ;
  int in3IncX, in3IncY, in3IncZ;
  in1Data->GetContinuousIncrements(outExt, in1IncX, in1IncY, in1IncZ);
  in2Data->GetContinuousIncrements(outExt, in2IncX, in2IncY, in2IncZ);
  if(in3Data)
    {
    in3Data->GetContinuousIncrements(outExt, in3IncX, in3IncY, in3IncZ);
    }

  int incC=in1Data->GetNumberOfScalarComponents();
  
 //Modified by Liu
  int idxX,idxY,idxZ;

  // Find max value in extent
  float max1=0;
  float max2=0;
  T1* ptr1=in1Ptr;
  T2* ptr2=in2Ptr;
  unsigned char* ptr3=in3Ptr;

  //Modified by Liu

  for (//int 
      idxZ = outExt[4]; idxZ <= outExt[5]; idxZ++)
    {
    for (//
        int idxY = outExt[2]; idxY <= outExt[3]; idxY++)
      {
      for (//int 
          idxX = outExt[0]; idxX <= outExt[1] ; idxX++)
    {
    if(!ptr3 || *ptr3==255)
      {
      if( max1 < *ptr1 )
        {
        max1=*ptr1;
        }
      if( max2 < *ptr2 )
        {
        max2=*ptr2;
        }
      }
    
    ptr1+=incC;
    ptr2+=incC;
    if(ptr3)
      {
      ++ptr3;
      }
    }
      ptr1 += in1IncY;
      ptr2 += in2IncY;
      if(ptr3)
    {
    ptr3 += in3IncY;
    }
      }
    ptr1 += in1IncZ;
    ptr2 += in2IncZ;
    if(ptr3)
      {
      ptr3 += in3IncZ;
      }
    }

  // scale coefficients for normalized data
  float max1c=max1;

  //Modified by Liu
  int ii;
  for(ii=0 ; ii <= degree ; ++ii)
    {
    f[ii]/=max1c;
    max1c/=max2;
    }

  //for(int i=0 ; i <= degree ; ++i)
  //  {
  //  f[i]/=max1c;
  //  max1c/=max2;
  //  }


  // create point list
  vector<ppd> c((maxX+1)*(maxY+1)*(maxZ+1));
  vector<ppd>::iterator i=c.begin();
  ptr1=in1Ptr;
  ptr2=in2Ptr;
  ptr3=in3Ptr;
  for (//int 
      idxZ = outExt[4]; idxZ <= outExt[5]; idxZ++)
    {
    for (//int 
        idxY = outExt[2]; idxY <= outExt[3]; idxY++)
      {
      for (//int 
          idxX = outExt[0]; idxX <= outExt[1] ; idxX++)
    {
    if(!ptr3 || *ptr3==255)
      {
      i->x = *ptr2/max2;
      i->y = *ptr1/max1;
      i->updateDist(f,degree);

      ++i;
      }
    
    ptr1+=incC;
    ptr2+=incC;
    if(ptr3)
      {
      ++ptr3;
      }
    }
      ptr1 += in1IncY;
      ptr2 += in2IncY;
      if(ptr3)
    {
    ptr3+= in3IncY;
    }
      }
    ptr1 += in1IncZ;
    ptr2 += in2IncZ;
    if(ptr3)
      {
      ptr3+=in3IncZ;
      }
    }

  // if ratio is 1, there is no need to shuffle or iterate since
  // we are using all the points
  if(sratio != 1)
    {
    random_shuffle(c.begin(),c.end());
    }

  if(self->GetUseBias())
    {
    polynomialFit(c,f,degree,sratio);
    }
  else
    {
    polynomialFitNoBias(c,f,degree,sratio);
    }
  
  // compute TLS/RLS
  if(sratio != 1)
    {
    // number of (best) points used to fit polynomial
    long numberOfPoints = long(c.size()*sratio);
    
    // errors in polynomial fit when iterating
    float oldError = accumulate(c.begin(),c.begin()+numberOfPoints,0.0,
                addDist)/numberOfPoints;
    
    for(vector<ppd>::iterator i=c.begin();i!=c.end();++i)
      {
      i->updateDist(f,degree);
      }
    float newError=accumulate(c.begin(),c.begin()+numberOfPoints,0.0,
                  addDist)/numberOfPoints;
    
    int count=0;
    // compute LTS
    while(0>oldError-newError || oldError-newError>1e-3)
      {
      // after 100 iterations, just take whatever we have.  we're
      // probably already screwed anyway. let's hope we never get
      // there.
      if(count > 100)
    {
    break;
    }
      oldError=newError;
      nth_element(c.begin(),c.begin()+numberOfPoints,c.end());
      
      // fit polynomial
      if(self->GetUseBias())
    {
    polynomialFit(c,f,degree,sratio);
    }
      else
    {
    polynomialFitNoBias(c,f,degree,sratio);
    }
      
      // update according to f
      for(vector<ppd>::iterator i=c.begin();i!=c.end();++i)
    {
    i->updateDist(f,degree);
    }
      newError=accumulate(c.begin(),c.begin()+numberOfPoints,0.0,
              addDist)/numberOfPoints;
      
      count++;
      }
    
    // compute variance
    float sigma=sigcor*sqrt(newError);
    
    // find every element <= 3*sigma
    sort(c.begin(),c.end());
    ppd myppd;
    myppd.d = 3*sigma;
    vector<ppd>::iterator last1=upper_bound(c.begin(),c.end(),myppd);
    
    // recompute polynomial using values obtained previously
    float ratio = (last1-c.begin())/float(c.size());
    
    // compute RLS
    if(!self->GetUseBias())
      {
      polynomialFitNoBias(c,f,degree,ratio);
      }
    else
      {
      polynomialFit(c,f,degree,ratio);
      }
    }

  // rescale coefs for original intensities
  //Modified by Liu
  for( ii = 0 ; ii <= degree ; ++ii)
    {
    f[ii] *= max1;
    max1 /= max2;
    }

//  for(int i = 0 ; i <= degree ; ++i)
//    {
//    f[i] *= max1;
//    max1 /= max2;
//    }

}

template <class T1,class T2>
static void vtkLTSPolynomialITExecute2(vtkLTSPolynomialIT *self,
                      vtkImageData *in1Data, T1 *in1Ptr,
                      vtkImageData *in2Data, T2 *in2Ptr,
                      vtkImageData *in3Data, unsigned char *in3Ptr,
                      float** Alphas)
{
  for(int c=0; c < self->GetNumberOfFunctions(); ++c)
    {
    vtkLTSPolynomialITExecute(self,
                  in1Data,in1Ptr++,
                  in2Data,in2Ptr++,
                  in3Data,in3Ptr,
                  Alphas[c]);
    }
}

template <class T>
static void vtkLTSPolynomialITExecute1(vtkLTSPolynomialIT *self,
                                       vtkImageData *in1Data, T *in1Ptr,
                                       vtkImageData *in2Data, void *in2Ptr,
                                       vtkImageData *in3Data, unsigned char *in3Ptr,
                                       float** Alphas)
{
  switch (in2Data->GetScalarType())
    {
    vtkTemplateMacro8(vtkLTSPolynomialITExecute2,
              self,in1Data, in1Ptr, 
              in2Data, (VTK_TT *)(in2Ptr),
              in3Data, in3Ptr,
              Alphas);
    default:
      vtkGenericWarningMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}

void vtkLTSPolynomialIT::InternalUpdate()
{
  vtkDebugMacro("Main code for intensity matching");
   
  void *inPtr1;
  void *inPtr2;
  unsigned char *inPtr3=0;

  if (this->Target == NULL)
    {
    vtkErrorMacro(<< "Target must be specified.");
    return;
    }
   
  if (Source == NULL)
    {
    vtkErrorMacro(<< "Source must be specified.");
    return;
    }

  inPtr1 = this->Target->GetScalarPointer();
  inPtr2 = this->Source->GetScalarPointer();
  if(this->Mask)
    {
    inPtr3 = (unsigned char*)Mask->GetScalarPointer();
    }

  // expect all inputs of the same time.
  if (this->Mask && this->Mask->GetScalarType() != VTK_UNSIGNED_CHAR)
    {
    vtkErrorMacro(<< "Execute: Mask ScalarType, "
          <<  this->Target->GetScalarType()
          << ", must be VTK_UNSIGNED_CHAR ");
    return;
    }
  
  if (this->Target->GetNumberOfScalarComponents() !=
      this->Source->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: Target NumberOfScalarComponents, "
          << this->Target->GetNumberOfScalarComponents()
          << ", must be equal to Source NumberOfScalarComponents, "
          << this->Source->GetNumberOfScalarComponents());
    return;
    }
  
  if (this->Mask && this->Mask->GetNumberOfScalarComponents() != 1)
    {
    vtkErrorMacro(<< "Execute: Mask NumberOfScalarComponents, "
          << this->Target->GetNumberOfScalarComponents()
          << ", must be 1");
    return;
    }
    
  if(this->GetNumberOfFunctions()>
     this->Target->GetNumberOfScalarComponents())
    {
    vtkErrorMacro(<< "Execute: Target NumberOfScalarComponents, "
          << this->Target->GetNumberOfScalarComponents()
          << ", must smaller or equal to number of functions, "
          << this->GetNumberOfFunctions());
    return;
    }

  switch (this->Target->GetScalarType())
    {
    vtkTemplateMacro8(vtkLTSPolynomialITExecute1,
              this,this->Target, (VTK_TT *)(inPtr1), 
              this->Source, inPtr2,
              this->Mask, inPtr3,
              this->Alphas);
    default:
      vtkErrorMacro(<< "Execute: Unknown ScalarType");
      return;
    }
}
