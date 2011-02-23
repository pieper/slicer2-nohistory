/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkVectorToOuterProductDualBasis.cxx,v $
  Date:      $Date: 2006/01/13 15:51:54 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
#include "vtkVectorToOuterProductDualBasis.h"
#include "vtkObjectFactory.h"
#include "vtkMathUtils.h"
#include "vtkMath.h"

#include "vnl/vnl_matrix.h"
#include "vnl/algo/vnl_matrix_inverse.h"

#define VTK_VECTOR_LENGTH 3




vtkStandardNewMacro(vtkVectorToOuterProductDualBasis);

//-------------------------------------------------------------------------
vtkVectorToOuterProductDualBasis::vtkVectorToOuterProductDualBasis()
{
  this->NumberOfInputVectors = 6;
  // vectors
  this->V = NULL;
  // outer product of vectors
  this->VV = NULL;
  // VV transposed
  this->VVT = NULL;
  // VV transposed times VV
  this->VVTVV = NULL;
  // VV transposed times VV inverse
  this->VVTVVI = NULL;
  // pseudoinverse
  this->PInv = NULL;

  this->AllocateInternals();

  // defaults are from DT-MRI
  this->SetInputVector(0,1,1,0);
  this->SetInputVector(1,0,1,1);
  this->SetInputVector(2,1,0,1);
  this->SetInputVector(3,0,1,-1);
  this->SetInputVector(4,1,-1,0);
  this->SetInputVector(5,-1,0,1);
}

//----------------------------------------------------------------------------
vtkVectorToOuterProductDualBasis::~vtkVectorToOuterProductDualBasis()
{
  this->DeallocateInternals();
}

//----------------------------------------------------------------------------
void vtkVectorToOuterProductDualBasis::PrintSelf(ostream& os, vtkIndent indent)
{
  int i,j,N;

  vtkObject::PrintSelf(os,indent);

  N =   this->NumberOfInputVectors;

  os << indent << "NumberOfInputVectors: "<< this->NumberOfInputVectors << "\n";

  // vectors
  for (i=0; i< this->NumberOfInputVectors; i++)
    {
      os << indent << "Input Vector " << i << ": ";
      for (j=0; j<VTK_VECTOR_LENGTH ; j++)
        {
          os << this->V[i][j] << " ";
        }
      os << "\n";
    }
  // outer product of vectors
  os << indent << "VV (outer product) " << ": \n";
  if (this->VV)
    vtkMathUtils::PrintMatrix(this->VV,9,N,os,indent);
  // VV transposed
  os << indent << "VVT (transpose) " << ": \n";
  if (this->VVT)
    vtkMathUtils::PrintMatrix(this->VVT,N,9,os,indent);
  // VV transposed times VV
  os << indent << "VVTVV (product)" << ": \n";
  if (this->VVTVV)
    vtkMathUtils::PrintMatrix(this->VVTVV,N,N,os,indent);
  // VV transposed times VV inverse
  os << indent << "VVTVVI (inverse)" << ": \n";
  if (this->VVTVVI)
    vtkMathUtils::PrintMatrix(this->VVTVVI,N,N,os,indent);
  // pseudoinverse of VV
  os << indent << "PseudoInverse" << ": \n";
  if (this->PInv)
    vtkMathUtils::PrintMatrix(this->PInv,N,9,os,indent);
}

//----------------------------------------------------------------------------
void vtkVectorToOuterProductDualBasis::SetNumberOfInputVectors(int num) 
{
  if (this->NumberOfInputVectors != num)
    {
      // first kill old objects
      this->DeallocateInternals();

       vtkDebugMacro ("setting num input vecotrs to " << num);
      this->NumberOfInputVectors = num;
      this->AllocateInternals();
      this->Modified();
    }
}

// Allocate all the 2D arrays we use internally.
// Since vtkMath expects double**, we use that
// in this class.
void vtkVectorToOuterProductDualBasis::AllocateInternals()
{
  int i;

  if (this->NumberOfInputVectors > 0)
    {
      // allocate space for the vectors (Nx3)
      this->V = new vtkFloatingPointType*[this->NumberOfInputVectors];
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          this->V[i] = new vtkFloatingPointType[VTK_VECTOR_LENGTH];
        }


      // allocate space for the outer product matrices (9xN)
      // each column is a 9-vector from outer product
      this->VV = new double*[9];
      for (i=0; i< 9; i++)
        {
          this->VV[i] = new double[this->NumberOfInputVectors];
        }

      // allocate space for the transpose of VV (Nx9)
      this->VVT = new double*[this->NumberOfInputVectors];
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          this->VVT[i] = new double[9];
        }

      // allocate space for the transpose of VV times VV (NxN)
      this->VVTVV = new double*[this->NumberOfInputVectors];
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          this->VVTVV[i] = new double[this->NumberOfInputVectors];
        }

      // allocate space for the transpose of VV times VV inverse (NxN) 
      this->VVTVVI = new double*[this->NumberOfInputVectors];
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          this->VVTVVI[i] = new double[this->NumberOfInputVectors];
        }

      // allocate space for the pseudoinverse (Nx9)
      this->PInv = new double*[this->NumberOfInputVectors];
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          this->PInv[i] = new double[9];
        }
    }

}

void vtkVectorToOuterProductDualBasis::DeallocateInternals()
{
  int i;

  if (this->V != NULL) 
    {
      // delete interior vectors first
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->V[i];
        }
      // now delete the pointers
      delete []this->V;
      this->V = NULL;
    }
  if (this->VV != NULL) 
    {
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->VV[i];
        }
      delete []this->VV;
      this->VV = NULL;
    }

  if (this->VVT != NULL) 
    {
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->VVT[i];
        }
      delete []this->VVT;
      this->VVT = NULL;
    }

  if (this->VVTVV != NULL) 
    {
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->VVTVV[i];
        }
      delete []this->VVTVV;
      this->VVTVV = NULL;
    }
  if (this->VVTVVI != NULL) 
    {
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->VVTVVI[i];
        }
      delete []this->VVTVVI;
      this->VVTVVI = NULL;
    }
  if (this->PInv != NULL) 
    {
      for (i=0; i< this->NumberOfInputVectors; i++)
        {
          delete []this->PInv[i];
        }
      delete []this->PInv;
      this->PInv = NULL;
    }
}


void vtkVectorToOuterProductDualBasis::SetInputVector(int num, 
                              vtkFloatingPointType vector[VTK_VECTOR_LENGTH]) 
{
  vtkFloatingPointType length = 0;

  if (num > this->NumberOfInputVectors-1)
    {
      vtkErrorMacro("We don't have that many input vectors");
      return;
    }
  if (this->V == NULL) 
    {
      this->AllocateInternals();
    }
  if (this->NumberOfInputVectors < 1) 
    {
      vtkErrorMacro("Need more than 0 vectors, use SetNumberOfInputVectors");
      return;    
    }

  // normalize vector
  int i;
  for (i=0; i < VTK_VECTOR_LENGTH; i++)
    {
      length += vector[i]*vector[i];  
    }
  length = sqrt(length);

  for (i=0; i < VTK_VECTOR_LENGTH; i++)
    {
      this->V[num][i] = vector[i]/length;  
    }

}

void vtkVectorToOuterProductDualBasis::SetInputVector(int num, vtkFloatingPointType v0, 
                              vtkFloatingPointType v1, vtkFloatingPointType v2)
{

  vtkFloatingPointType *tmp = new vtkFloatingPointType[VTK_VECTOR_LENGTH];
  tmp[0] = v0;
  tmp[1] = v1;
  tmp[2] = v2;

  this->SetInputVector(num,tmp);

  delete [] tmp;
}

void vtkVectorToOuterProductDualBasis::CalculateDualBasis()
{
  unsigned int i,j,k,count,N;
  // temp storage
  vtkFloatingPointType A[VTK_VECTOR_LENGTH][VTK_VECTOR_LENGTH];
  
  
  N =   this->NumberOfInputVectors;


  vnl_matrix<double> G;
  vnl_matrix<double> Ginv;
  
  G.set_size(9,N);
  Ginv.set_size(N,9);

  vtkDebugMacro("Calculating dual basis");

  // first fill the VV (outer product) array
  // loop over all input vectors
  for (i = 0; i < N; i++)
    {
      // do outer product of each of the input vectors
      vtkMathUtils::Outer3(this->V[i],this->V[i],A);

      // copy elements of A into our class arrays
      count = 0;
      for (j = 0; j < VTK_VECTOR_LENGTH; j++)
    {
      for (k = 0; k < VTK_VECTOR_LENGTH; k++)
        {
          // place in cols of VV
          this->VV[count][i] = A[j][k];
          
      G.put(count,i,A[j][k]);
          
      // also place in rows of VVT (transposed) array
          this->VVT[i][count] = A[j][k];          
          //cout << "A[j][k]" << j << " " << k << " " << A[j][k] << endl;
          count++;
        }
    }
    }

 /* Compute pseudoinverse using standard method. 
 // multiply VVT by VV to make VVTVV, symmetric invertible matrix
  vtkMathUtils::MatrixMultiply(this->VVT,this->VV,this->VVTVV,N,9,9,N);
  vtkDebugMacro("inverting VVT VV matrix");

  result = vtkMath::InvertMatrix (this->VVTVV, this->VVTVVI, N);

  vtkDebugMacro("result of inverting matrix was: " << result);
  if (result == 0)
    {
      vtkErrorMacro("VVTVV Matrix could not be inverted!");
      vtkMathUtils::PrintMatrix(this->VVTVV,N,N);
    }

//    vtkMathUtils::PrintMatrix(this->VVTVVI,N,N);

  vtkDebugMacro("multiplying to make pinv");

  // make pseudoinverse: (HT H)^-1 HT
   vtkMathUtils::MatrixMultiply(this->VVTVVI,this->VVT,this->PInv,N,N,N,9);
*/


  //New Approach using SVD
  /*
  result = this->PseudoInverse(this->VV,this->PInv,9,N);

  if (result)
    {
      vtkErrorMacro("VV PseudoInverse could not be computed!");
      vtkMathUtils::PrintMatrix(this->PInv,N,9);
    }
  */
  //cout<<"My pseudoinverse"<<endl;
  //vtkMathUtils::PrintMatrix(this->PInv,N,9);
 
 
  //VNL approach avoiding reimplementation of Numerical Recipes

   vnl_matrix_inverse<double>  Pinv(G);
   Ginv = Pinv.pinverse(6);

   for (i = 0; i < N; i++)
    {
     for (j = 0; j< 9; j++)
       {
       this->PInv[i][j] = Ginv.get(i,j);
   
       }
    }
   if (Pinv.valid()==0) {
     vtkErrorMacro("VV PseudoInverse could not be computed!");
     vtkMathUtils::PrintMatrix(this->PInv,N,9);
   }
   
   


}

void vtkVectorToOuterProductDualBasis::PrintPseudoInverse(ostream &os)
{
  int N;
  // create this just to use the PrintMatrix function
  vtkIndent indent;

  N =   this->NumberOfInputVectors;

  // pseudoinverse of VV
  os << "PseudoInverse" << ": \n";
  if (this->PInv)
    vtkMathUtils::PrintMatrix(this->PInv,N,9,os,indent);
  else
    cout<<"Nothing to Print."<<endl;

}

void vtkVectorToOuterProductDualBasis::PrintPseudoInverse()
{
  this->PrintPseudoInverse(cout);
}


#define VTK_SQR(a) (a == 0.0 ? 0.0 : a*a)
#define VTK_SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))
#define VTK_MAX(a,b) ((a) > (b) ?\
        (a) : (b))
#define VTK_MIN(a,b) ((a) < (b) ?\
        (a) : (b))

template<class T>
static inline T vtkpythag(const T a, const T b)
{
  T absa, absb;

  absa = fabs(a);
  absb = fabs(b);
  if (absa > absb) return absa*sqrt(1.0 + VTK_SQR(absb/absa));
  else return (absb == 0.0 ? 0.0 : absb*sqrt(1.0 + VTK_SQR(absa/absb)));

}

//SVD decomposition a = u w v^T
template<class T>
static inline int vtkSVD(T **a, int m, int n, T *w, T **v)
{
  int flag,i,its,j,jj,k,l,nm;
  T anorm,c,f,g,h,s,scale,x,y,z,*rv1;

  rv1 = new T[n];
  g=scale=anorm=0.0;
  cout<<"For 1"<<endl;
  for (i=0;i<n;i++) {
    l=i+2;
    rv1[i]=scale*g;
    g=s=scale=0.0;
    if (i < m) {
      for (k=i;k<m;k++) scale += fabs(a[k][i]);
      if (scale != 0.0) {
    for (k=i;k<m;k++) {
      a[k][i] /= scale;
      s += a[k][i]*a[k][i];
    }
    f=a[i][i];
    g = -VTK_SIGN(sqrt(s),f);
    h=f*g-s;
    a[i][i]=f-g;
    for (j=l-1;j<n;j++) {
      for (s=0.0,k=i;k<m;k++) s += a[k][i]*a[k][j];
      f=s/h;
      for (k=i;k<m;k++) a[k][j] += f*a[k][i];
    }
    for (k=i;k<m;k++) a[k][i] *= scale;
      }
    }
    w[i]=scale *g;
    g=s=scale=0.0;
    if (i+1 <= m && i != n) {
      for (k=l-1;k<n;k++) scale += fabs(a[i][k]);
      if (scale != 0.0) {
    for (k=l-1;k<n;k++) {
      a[i][k] /= scale;
      s += a[i][k]*a[i][k];
    }
    f=a[i][l-1];
    g = -VTK_SIGN(sqrt(s),f);
    h=f*g-s;
    a[i][l-1]=f-g;
    for (k=l-1;k<n;k++) rv1[k]=a[i][k]/h;
    for (j=l-1;j<m;j++) {
      for (s=0.0,k=l-1;k<n;k++) s += a[j][k]*a[i][k];
      for (k=l-1;k<n;k++) a[j][k] += s*rv1[k];
    }
    for (k=l-1;k<n;k++) a[i][k] *= scale;
      }
    }
    anorm=VTK_MAX(anorm,(fabs(w[i])+fabs(rv1[i])));
  }

  for (i=n-1;i>=0;i--) {
    if (i < n-1) {
      if (g !=0.0) {
    for (j=l;j<n;j++)
      v[j][i]=(a[i][j]/a[i][l])/g;
    for (j=l;j<n;j++) {
      for (s=0.0,k=l;k<n;k++) s += a[i][k]*v[k][j];
      for (k=l;k<n;k++) v[k][j] += s*v[k][i];
    }
      }
      for (j=l;j<n;j++) v[i][j]=v[j][i]=0.0;
    }
    v[i][i]=1.0;
    g=rv1[i];
    l=i;
  }

  for (i=VTK_MIN(m,n)-1;i>=0;i--) {
    l=i+1;
    g=w[i];
    for (j=l;j<n;j++) a[i][j]=0.0;
    if (g != 0.0) {
      g=1.0/g;
      for (j=l;j<n;j++) {
    for (s=0.0,k=l;k<m;k++) s += a[k][i]*a[k][j];
    f=(s/a[i][i])*g;
    for (k=i;k<m;k++) a[k][j] += f*a[k][i];
      }
      for (j=i;j<m;j++) a[j][i] *= g;
    } else for (j=i;j<m;j++) a[j][i]=0.0;
    ++a[i][i];
  }
 
  for (k=n-1;k>=0;k--) {
    for (its=0;its<30;its++) {
      flag=1;
      for (l=k;l>=0;l--) {
    nm=l-1;
    if ((fabs(rv1[l])+anorm) == anorm) {
      flag=0;
      break;
    }
    if ((fabs(w[nm])+anorm) == anorm) break;
      }
      if (flag) {
    c=0.0;
    s=1.0;
    for (i=l-1;i<k+1;i++) {
      f=s*rv1[i];
      rv1[i]=c*rv1[i];
      if ((fabs(f)+anorm) == anorm) break;
      g=w[i];
      h=vtkpythag(f,g);
      w[i]=h;
      h=1.0/h;
      c=g*h;
      s = -f*h;
      for (j=0;j<m;j++) {
        y=a[j][nm];
        z=a[j][i];
        a[j][nm]=y*c+z*s;
        a[j][i]=z*c-y*s;
      }
    }
      }
      z=w[k];
      if (l == k) {
    if (z < 0.0) {
      w[k] = -z;
      for (j=0;j<n;j++) v[j][k] = -v[j][k];
    }
    break;
      }
      if (its == 29) {
    cerr<<"SVD: no convergence in 30 svdcmp iterations"<<endl;
    return 1;
      }
      x=w[l];
      nm=k-1;
      y=w[nm];
      g=rv1[nm];
      h=rv1[k];
      f=((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
      g=vtkpythag(f,(T) 1.0);
      f=((x-z)*(x+z)+h*((y/(f+VTK_SIGN(g,f)))-h))/x;
      c=s=1.0;
      for (j=l;j<=nm;j++) {
    i=j+1;
    g=rv1[i];
    y=w[i];
    h=s*g;
    g=c*g;
    z=vtkpythag(f,h);
    rv1[j]=z;
    c=f/z;
    s=h/z;
    f=x*c+g*s;
    g = g*c-x*s;
    h=y*s;
    y *= c;
    for (jj=0;jj<n;jj++) {
      x=v[jj][j];
      z=v[jj][i];
      v[jj][j]=x*c+z*s;
      v[jj][i]=z*c-x*s;
    }
    z=vtkpythag(f,h);
    w[j]=z;
    if (z) {
      z=1.0/z;
      c=f*z;
      s=h*z;
    }
    f=c*g+s*y;
    x=c*y-s*g;
    for (jj=0;jj<m;jj++) {
      y=a[jj][j];
      z=a[jj][i];
      a[jj][j]=y*c+z*s;
      a[jj][i]=z*c-y*s;
    }
      }
      rv1[l]=0.0;
      rv1[k]=f;
      w[k]=x;
    }
  }

  delete rv1;
  return 0;
}

#undef VTK_SIGN
#undef VTK_MAX
#undef VTK_MIN
#undef VTK_SQR


int vtkVectorToOuterProductDualBasis::SVD(float **a, int m, int n, float *w, float **v)
{
  return vtkSVD(a,m,n,w,v);
}

int vtkVectorToOuterProductDualBasis::SVD(double **a, int m, int n, double *w, double **v)
{
  return vtkSVD(a,m,n,w,v);
}

#define VTK_EPS 1.0e-15

int vtkVectorToOuterProductDualBasis::PseudoInverse(double **A, double **AI, int m, int n) 
{
  
  double **U, *W, **V;
  double maxw;
  int i, j, k;
  int maxmn;
  double **AItmp;

  //cout<<"In PseudoInverse: m="<<m<<" n="<<n<<endl;

  if (n>m)
   {
   for(i=0;i<m;i++)
     for(j=0;j<n;j++)
       AI[j][i]=A[i][j];

   AItmp = new double*[m];
   for (i=0;i<m;i++)
    AItmp[i] = new double[n];
   
   vtkVectorToOuterProductDualBasis::PseudoInverse(AI,AItmp,n,m);
   for(i=0;i<m;i++)
     for(j=0;j<n;j++)
       AI[j][i]=AItmp[i][j];
       
   for (i=0;i<m;i++)
    delete []AItmp[i];
   delete [] AItmp;
   
   return 0;
   }


  U = new double*[m];
  W = new double[n];
  V = new double*[n];

  for (i=0;i<m;i++)
    U[i] = new double[n];
  for (i=0;i<n;i++)
    V[i] = new double[n];
  
  for (i=0;i<m;i++)
    for (j=0;j<n;j++)
      U[i][j]=A[i][j];


  if (vtkVectorToOuterProductDualBasis::SVD(U,m,n, W, V)) 
   {
     cerr<<"Trouble in SVD computation"<<endl;
     return 1;
   }
  maxw=0.0;
  for (i=0;i<n;i++)
    if(W[i]>maxw)
       maxw = W[i];
  maxmn = 0;
  if(m>n)
    maxmn = m;
  else
   maxmn =n;

  double tol = maxmn * VTK_EPS*maxw;
  int r = 0;

  for (r=0;r<n;r++){
    cout<<"OUt W[r]= "<<W[r]<<endl;
    if (W[r]<tol){
    cout<<"In W[r]= "<<W[r]<<endl;
    break;
     }
   }   
  
  cout<<"Number of nonzero eigenvalues in SVD: "<<r<<endl;
  
  if (r==0)
    {
    for (i=0;i<n;i++)
      for (j=0;j<m;j++)
        AI[i][j]=0.0;
    }
  else
    {
   for (i=0;i<n;i++)
      {
      for (j=0;j<m;j++)
        {
        AI[i][j]=0.0;
        for (k=0;k<r;k++)
           {
          //in V: row fixed at i, k goes through columns */
      //in U^T: row fixed at j, k goes through columns ==>
           
           AI[i][j] += V[i][k]*(1/W[k])*U[j][k];
           }
        }
      }
   }
   
  delete []W;
  for (i=0;i<m;i++)
    delete []U[i];
  delete []U;
  for (i=0;i<n;i++)
    delete []V[i];
  delete []V;

  return 0;
}

#undef VTK_EPS
