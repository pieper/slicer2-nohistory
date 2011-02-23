/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkStochasticTracking.cxx,v $
  Date:      $Date: 2006/07/24 14:02:49 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkStochasticTracking.h"
#include "vtkObjectFactory.h"
#include "vtkFloatArray.h"
#include "vtkPolyData.h"
#include "vtkPoints.h"
#include "vtkCellArray.h"
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkIdList.h"
#include "vtkMath.h"
#include "vtkMathUtils.h"
#include "vtkMultiThreader.h"

#include "vtkTimerLog.h"
#include "vnl/vnl_matrix.h"
#include "vnl/algo/vnl_matrix_inverse.h"
#include "vnl/algo/vnl_symmetric_eigensystem.h"

#define PI 3.141592653589

#define VTKEPS 10e-10

class vtkDiffusionModelParameters {
  public:
  // Diffusion input 
  double logS0;
  double *logdwi;
  // Storing also dwi to avoid
  // log computations.
  double *dwi;

  // Tensor model
  double D[3][3];
  // Weights use in the weighted LS fitting
  double *squareWeights;
   
  double v[3];  //eigenvector
  double w[3];  //eigenvalues
  // Contrained model params
  double alpha;
  double beta;
  double sigma2;
 
};


//----------------------------------------------------------------------------
vtkStochasticTracking* vtkStochasticTracking::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkStochasticTracking");
  if(ret)
    {
      return (vtkStochasticTracking*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkStochasticTracking;
}


//----------------------------------------------------------------------------
vtkStochasticTracking::vtkStochasticTracking()
{
  // may be set by user
  this->Transform = NULL;

  this->NumberOfRequiredInputs = 7;
  this->NumberOfGradients = 6;
  this->G = NULL;
  //this->AllocateInternals();
  
 
  this->B = vtkDoubleArray::New();
  this->B->SetNumberOfTuples(this->NumberOfGradients);

  // Step length in scale ijk (mm)
  this->StepLength = 1;
  
  this->StoppingThreshold = 0.2;
  
  // Maximum length of a single path (in mm)
  this->MaxPathLength = 200;

  // Number of paths to track
  this->NumberOfPaths = 2000;
 
  this->Gamma = 1;

  this->WeightedFitting = 0;

  this->Paths = vtkCollection::New();
  
  //Matrices to solve tensor model
  this->A = NULL;
  this->AT = NULL;
  this->PinvA = NULL;

  // Sample sphere directions
  this->SphereDirections= NULL;
  this->FlatSD = NULL;
  // Dual basis.
  this->DualBasis = vtkVectorToOuterProductDualBasis::New();
  this->DualBasis->SetNumberOfInputVectors(this->NumberOfGradients);

  // defaults are from DT-MRI 
  // (from Processing and Visualization for 
  // Diffusion Tensor MRI, C-F Westin, pg 8)
  this->SetDiffusionGradient(0,1,1,0);
  this->SetDiffusionGradient(1,0,1,1);
  this->SetDiffusionGradient(2,1,0,1);
  this->SetDiffusionGradient(3,0,1,-1);
  this->SetDiffusionGradient(4,1,-1,0);
  this->SetDiffusionGradient(5,-1,0,1);

  this->Paths = vtkCollection::New();

  // Internal variable to scale the B values, so we get a
  // much better conditioned matrix so solve the Tensor model
  // LS problem. The diffusion matrix should be scaled back with 
  // this factor to get the real diffusion.
  this->ScaleFactor = 10000;

  this->SDMatchList = NULL;
 

  this->LikelihoodCache = vtkCollection::New();
  this->CacheId = vtkIntArray::New();
  
}
vtkStochasticTracking::~vtkStochasticTracking()
{
  this->DeallocatePaths();
  this->Paths->Delete();
  if (this->SDMatchList != NULL)
    this->SDMatchList->Delete();

  this->LikelihoodCache->Delete();
  this->CacheId->Delete();

}

//----------------------------------------------------------------------------
void vtkStochasticTracking::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageMultipleInputFilter::PrintSelf(os,indent);

  os << indent << "NumberOfGradients: " << this->NumberOfGradients << "\n";

  // print all of the gradients
  for (int i = 0; i < this->NumberOfGradients; i++ ) 
    {
      vtkFloatingPointType *g = this->GetDiffusionGradient(i);
      os << indent << "Gradient " << i << ": (" 
         << g[0] << ", "
         << g[1] << ", "
         << g[2] << ")" << "\n";
      
    }  
}


void vtkStochasticTracking::AllocatePaths()
{

 if (this->Paths == NULL)
  {
  this->Paths = vtkCollection::New();
  }

 // Check for previous paths store in Paths
 // and delete them
 this->DeallocatePaths();
 
 int num = (int) floor(this->MaxPathLength/this->StepLength) + 1;
 
 vtkPolyData *tmp;
 vtkPoints *tmp1;
 vtkDoubleArray *tmp2;
 vtkCellArray *tmp3;


 for (int i =0 ;i< this->NumberOfPaths; i++)
   {
    tmp = vtkPolyData::New();
    tmp1 = vtkPoints::New();
    tmp2 = vtkDoubleArray::New();
    tmp3 = vtkCellArray::New();
    tmp1->SetNumberOfPoints(num);
    tmp1->Reset();
    tmp2->SetNumberOfValues(num);
    tmp2->Reset();
    tmp->SetPoints(tmp1);
    tmp->SetLines(tmp3);
    tmp->GetPointData()->SetScalars(tmp2);
    
    this->GetPaths()->AddItem(tmp);
    }
}

//----------------------------------------------------------------------------
void vtkStochasticTracking::DeallocatePaths()
{

  vtkPolyData *path;
  int num;

  if (this->GetPaths() != NULL)
   {
   num = this->GetPaths()->GetNumberOfItems();
   for (int i=0; i < num; i++)
    {
    path =(vtkPolyData *) this->GetPaths()->GetItemAsObject(i);
    //path->GetPoints()->Delete();
    //path->GetPointData()->GetScalars()->Delete();
    //path->GetLines()->Delete();
    path->Delete();
    this->GetPaths()->RemoveItem(i);

    }
  }

}

//----------------------------------------------------------------------------
void vtkStochasticTracking::EstimateConstrainedModel(vtkStochasticTracking *self, vtkDiffusionModelParameters* diffparams )
{

  diffparams->alpha = (diffparams->w[1] + diffparams->w[2])/2.0;
  diffparams->beta = (diffparams->w[0] - diffparams->alpha);

  double r;  
  
  double *logdwi = diffparams->logdwi;
  double logS0 = diffparams->logS0;
  double * b = (double *)self->GetB()->GetVoidPointer(0);
  
  double inner;
  diffparams->sigma2 = 0.0;
  for (int i = 0; i<self->GetNumberOfGradients(); i++)
   {
    inner = vtkMath::Dot(diffparams->v,self->GetDiffusionGradient(i));
    r = logdwi[i] - (logS0 - b[i]*(diffparams->alpha + diffparams->beta*inner*inner));
    diffparams->sigma2 += (diffparams->squareWeights[i]*r*r);
   }
    // Normalize sigma: variance of the residual of the contraint model
   // The unbias estimator is done normalizing with (numelemts - numparams)
    diffparams->sigma2 /= (self->GetNumberOfGradients()-6);
}

//----------------------------------------------------------------------------
// Implementation of eq 7 of MICCA 05, Friman, Westin, "Uncertainty in White Matter Fiber Tractography"
void vtkStochasticTracking::CalculateLikelihood(vtkStochasticTracking *self, const vtkDiffusionModelParameters* diffparams, int Nsamples, double *flatSD, double *likelihood )
{


  double *logdwi = diffparams->logdwi;
  double norm = 0.5*log(2*PI*diffparams->sigma2 + VTKEPS);
  
  double *b = (double *) self->GetB()->GetVoidPointer(0);
  double inner;
  double logmui;
  double mui2;
  double *sd;
  double *grad;
  double tmp;
  int entry1;
  int entry2;
  int *matchlist = (int *) self->GetSDMatchList()->GetVoidPointer(0);
  int numgrads =self->GetNumberOfGradients();

  for (int j =0; j< self->GetSDMatchList()->GetNumberOfTuples(); j++)
     {

       tmp = 0.0;
       for (int i =0; i< numgrads; i++)
        { 
         grad = self->GetDiffusionGradient(i);
         sd = (flatSD +j*3);
         inner = sd[0] * grad[0] + sd[1] * grad[1] + sd[2] * grad[2];
         logmui = diffparams->logS0 - b[i]*(diffparams->alpha + diffparams->beta*inner*inner);
         mui2 = exp(2*logmui);
         tmp += logmui - norm - mui2/(2*diffparams->sigma2)*(logdwi[i]-logmui)*(logdwi[i]-logmui);
        }

    // Filling the likelihood in corresponding points.
     // Opposite directions will always have the same likelihood.
     // The corresponding list is stored in SDMatchList.
     // This list is precomputed before we start the tracking (see ExecuteData)
      entry1 = (int) matchlist[j*2];
      entry2 = (int) matchlist[j*2+1];
      //cout<<"Access point: "<<j*2<<" "<<j*2+1<<"  Match twins: "<<entry1<<" "<<entry2<<endl;
      likelihood[entry1] = exp(tmp);
      likelihood[entry2] = likelihood[entry1];
      }
}

//----------------------------------------------------------------------------
void vtkStochasticTracking::CalculatePrior(vtkStochasticTracking *self, double vprev[3], double gamma, int NSamples, double *flatSD, double *prior )
{
  double *sd;

  if (vprev == NULL) {
   
    for (int i = 0; i<NSamples;i++)
       prior[i] = 1;
    return;
   }

  for (int i=0; i<NSamples;i++)
    {
     //self->GetSphereDirections()->GetTuple(i,sd);
     sd = (flatSD+i*3);
     prior[i] = sd[0]*vprev[0] + sd[1]*vprev[1] + sd[2]*vprev[2];

      if (prior[i]<0)
        prior[i]=0.0;
     
     if (gamma!=1) 
       prior[i]=pow(prior[i],gamma);

    }

}

//----------------------------------------------------------------------------
void vtkStochasticTracking::CalculatePosterior(int numelem, const double *likelihood, const double *prior, double *posterior )
{

  double norm=0;
  for (int i = 0; i<numelem; i++)
    {
     posterior[i] = likelihood[i]*prior[i];
     norm += posterior[i];
    }
  
    for (int i = 0; i<numelem; i++)
    posterior[i] = posterior[i]/(norm);

}

//----------------------------------------------------------------------------
int vtkStochasticTracking::DrawRandomDirection(vtkStochasticTracking *self, const double *posterior )
{

  //Call random twice to avoid init problems;
  double rand=vtkMath::Random(); 
  rand=vtkMath::Random();  

  double cumsum=0.0;
  int i=0;
  while (cumsum<rand)
    {
     cumsum += posterior[i];
     i++;
    }
 //Decrement 1 the counter
 // We want the point when the posterior reach our random sample.
 // In matlab:  
 // vindex = find(cumsum(Posterior) > rand);
 //  return vindex(1);
 
return i--;
    

}

//-------------------
//Every function calling this method should preallocate PinvA and ATW2. This two matrices are used for the
// weighted LS fitting of the tensor model. If no WLS, these variables are not used.
// The memory needed is: PinvA [7][N] and ATW2[7][N] where N is the number of gradients
void vtkStochasticTracking::EstimateTensorModel(vtkStochasticTracking *self, vtkDiffusionModelParameters *diffparams,double **PinvA, double **ATW2)
{

  // eigensystem variables
  vtkFloatingPointType *m[3], *v[3];
  vtkFloatingPointType m0[3], m1[3], m2[3];
  vtkFloatingPointType v0[3], v1[3], v2[3];
  v[0] = v0; v[1] = v1; v[2] = v2;
  m[0] = m0; m[1] = m1; m[2] = m2;

  // If weighted fitting,
  // 1. Build weights
  // 2. Compute pseudoinverse
  int N = self->GetNumberOfGradients();
  if(self->GetWeightedFitting()==1)
   {
  
   double **AT = self->GetAT();   
   for (int i=0; i<7;i++)
     {  
      for (int j=0; j<N;j++)
        ATW2[i][j] = diffparams->squareWeights[j]*AT[i][j];
       
     }

    double **invATW2A;
    double **ATW2A;
    invATW2A=self->AllocateMatrix(7,7);
    ATW2A=self->AllocateMatrix(7,7);
    vtkMathUtils::MatrixMultiply(ATW2,self->GetA(),ATW2A,7,N,N,7);
    vtkMath::InvertMatrix(ATW2A,invATW2A,7);   
    vtkMathUtils::MatrixMultiply(invATW2A,ATW2,PinvA,7,7,7,N);
    self->DeallocateMatrix(invATW2A,7,7);
    self->DeallocateMatrix(ATW2A,7,7);
    
   } else {

   PinvA = self->GetPinvA();

   }

   // Solve the system
   double tmp[7];

   for (int i=0 ; i<7 ; i++)
     {
      tmp[i]=0.0;
      for (int j=0 ; j< N ; j++){
         tmp[i] += PinvA[i][j] * diffparams->logdwi[j];
      }
    }

  // tmp is the scale version of the diffusion tensor
  m[0][0] = tmp[1];
  m[0][1] = tmp[2];
  m[1][0] = tmp[2];
  m[0][2] = tmp[3];
  m[2][0] = tmp[3];
  m[1][1] = tmp[4];
  m[1][2] = tmp[5];
  m[2][1] = tmp[5];
  m[2][2] = tmp[6];

  
  vnl_vector<double> V;
  vnl_matrix<double> M;
  M.set_size(3,3);
    for(int i=0; i< 3; i++)
      for(int j=0; j< 3; j++)
        M.put(i,j,m[i][j]);


   // WARNING: Calling this methos is not thread safe
   vnl_symmetric_eigensystem<double> Jacobi(M);
  

  double scale = self->GetScaleFactor();
  diffparams->w[0] = Jacobi.D.get(2,2)/scale;
  diffparams->w[1] = Jacobi.D.get(1,1)/scale;
  diffparams->w[2] = Jacobi.D.get(0,0)/scale;

  diffparams->v[0] = Jacobi.V.get(0,2);
  diffparams->v[1] = Jacobi.V.get(1,2);
  diffparams->v[2] = Jacobi.V.get(2,2);


  //Fix potential ill-conditioned tensors due to noise
  diffparams->w[0] = fabs(diffparams->w[0]);
  diffparams->w[1] = fabs(diffparams->w[1]);
  diffparams->w[2] = fabs(diffparams->w[2]);

  //vtkMath::Jacobi(m,diffparams->w,v);
 
  //Assign results: tensor and eigenvalues
  // Get scale factor
  
  //Scale back eigenvalues
  //diffparams->w[0] = diffparams->w[0]/scale;
  //diffparams->w[1] = diffparams->w[1]/scale;
  //diffparams->w[2] = diffparams->w[2]/scale;

  //diffparams->v[0] = v0[0];
  //diffparams->v[1] = v0[1];
  //diffparams->v[2] = v0[2];
  
  //NOTE: Scale back Diffusion tensor.
  //When computing LS matrix (CreateLSMatrix method), we reduce B by a scale factor
  //to get a better numeric accuracy. This means that the diffusion is scale by this
 // factor. We undo this, to give back the real diffusion
 
  diffparams->logS0 =tmp[0];
  diffparams->D[0][0] = tmp[1]/scale;
  diffparams->D[0][1] = tmp[2]/scale;
  diffparams->D[1][0] = diffparams->D[0][1];
  diffparams->D[0][2] = tmp[3]/scale;
  diffparams->D[2][0] = diffparams->D[0][2];
  diffparams->D[1][1] = tmp[4]/scale;
  diffparams->D[1][2] = tmp[5]/scale;
  diffparams->D[2][1] = diffparams->D[1][2];
  diffparams->D[2][2] = tmp[6]/scale;
 
 /*
  cout<<"Tensor:"<<endl;
  for (int i =0 ; i< 3 ; i++) {
    for (int j =0; j<3;j++) {
      cout<<" "<<diffparams->D[i][j];
     }
   cout<<endl;
 }
 */

}


double **vtkStochasticTracking::AllocateMatrix(int rows, int columns)
{
  
   double **M = new double*[rows];
    for (int i=0; i< rows; i++)
       {
          M[i] = new double[columns];
       }
  return M;
}

void vtkStochasticTracking::DeallocateMatrix(double **M,int rows, int columns)
{

  for (int i=0; i< rows; i++)
     {
          delete [] M[i];
     }
  
  delete M;
}

void vtkStochasticTracking::CreateLSMatrix()
{

  int N = this->GetNumberOfGradients();
 
  double b;
  double *g;
  this->A=this->AllocateMatrix(N,7);

  for (int i=0; i< N; i++)
    {
     //We scale B values by a given factor to get a better
    // condition of A matrix, then the pseudoinverse is much
    // more stable.
    // Be aware that the resulting diffusion tensor will be 
    // scale by this factor. We take care later on.
     b = this->B->GetValue(i)/this->ScaleFactor;
     g = this->GetDiffusionGradient(i);
     this->A[i][0]=1;
     this->A[i][1]=-b*g[0]*g[0];
     this->A[i][2]=-2*b *g[0]*g[1];
     this->A[i][3]=-2*b *g[0]*g[2];
     this->A[i][4]=-b *g[1]*g[1];
     this->A[i][5]=-2*b *g[1]*g[2];
     this->A[i][6]=-b*g[2]*g[2];
    }

    // allocate space for the transpose of VV (Nx9)
   this->AT=this->AllocateMatrix(7,N);

   for (int i=0; i< 7; i++)
     {      
     for (int j=0 ; j <N ; j++)
       {
       this->AT[i][j] = this->A[j][i];
       }
     }
   
  cout<<"Creating vnl matrices"<<endl;
   vnl_matrix<double> G;
   vnl_matrix<double> Ginv;
   
  if (this->GetWeightedFitting()==0)
   {
    this->PinvA=this->AllocateMatrix(7,N);    
    double **ATA;
    double **invATA;
    ATA=this->AllocateMatrix(7,7);
    invATA=this->AllocateMatrix(7,7);
    vtkMathUtils::MatrixMultiply(this->AT,this->A,ATA,7,N,N,7);
    vtkMath::InvertMatrix(ATA,invATA,7);   
    vtkMathUtils::MatrixMultiply(invATA,this->AT,this->PinvA,7,7,7,N);
 
    G.set_size(N,7);
    Ginv.set_size(7,N);
    for(int i=0; i< N; i++)
      for(int j=0; j< 7; j++)
        G.put(i,j,A[i][j]);

    vnl_matrix_inverse<double>  Pinv(G);
    cout<<"Computing pinverse"<<endl;
    Ginv = Pinv.pinverse(7);
    cout<<"Getting values"<<endl;
    for (int i = 0; i < 7; i++)
    {
     for (int j = 0; j< N; j++)
       {
       this->PinvA[i][j] = Ginv.get(i,j);
   
       }
    }
    this->DeallocateMatrix(ATA,7,7);
    this->DeallocateMatrix(invATA,7,7);
   }

}


//----------------------------------------------------------------------------
void vtkStochasticTracking::TransformDiffusionGradients()
{
  vtkFloatingPointType gradient[3];

  // if matrix has not been set by user don't use it
  if (this->Transform == NULL) 
    {
      return;
    }

  vtkDebugMacro("Transforming diffusion gradients");
  //this->Transform->Print(cout);


  // transform each gradient by this matrix
  for (int i = 0; i < this->NumberOfGradients; i++ ) 
    {
      vtkFloatingPointType *g = this->GetDiffusionGradient(i);
      this->Transform->TransformPoint(g,gradient);

      // set the gradient to the transformed one 
      // (note this set function normalizes too)
      this->SetDiffusionGradient(i,gradient);
    }
}

//----------------------------------------------------------------------------
// The number of required inputs is one more than the number of
// diffusion gradients applied.  (Since image 0 is an image
// acquired without diffusion gradients).
void vtkStochasticTracking::SetNumberOfGradients(int num) 
{
  if (this->NumberOfGradients != num)
    {
      vtkDebugMacro ("setting num gradients to " << num);
      // internal array for storage of gradient vectors
      this->DualBasis->SetNumberOfInputVectors(num);
      // this class's info
      this->NumberOfGradients = num;
      this->NumberOfRequiredInputs = num;
      this->Modified();
    }
}

//----------------------------------------------------------------------------
//
void vtkStochasticTracking::ExecuteInformation(vtkImageData **inDatas, 
                                             vtkImageData *outData)
{
  // We always want to output vtkFloatingPointType scalars
  outData->SetScalarType(VTK_FLOAT);

}

//----------------------------------------------------------------------------
// Replace superclass Execute with a function that allocates tensors
// as well as scalars.  This gets called before multithreader starts
// (after which we can't allocate, for example in ThreadedExecute).
// Note we return to the regular pipeline at the end of this function.
void vtkStochasticTracking::ExecuteData(vtkDataObject *out)
{
  vtkImageData *output = vtkImageData::SafeDownCast(out);

// Do some error checking
  // Lauren check they have set the first input for no diff

/*
  if (this->NumberOfInputs < this->NumberOfRequiredInputs)
    {
      vtkErrorMacro(<< "Number of inputs (" << this->NumberOfInputs << 
      ") is less than the number of required inputs (" << 
      this->NumberOfRequiredInputs <<
      ") for this filter.");
      return;      
    }
*/
  vtkImageData **inDatas = (vtkImageData **)this->GetInputs();
  vtkImageData *outData = output;

  // Loop through checking all inputs 
  for (int idx = 0; idx < this->NumberOfInputs; ++idx)
    {
      if (inDatas[idx] != NULL)
        {
          // this filter expects all inputs to have the same extent
          // Lauren check the above.

          // this filter expects 1 scalar component input
          if (inDatas[idx]->GetNumberOfScalarComponents() != 1)
            {
              vtkErrorMacro(<< "Execute: input" << idx << " has " << 
              inDatas[idx]->GetNumberOfScalarComponents() << 
              " instead of 1 scalar component");
              return;
            }


          // this filter expects that output is float
          if (outData->GetScalarType() != VTK_FLOAT)
            {
              vtkErrorMacro(<< "Execute: output ScalarType (" << 
              outData->GetScalarType() << 
              "), must be float");
              return;
            }
          
        }
      else {
        vtkErrorMacro(<< "Execute: input" << idx << " is NULL");
      }
    }


   // Check starting seed point is inside bounds 
   int ijk[3];
   double pcoords[3];
   if ( inDatas[0]->ComputeStructuredCoordinates(this->GetSeedPoint(), ijk, pcoords) == 0 )
    {
    vtkErrorMacro(<<"Point: "<<this->GetSeedPoint()<<" is out of bounds. Try a new seed point");
    return;
    }
 


  // set extent so we know how many tensors to allocate
  output->SetExtent(output->GetUpdateExtent());

  // make sure our gradient matrix is up to date
  //This update is not thread safe and it has to be performed outside
  // the threaded part.
  // if the user has transformed the coordinate system
  this->TransformDiffusionGradients();
  //this->GetDualBasis()->CalculateDualBasis();
  

  if (this->SphereDirections == NULL)
   {
    vtkErrorMacro(<<"Sphere Directions are needed. This is essential for the stochastic tracking to know which direction to sample from");
    return;
   }

 
   //Create Match List to see if you have corresponding directions. This is done as a trick to speed up.
   // Opposite diretions share the same likelihood.
   this->CreateSphereDirectionsMatchList();


   cout<<"Match List Size: "<<this->SDMatchList->GetNumberOfTuples()<<endl;


  // Precalculate the LS system.
  // If we are in weightedfitting mode,
  // the LS system has to be calculated per voxel location
  // to account for the weights.
   cout<<"CreateLSMatrix"<<endl;
  this->CreateLSMatrix();

  // Allocate Paths object
  // The threads will take care of filling this
  cout<<"AllocatePath"<<endl;
  this->AllocatePaths();

  // jump back into normal pipeline: call standard superclass method here
  //this->vtkImageMultipleInputFilter::ExecuteData(out);
  // Make sure the Input has been set.
  if ( this->GetInput() == NULL )
    {
    vtkErrorMacro(<< "ExecuteData: Input is not set.");
    return;
    }

  // Too many filters have floating point exceptions to execute
  // with empty input/ no request.
  if (this->UpdateExtentIsEmpty(out))
    {
    return;
    }


  vtkImageData *outdata = this->AllocateOutputData(out);
  this->MultiThread((vtkImageData**)this->GetInputs(), outdata);

}


struct vtkStochasticTrackingThreadStruct
{
  vtkStochasticTracking *Filter;
  vtkImageData   **Inputs;
  vtkImageData   *Output;
};


// this mess is really a simple function. All it does is call
// the ThreadedExecute method after setting the correct
// extent for this thread. Its just a pain to calculate
// the correct extent.
VTK_THREAD_RETURN_TYPE vtkStochasticTrackingThreadedExecute( void *arg )
{
  vtkStochasticTrackingThreadStruct *str;
  int  total;
  int threadId, threadCount;
  
  threadId = ((vtkMultiThreader::ThreadInfo *)(arg))->ThreadID;
  threadCount = ((vtkMultiThreader::ThreadInfo *)(arg))->NumberOfThreads;
  
  str = (vtkStochasticTrackingThreadStruct *)(((vtkMultiThreader::ThreadInfo *)(arg))->UserData);
  


 // execute the actual tracking, assigning the appropriate range of paths
 // to each thread.
 total = str->Filter->GetNumberOfThreads();
 int np = str->Filter->GetNumberOfPaths();

 int npperthread = (int) floor((double) (np / total));
 
 int range[2];
 cout<<" Number of Paths: "<<np<<endl;
 cout<<" Number of Threads per path: "<<npperthread<<endl;

 range[0] = threadId*npperthread;
 range[1] = (threadId+1)*npperthread-1;
 
 // If this is the last thread, do the remaining job
 if (threadId == (np-1))
   range[1] = np-1;

 cout<<"Range: "<<range[0]<<" "<<range[1]<<endl;
    
  if (threadId < total)
    {
    str->Filter->ThreadedExecute(str->Inputs, str->Output, range, threadId);
    }
  // else
  //   {
  //   otherwise don't use this thread. Sometimes the threads dont
  //   break up very well and it is just as efficient to leave a 
  //   few threads idle.
  //   }

  return VTK_THREAD_RETURN_VALUE;
}


// Overload all the threading control methods
void vtkStochasticTracking::MultiThread(vtkImageData **inputs, vtkImageData *output)
{
 vtkStochasticTrackingThreadStruct str;
  
  str.Filter = this;
  str.Inputs = inputs;
  str.Output = output;
  
  this->Threader->SetNumberOfThreads(this->NumberOfThreads);
  
  // setup threading and the invoke threadedExecute
  cout<<"Ready for a thread trip"<<endl;
  this->Threader->SetSingleMethod(vtkStochasticTrackingThreadedExecute, &str);
  this->Threader->SingleMethodExecute();
}

void vtkStochasticTracking::CreateSphereDirectionsMatchList()
{


 int num = this->SphereDirections->GetNumberOfTuples();

 if (this->SDMatchList != NULL)
   this->SDMatchList->Delete();
 
 this->SDMatchList = vtkIntArray::New();
 this->SDMatchList->SetNumberOfComponents(2);
 this->SDMatchList->SetNumberOfTuples(num);
 this->SDMatchList->Reset();
 double v[3], vtrial[3];
 double tmp;
 
 char * flag = new char[num];

 //We are looking for opposite vectors. Let us call them twins.
 // We store twin indexes in each  component of the tuple.
// If we don't find any twin, we store the same index in both components.

 int twini;

 for (int i = 0; i < num ; i++)
   flag[i]=0;

 for (int i = 0; i < num ; i++)
   {

   if (flag[i] == 0)
     {

    this->SphereDirections->GetTuple(i,v);
   twini = i;
   for (int j =i; j < num ; j++)
     {
     this->SphereDirections->GetTuple(j,vtrial);
     tmp = fabs(v[0]+vtrial[0])+fabs(v[1]+vtrial[1])+fabs(v[2]+vtrial[2]);

     if (tmp < VTKEPS)
       {
       twini=j; 
        break;
       }
     }
    
    this->SDMatchList->InsertNextTuple2(i,twini);
    flag[i]=1;
    flag[twini]=1;
    }

  }
this->SDMatchList->Squeeze();

delete flag;

}
 


//----------------------------------------------------------------------------
// This method is passed a input and output regions, and executes the filter
// algorithm to fill the output from the inputs.
// It just executes a switch statement to call the correct function for
// the regions data types.
void vtkStochasticTracking::ThreadedExecute(vtkImageData **inDatas, 
                                              vtkImageData *outData,
                                              int range[2], int id)
{

  vtkDebugMacro("in threaded execute, " << this->GetNumberOfInputs() << " inputs ");
  cout<<"In Thread execute"<<endl;

  double *orig = inDatas[0]->GetOrigin();
  double *sp = inDatas[0]->GetSpacing();
  // Loop through the paths doing the job
  double xyz[3];
  int ijk[3];
  double pcoords[3];

  //Allocate the diffusionmodelparam class. It's the class that keep the local state of
  // the diffusion model for each point that we visit in the tracking.
  vtkDiffusionModelParameters *params = new vtkDiffusionModelParameters;

  int N = this->GetNumberOfGradients();
  // Allocate dwi arrays
  params->logdwi = new double [N];
  params->dwi = new double [N];
  params->squareWeights = new double [N];

  // Variables to solve the tensor model

  double **PinvA;
  double **ATW2;
  if (this->GetWeightedFitting())
    {
      PinvA=this->AllocateMatrix(7,N);
      ATW2=this->AllocateMatrix(7,N);
    }

  // Allocate likelihood, prior, posterio
  int Nsamples = this->GetSphereDirections()->GetNumberOfTuples();
  double *likelihood = new double [Nsamples];
  double *prior = new double [Nsamples];
  double *posterior = new double [Nsamples];

  // Index to SphereDirections array
  int vindex;
  double *vprev = NULL;
  double sd[3];
  double tmpvprev[3];
  
  double step = this->StepLength;
  double arcLength;
  double sign = 1;

  //Cache pointers
  vtkDoubleArray *cacheentry;
  vtkDoubleArray *newentrey;
  
  int index_ijk;
  int numberofcalls;
  double anisotropy;

  double *flatSD = (double *) this->SphereDirections->GetVoidPointer(0);


  // Profiling variables
  double t1=0.0;
  double t2=0.0;
  double t3=0.0;
  double t4=0.0;
  double t5=0.0;
  vtkTimerLog *timer = vtkTimerLog::New();
  vtkTimerLog *totaltimer = vtkTimerLog::New();

 // The cache is a flat array with
    // First element: number of times this cache entry has been requested
    // Second element: anisotropy=beta/(alpha + beta). This value is used a stopping threhold
    // Third element: flat array with the compact version of the likelihood.
    //                the compact version of the likelihood is obtained from SDMatchList.

  //Temp array to keep line info

vtkPolyData *path;
vtkPoints *pathPoints;
vtkCellArray *pathLine;
vtkDoubleArray *pathProb;
vtkIdList *linearray = vtkIdList::New();
int maxpointsperpath = (int) floor(this->MaxPathLength/this->StepLength) + 1;
linearray->SetNumberOfIds(maxpointsperpath);
linearray->Reset();
  cout<<"Do tracks in the range: "<< range[0]<< " "<<range[1]<<endl;

  int *dim = inDatas[0]->GetDimensions();


  for (int r = range[0] ; r <= range[1] ; r++)
   {
   cout<<"Init path: "<<r<<endl;
   // Get Seed point
   this->GetSeedPoint(xyz);

   // Get Pointer to array of points
   cout <<"Get path object"<<endl;
   path = (vtkPolyData *)(this->GetPaths()->GetItemAsObject(r));
   pathPoints = path->GetPoints();
   pathLine = path->GetLines();
   pathProb = (vtkDoubleArray *)path->GetPointData()->GetScalars();
   
  
   linearray->Reset();
   //Insert seed point
   pathPoints->InsertNextPoint(xyz);
    
   arcLength = 0.0;
   int id =0;
   double cachehit = 0;
   double loops = 0;
   
   // Tracking loop
   t1 = 0;
   totaltimer->StartTimer();
   numberofcalls = 0;
   
    // Reset timer variables
    t2 = 0;
    t3 = 0;
    t4 = 0;
    t5 = 0; 
    
   cout<<"Lauching tracking: loop"<<endl;
   while(1)
    {
     
   

     if (inDatas[0]->ComputeStructuredCoordinates(xyz, ijk, pcoords) == 0)
       {
        //point out of volume. Stop tracking
        break;
       }
     
     //Draw random walk depending on xyz
      for (int i=0; i<3;i++)
        {
        if ((ceil(xyz[i]+VTKEPS)-xyz[i]) < vtkMath::Random())
              ijk[i] = ijk[i] +1;
        }

     
      
    //Check if we have the likelihood in the Cache
    index_ijk = ijk[0] + ijk[1]*dim[0] + ijk[2] * dim[0]*dim[1]; 
     
    cacheentry = NULL;
    if (this->GetActiveCache()==1) {
        for (int i=0; i< this->CacheId->GetNumberOfTuples();i++)
        {
        if (this->CacheId->GetValue(i) == index_ijk)
         {
          cacheentry = (vtkDoubleArray *) this->LikelihoodCache->GetItemAsObject(i);
          break;
         }
        }
    }

  

   timer->StartTimer();
    if (cacheentry == NULL)
     {
      //cout<<"ijk point: "<<ijk[0]<<" "<<ijk[1]<<" "<<ijk[2]<<endl;
      // Get data in that point and fill the params class
    
      for (int i=0; i<this->NumberOfInputs; i++)
       {
       params->dwi[i] = inDatas[i]->GetScalarComponentAsDouble(ijk[0],ijk[1],ijk[2],0);

      //cout<<params->dwi[i]<<endl;
       params->logdwi[i] = log(params->dwi[i] + VTKEPS);
       // Let us set the weights for each gradient direction.
       // R. Salvador et al. Human Brain Mapping 24:144-155 . 2005.
       params->squareWeights[i] = params->dwi[i]*params->dwi[i];
       } 
      
     //cout<<"Computing model"<<endl;
     //cout<<"Step 1"<<endl;
     this->EstimateTensorModel(this, params,PinvA,ATW2);
     //cout<<"Step 2"<<endl;
     this->EstimateConstrainedModel(this,params);
    
     anisotropy = params->beta/(params->alpha+params->beta +VTKEPS);
 
     timer->StartTimer(); 
     //cout<<"Step 3"<<endl;
     this->CalculateLikelihood(this,params,Nsamples,flatSD,likelihood);
     //cout<<"Done Step 3"<<endl;
     numberofcalls++;
     timer->StopTimer();
     t3 += timer->GetElapsedTime();

     if (this->GetActiveCache()==1) {
       // Update cache
       timer->StartTimer();
       vtkDoubleArray *newcache = vtkDoubleArray::New();
       newcache->SetNumberOfValues(this->SDMatchList->GetNumberOfTuples()+2);
       newcache->InsertValue(0,1);
       newcache->InsertValue(1,anisotropy);
       for (int i=0; i < this->SDMatchList->GetNumberOfTuples(); i++)
        {
          newcache->InsertValue(i+2,likelihood[(int)this->SDMatchList->GetComponent(i,0)]);
        }
       this->LikelihoodCache->AddItem(newcache);
       this->CacheId->InsertNextValue(index_ijk);
       timer->StopTimer();
       t2 += timer->GetElapsedTime();
     }

     }
     else {
  
      //Build likelihood from cache

      cacheentry->SetValue(0,cacheentry->GetValue(0)+1);

      anisotropy = cacheentry->GetValue(1);

      for (int i=0 ; i < this->SDMatchList->GetNumberOfTuples(); i++)
        {
           likelihood[(int)this->SDMatchList->GetComponent(i,0)] = cacheentry->GetValue(i);
           likelihood[(int)this->SDMatchList->GetComponent(i,1)] = cacheentry->GetValue(i);
        }
      
      cachehit++;

     }

    timer->StopTimer();
    t3 += timer->GetElapsedTime();
    

     timer->StartTimer();
     this->CalculatePrior(this,vprev,this->Gamma,Nsamples,flatSD,prior);
     timer->StopTimer();
      t4 += timer->GetElapsedTime();  

    timer->StartTimer();
     this->CalculatePosterior(Nsamples,likelihood,prior,posterior);
     timer->StopTimer();
   t2 += timer->GetElapsedTime();


     //cout<<"Step 4"<<endl;
     vindex = this->DrawRandomDirection(this,posterior);
     this->GetSphereDirections()->GetTuple(vindex,sd); 
 
  
     
     if (id == 0)
      {
      vprev = tmpvprev;
      }
     vprev[0]=sd[0];
     vprev[1]=sd[1];
     vprev[2]=sd[2];
    

     loops++;
      

     //Stopping criteria
     if (arcLength >this->MaxPathLength || 
          anisotropy < this->StoppingThreshold )
      {
       pathLine->InsertNextCell(linearray);
       //cout<<"ijk point: "<<ijk[0]<<" "<<ijk[1]<<" "<<ijk[2]<<endl;
       //cout<<"Stop criteria: "<< params->beta/(params->alpha+params->beta +VTKEPS)<< endl;
       //cout<<"Arc legnth: "<<arcLength<<endl;
       cout<<"%Cache hits: "<< cachehit/loops*100<<", Number of cache hits: "<<cachehit<<" Number of likelihood calls: "<< numberofcalls<< endl;
       cout<<"Likelihood: "<< t3<<endl;
       cout<<"Prior: "<< t4<<endl;
       cout<<"Posterior: "<< t2<<endl;
       totaltimer->StopTimer();
       cout<<"Total time: "<<totaltimer->GetElapsedTime()<<endl;
       break;
      }
      
     
     //Take the step
     xyz[0] = xyz[0] + vprev[0]*step;
     xyz[1] = xyz[1] + vprev[1]*step;
     xyz[2] = xyz[2] + vprev[2]*step;
     
     //Update the global array with Path points
     pathPoints->InsertNextPoint(xyz);
     linearray->InsertNextId(id);
     pathProb->InsertNextValue(posterior[vindex]);
     
     arcLength += this->StepLength;
     id++;    
   }
    
}

 cout<<"We are out"<<endl;
 //Deallocate arrays
 delete likelihood;
 delete prior;
 delete posterior;


 //Deallocate Matrix
 if (this->GetWeightedFitting()==1)
   {
     this->DeallocateMatrix(PinvA,7,N);
     this->DeallocateMatrix(ATW2,7,N); 
   }


 //Deallocate params
 cout<<"Deallocate params"<<endl;
 delete params->dwi;
 delete params->logdwi;
 delete params->squareWeights;
 delete params;

  linearray->Delete();
  cout<<"DONE"<<endl;

}

