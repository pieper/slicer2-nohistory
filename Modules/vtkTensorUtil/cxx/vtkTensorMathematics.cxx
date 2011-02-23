/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkTensorMathematics.cxx,v $
  Date:      $Date: 2007/10/16 21:25:48 $
  Version:   $Revision: 1.44 $

=========================================================================auto=*/

#ifdef _WIN32
// to pick up M_SQRT2 and other nice things...
#define _USE_MATH_DEFINES
#endif

// But, if you are on VS6.0 you don't get the define...
#ifndef M_SQRT2
#define M_SQRT2    1.41421356237309504880168872421      /* sqrt(2) */
#endif

#include "vtkImageData.h"
#include "vtkTensorMathematics.h"
#include "vtkMath.h"
#include "vtkObjectFactory.h"
#include "vtkTransform.h"
#include "vtkFloatArray.h"
#include "vtkPointData.h"
#include "vtkMathUtils.h"
#include "time.h"
#include "vtkLookupTable.h"

extern "C" {
#include "teem/ten.h"
}

#define VTK_EPS 10e-15

vtkCxxSetObjectMacro(vtkTensorMathematics,TensorRotationMatrix,vtkMatrix4x4);
vtkCxxSetObjectMacro(vtkTensorMathematics,ScalarMask,vtkImageData);

//----------------------------------------------------------------------------
vtkTensorMathematics* vtkTensorMathematics::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkTensorMathematics");
  if(ret)
    {
    return (vtkTensorMathematics*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkTensorMathematics;
}






//----------------------------------------------------------------------------
vtkTensorMathematics::vtkTensorMathematics()
{
  this->Operation = VTK_TENS_TRACE;

  this->ScaleFactor = 1.0;
  this->ExtractEigenvalues = 1;
  this->TensorRotationMatrix = NULL;
  this->ScalarMask = NULL;
  this->MaskWithScalars = 0;
}

//----------------------------------------------------------------------------     
 vtkTensorMathematics::~vtkTensorMathematics()     
 {     
   if( this->TensorRotationMatrix )     
     {     
     this->TensorRotationMatrix->Delete();     
     }     
   if( this->ScalarMask )     
     {     
     this->ScalarMask->Delete();     
     }     
 }

//----------------------------------------------------------------------------
// 
void vtkTensorMathematics::ExecuteInformation(vtkImageData **inDatas, 
                         vtkImageData *outData)
{
  int ext[6];
  //int ext[6], *ext2, idx;

  inDatas[0]->GetWholeExtent(ext);
  
  // We want the whole extent of the tensors, and should
  // allocate the matching size image data.
  vtkDebugMacro(<<"Execute information extent: " << 
    ext[0] << " " << ext[1] << " " << ext[2] << " " <<
    ext[3] << " " << ext[4] << " " << ext[5]);

  // We always want to output float, unless it is color
  outData->SetScalarType(VTK_FLOAT);

  if (this->Operation == VTK_TENS_COLOR_ORIENTATION)
    {
    // output color (RGBA)
    outData->SetNumberOfScalarComponents(4);
    outData->SetScalarType(VTK_UNSIGNED_CHAR);
    }
  if (this->Operation == VTK_TENS_COLOR_MODE) 
    {
    // output color (RGBA)
    outData->SetNumberOfScalarComponents(4);
    outData->SetScalarType(VTK_UNSIGNED_CHAR);
    }

  outData->SetWholeExtent(ext);
}






//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
// Handles the one input operations.
// Handles the ops where eigensystems are not computed.
template <class T>
static void vtkTensorMathematicsExecute1(vtkTensorMathematics *self,
                    vtkImageData *in1Data, 
                    vtkImageData *outData, T *outPtr,
                    int outExt[6], int id)
{
  // image variables
  int idxR, idxY, idxZ;
  int maxY, maxZ;
  int outIncX, outIncY, outIncZ;
  int inIncX, inIncY, inIncZ;
  int rowLength;
  // progress
  unsigned long count = 0;
  unsigned long target;
  // math operation
  int op = self->GetOperation();
  // tensor variables
  vtkDataArray *inTensors;
  vtkFloatingPointType tensor[3][3];
  vtkPointData *pd;
  int numPts, inPtId;
  // time
  clock_t tStart=0;
  tStart = clock();
  // working matrices
  vtkFloatingPointType *m[3], *v[3];
  vtkFloatingPointType m0[3], m1[3], m2[3];
  vtkFloatingPointType v0[3], v1[3], v2[3];
  m[0] = m0; m[1] = m1; m[2] = m2; 
  v[0] = v0; v[1] = v1; v[2] = v2;
  // scaling
  vtkFloatingPointType scaleFactor = self->GetScaleFactor();

  // find the input region to loop over
  pd = in1Data->GetPointData();
  inTensors = pd->GetTensors();
  numPts = in1Data->GetNumberOfPoints();

  if ( !inTensors || numPts < 1 )
    {
    vtkGenericWarningMacro(<<"No input tensor data to filter!");
    return;
    }

  // find the output region to loop over
  rowLength = (outExt[1] - outExt[0]+1);
  maxY = outExt[3] - outExt[2]; 
  maxZ = outExt[5] - outExt[4];
  target = (unsigned long)((maxZ+1)*(maxY+1)/50.0);
  target++;
  
  // Get increments to march through output data 
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
  in1Data->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);

  //Initialize ptId to walk through tensor volume
  int *inInc,*inFullUpdateExt;
  inInc = in1Data->GetIncrements();
  inFullUpdateExt = in1Data->GetExtent(); //We are only working over the update extent
  inPtId = ((outExt[0] - inFullUpdateExt[0]) * inInc[0]
          + (outExt[2] - inFullUpdateExt[2]) * inInc[1]
          + (outExt[4] - inFullUpdateExt[4]) * inInc[2]);
  
  int doMasking = 0;
  vtkDataArray *inMask = NULL;
  short * inMaskptr = NULL;
  if (self->GetScalarMask())
    {
    inMask = self->GetScalarMask()->GetPointData()->GetScalars();
    inMaskptr = (short *) inMask->GetVoidPointer(0);
    }

  if (self->GetMaskWithScalars())
    {
    if (inMask) {
      doMasking = 1;
    }
    else {
      doMasking = 0;
      //vtkWarningMacro("User has not set input mask, but has requested MaskWithScalars.\n Avoiding masking");
    }
    }


  for (idxZ = 0; idxZ <= maxZ; idxZ++)
    {
    for (idxY = 0; idxY <= maxY; idxY++)
      {
      if (!id) 
        {
        if (!(count%target))
          {
          self->UpdateProgress(count/(50.0*target));
          }
        count++;
        }

      for (idxR = 0; idxR < rowLength; idxR++)
        {

        if (doMasking && *(inMaskptr+inPtId) == 0)
          {
          *outPtr = 0;
          }
        else
          {

          // tensor at this voxel
          inTensors->GetTuple(inPtId,(vtkFloatingPointType *)tensor);

          // pixel operation
          switch (op)
            {
          case VTK_TENS_D11:
            *outPtr = (T)(scaleFactor*tensor[0][0]);
            break;

          case VTK_TENS_D22:
            *outPtr = (T)(scaleFactor*tensor[1][1]);
            break;

          case VTK_TENS_D33:
            *outPtr = (T)(scaleFactor*tensor[2][2]);
            break;

          case VTK_TENS_TRACE:
            /////////////////////*outPtr = (T)(scaleFactor*(tensor[0][0]
            //               +tensor[1][1]
            //               +tensor[2][2]));
            *outPtr = static_cast<T> (scaleFactor*vtkTensorMathematics::Trace(tensor));
            break;

          case VTK_TENS_DETERMINANT:
            //*outPtr = 
            //  (T)(scaleFactor*(vtkMath::Determinant3x3(tensor)));
            *outPtr = static_cast<T> (scaleFactor*vtkTensorMathematics::Determinant(tensor));
            break;
            }
        }

        if (inPtId > numPts) 
          {
          vtkGenericWarningMacro(<<"not enough input pts for output extent "<<numPts<<" "<<inPtId);
          }
        outPtr++;
        inPtId++;
        }
      outPtr += outIncY;
      inPtId += inIncY;
      }
    outPtr += outIncZ;
    inPtId += outIncZ;
    }

  //cout << "tensor math time: " << clock() - tStart << endl;
}

// copied from 
// vtkInteractorStyleUnicam.cxx
template <class Type>
inline Type tensor_math_clamp(const Type a,
                  const Type b,
                  const Type c) { return (a) > (b) ? ((a) < (c) ? (a) : (c)) : (b) ; }

//----------------------------------------------------------------------------
// This templated function executes the filter for any type of data.
// Handles the one input operations.
// Handles the ops where eigensystems are computed.
template <class T>
static void vtkTensorMathematicsExecute1Eigen(vtkTensorMathematics *self,
                          vtkImageData *in1Data, 
                          vtkImageData *outData, 
                          T *outPtr,
                          int outExt[6], int id)
{
  // image variables
  int idxR, idxY, idxZ;
  int maxY, maxZ;
  int outIncX, outIncY, outIncZ;
  int inIncX, inIncY, inIncZ;
  int rowLength;
  // progress
  unsigned long count = 0;
  unsigned long target;
  // math operation
  int op = self->GetOperation();
  // tensor variables
  vtkDataArray *inTensors;
  vtkFloatingPointType tensor[3][3];
  vtkPointData *pd;
  int numPts, inPtId;
  // time
  clock_t tStart=0;
  tStart = clock();
  // working matrices
  vtkFloatingPointType *m[3], w[3], *v[3];
  vtkFloatingPointType m0[3], m1[3], m2[3];
  vtkFloatingPointType v0[3], v1[3], v2[3];
  m[0] = m0; m[1] = m1; m[2] = m2; 
  v[0] = v0; v[1] = v1; v[2] = v2;
  int i, j;
  vtkFloatingPointType r, g, b;
  int extractEigenvalues;
  vtkFloatingPointType cl;
  // scaling
  vtkFloatingPointType scaleFactor = self->GetScaleFactor();
  // transformation of tensor orientations for coloring
  vtkTransform *trans = vtkTransform::New();
  int useTransform = 0;

  // map 0..1 values into the range a char takes on
  // but use scaleFactor so user can bump up the brightness
  const vtkFloatingPointType rgb_scale = (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX * scaleFactor / 1000.;
  vtkFloatingPointType rgb_temp = 0.;

  // find the input region to loop over
  pd = in1Data->GetPointData();
  inTensors = pd->GetTensors();
  numPts = in1Data->GetNumberOfPoints();

  if ( !inTensors || numPts < 1 )
    {
    vtkGenericWarningMacro(<<"No input tensor data to filter!");
    return;
    }

  // find the output region to loop over
  rowLength = (outExt[1] - outExt[0]+1);
  maxY = outExt[3] - outExt[2]; 
  maxZ = outExt[5] - outExt[4];
  target = (unsigned long)((maxZ+1)*(maxY+1)/50.0);
  target++;
  
  // Get increments to march through output data 
  outData->GetContinuousIncrements(outExt, outIncX, outIncY, outIncZ);
  in1Data->GetContinuousIncrements(outExt, inIncX, inIncY, inIncZ);

  //Initialize ptId to walk through tensor volume
  int *inInc,*inFullUpdateExt;
  inInc = in1Data->GetIncrements();
  inFullUpdateExt = in1Data->GetExtent(); //We are only working over the update extent
  inPtId = ((outExt[0] - inFullUpdateExt[0]) * inInc[0]
     + (outExt[2] - inFullUpdateExt[2]) * inInc[1]
     + (outExt[4] - inFullUpdateExt[4]) * inInc[2]);

  // decide whether to extract eigenfunctions or just use input cols
  extractEigenvalues = self->GetExtractEigenvalues();

  // if the user has set this matrix grab it
  if (self->GetTensorRotationMatrix())
    {
    trans->SetMatrix(self->GetTensorRotationMatrix());
    useTransform = 1;
    }

  // Check for masking
  int doMasking = 0;
  vtkDataArray *inMask = NULL;
  if (self->GetScalarMask())
    {
    inMask = self->GetScalarMask()->GetPointData()->GetScalars();
    }

  if (self->GetMaskWithScalars())
    {
    if (inMask)
      {
      doMasking = 1;
      }
    else
      {
      doMasking = 0;
      //vtkWarningMacro("User has not set input mask, but has requested MaskWithScalars.\n Avoiding masking");
      }
    }

   //vtkGenericWarningMacro( "Do masking: " << doMasking );


  // Loop through output pixels and input points

  for (idxZ = 0; idxZ <= maxZ; idxZ++)
    {
    for (idxY = 0; idxY <= maxY; idxY++)
      {
      if (!id) 
        {
        if (!(count%target))
          {
          self->UpdateProgress(count/(50.0*target));
          }
        count++;
        }

      for (idxR = 0; idxR < rowLength; idxR++)
        {

        if (doMasking && inMask->GetTuple1(inPtId)==0) {
          *outPtr = 0;

          if (op ==  VTK_TENS_COLOR_MODE || 
            op == VTK_TENS_COLOR_ORIENTATION) {
            outPtr++;
            *outPtr = 0; // green
            outPtr++;
            *outPtr = 0; // blue
            outPtr++;
            *outPtr = VTK_UNSIGNED_CHAR_MAX ; // alpha
          }
        }
        else {   

          // tensor at this voxel
          inTensors->GetTuple(inPtId,(vtkFloatingPointType *)tensor);

          // get eigenvalues and eigenvectors appropriately
          if (extractEigenvalues) 
            {
            for (j=0; j<3; j++)
              {
              for (i=0; i<3; i++)
                {
                // transpose
                m[i][j] = tensor[j][i];
                }
              }
            // compute eigensystem
            //vtkMath::Jacobi(m, w, v);
            vtkTensorMathematics::TeemEigenSolver(m,w,v);
            }
          else
            {
            // tensor columns are evectors scaled by evals
            for (i=0; i<3; i++)
              {
              v0[i] = tensor[i][0];
              v1[i] = tensor[i][1];
              v2[i] = tensor[i][2];
              }
            w[0] = vtkMath::Normalize(v0);
            w[1] = vtkMath::Normalize(v1);
            w[2] = vtkMath::Normalize(v2);
            }

          //Correct for negative eigenvalues. Three possible options:
          //  1. Round to zero
          //  2. Take absolute value
          //  3. Increase eigenvalues by negative part
          // The two first options have been problematic. Try 3 
          if (vtkTensorMathematics::FixNegativeEigenvalues(w)) 
        {
          vtkGenericWarningMacro( "Warning: Eigenvalues are not properly sorted" );
        }   

          // pixel operation
          switch (op)
            {
          case VTK_TENS_RELATIVE_ANISOTROPY:
            *outPtr = static_cast<T> (vtkTensorMathematics::RelativeAnisotropy(w));
            break;
          case VTK_TENS_FRACTIONAL_ANISOTROPY:
            *outPtr = static_cast<T> (vtkTensorMathematics::FractionalAnisotropy(w));
            break;

          case VTK_TENS_LINEAR_MEASURE:
            *outPtr = static_cast<T> (vtkTensorMathematics::LinearMeasure(w));
            break;

          case VTK_TENS_PLANAR_MEASURE:
            *outPtr = static_cast<T> (vtkTensorMathematics::PlanarMeasure(w));
            break;

          case VTK_TENS_SPHERICAL_MEASURE:
            *outPtr = static_cast<T> (vtkTensorMathematics::SphericalMeasure(w));
            break;

          case VTK_TENS_MAX_EIGENVALUE:
            *outPtr = (T)w[0];
            break;

          case VTK_TENS_MID_EIGENVALUE:
            *outPtr = (T)w[1];
            break;

          case VTK_TENS_MIN_EIGENVALUE:
            *outPtr = (T)w[2];
            break;

          case VTK_TENS_PARALLEL_DIFFUSIVITY:
            *outPtr = static_cast<T> (vtkTensorMathematics::ParallelDiffusivity(w));
            break;

          case VTK_TENS_PERPENDICULAR_DIFFUSIVITY:
            *outPtr = static_cast<T> (vtkTensorMathematics::PerpendicularDiffusivity(w));
            break;

          case VTK_TENS_MAX_EIGENVALUE_PROJX:
            *outPtr = static_cast<T> (vtkTensorMathematics::MaxEigenvalueProjectionX(v,w));
            break;

          case VTK_TENS_MAX_EIGENVALUE_PROJY:
            *outPtr = static_cast<T> (vtkTensorMathematics::MaxEigenvalueProjectionY(v,w));
            break;           

          case VTK_TENS_MAX_EIGENVALUE_PROJZ:
            *outPtr = static_cast<T> (vtkTensorMathematics::MaxEigenvalueProjectionZ(v,w));
            break;           

      case VTK_TENS_RAI_MAX_EIGENVEC_PROJX:
        *outPtr = static_cast<T> (vtkTensorMathematics::RAIMaxEigenvecX(v,w));
        break;

      case VTK_TENS_RAI_MAX_EIGENVEC_PROJY:
            *outPtr = static_cast<T> (vtkTensorMathematics::RAIMaxEigenvecY(v,w));
            break;

      case VTK_TENS_RAI_MAX_EIGENVEC_PROJZ:
            *outPtr = static_cast<T> (vtkTensorMathematics::RAIMaxEigenvecZ(v,w));
            break;

      case VTK_TENS_MODE:
            *outPtr = static_cast<T> (vtkTensorMathematics::Mode(w));
            break;
      case VTK_TENS_ISOTROPIC_P:
            *outPtr = static_cast<T> (vtkTensorMathematics::IsotropicP(w));
            break;
      case VTK_TENS_ANISOTROPIC_Q:
            *outPtr = static_cast<T> (vtkTensorMathematics::AnisotropicQ(w));
            break;

          case VTK_TENS_COLOR_MODE:

            vtkTensorMathematics::ColorByMode(w,r,g,b);
            // scale maps 0..1 values into the range a char takes on
            rgb_temp = (rgb_scale*r);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            rgb_temp = (rgb_scale*g);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            rgb_temp = (rgb_scale*b);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            *outPtr = (T)VTK_UNSIGNED_CHAR_MAX; //alpha

            break;

          case VTK_TENS_COLOR_ORIENTATION:
            // If the user has set the rotation matrix
            // then transform the eigensystem first
            // This is used to rotate the vector into RAS space
            // for consistent anatomical coloring.
            double v_maj[3];
            v_maj[0]=v[0][0];
            v_maj[1]=v[1][0];
            v_maj[2]=v[2][0];
            if (useTransform)
              {
              trans->TransformPoint(v_maj,v_maj);
              }
            // Color R, G, B depending on max eigenvector
            // scale maps 0..1 values into the range a char takes on
            cl = vtkTensorMathematics::LinearMeasure(w);
            rgb_temp = (rgb_scale*fabs(v_maj[0])*cl);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            rgb_temp = (rgb_scale*fabs(v_maj[1])*cl);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            rgb_temp = (rgb_scale*fabs(v_maj[2])*cl);
            *outPtr = (T)tensor_math_clamp(rgb_temp, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MIN, (vtkFloatingPointType)VTK_UNSIGNED_CHAR_MAX);
            outPtr++;
            *outPtr = (T)VTK_UNSIGNED_CHAR_MAX; //alpha

            break;

            }

          // scale vtkFloatingPointType if the user requested this
          if (scaleFactor != 1 && op != VTK_TENS_COLOR_ORIENTATION 
            && op != VTK_TENS_COLOR_MODE)
            {
            *outPtr = (T) ((*outPtr) * scaleFactor);
            }
        }

        outPtr++;
        inPtId++;
        }
      outPtr += outIncY;
      inPtId += inIncY;
      }
    outPtr += outIncZ;
    inPtId += outIncZ;
    }
  // Cleanup     
  trans->Delete();     
 
  //cout << "tensor math time: " << clock() - tStart << endl;
}

//----------------------------------------------------------------------------
// This method is passed a input and output datas, and executes the filter
// algorithm to fill the output from the inputs.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkTensorMathematics::ThreadedExecute(vtkImageData **inData, 
                      vtkImageData *outData,
                      int outExt[6], int id)
{
  void *outPtr;
  
  vtkDebugMacro(<< "Execute: inData = " << inData 
        << ", outData = " << outData);
  

  if (inData[0] == NULL)
    {
      vtkErrorMacro(<< "Input " << 0 << " must be specified.");
      return;
    }


  outPtr = outData->GetScalarPointerForExtent(outExt);
  
  // single input only for now
  vtkDebugMacro ("In Threaded Execute. scalar type is " << inData[0]->GetScalarType() << "op is: " << this->Operation);

  switch (this->GetOperation()) 
    {
      
      // Operations where eigenvalues are not computed
    case VTK_TENS_D11:
    case VTK_TENS_D22:
    case VTK_TENS_D33:
    case VTK_TENS_TRACE:
    case VTK_TENS_DETERMINANT:
      switch (outData->GetScalarType())
      {
      // we set the output data scalar type depending on the op
      // already.  And we only access the input tensors
      // which are float.  So this switch statement on output
      // scalar type is sufficient.
      vtkTemplateMacro6(vtkTensorMathematicsExecute1,
                this,inData[0], outData, 
                (VTK_TT *)(outPtr), outExt, id);
      default:
        vtkErrorMacro(<< "Execute: Unknown ScalarType");
        return;
      }
      break;

    // Operations where eigenvalues are computed      
    case VTK_TENS_RELATIVE_ANISOTROPY:
    case VTK_TENS_FRACTIONAL_ANISOTROPY:
    case VTK_TENS_LINEAR_MEASURE:
    case VTK_TENS_PLANAR_MEASURE:
    case VTK_TENS_SPHERICAL_MEASURE:
    case VTK_TENS_MAX_EIGENVALUE:
    case VTK_TENS_MID_EIGENVALUE:
    case VTK_TENS_MIN_EIGENVALUE:
    case VTK_TENS_MAX_EIGENVALUE_PROJX:
    case VTK_TENS_MAX_EIGENVALUE_PROJY:
    case VTK_TENS_MAX_EIGENVALUE_PROJZ: 
    case VTK_TENS_RAI_MAX_EIGENVEC_PROJX:
    case VTK_TENS_RAI_MAX_EIGENVEC_PROJY:
    case VTK_TENS_RAI_MAX_EIGENVEC_PROJZ:
    case VTK_TENS_COLOR_ORIENTATION:
    case VTK_TENS_MODE:
    case VTK_TENS_COLOR_MODE:
    case VTK_TENS_PARALLEL_DIFFUSIVITY:
    case VTK_TENS_PERPENDICULAR_DIFFUSIVITY:
    case VTK_TENS_ISOTROPIC_P:
    case VTK_TENS_ANISOTROPIC_Q:
      switch (outData->GetScalarType())
      {
        vtkTemplateMacro6(vtkTensorMathematicsExecute1Eigen,
                this,inData[0], outData, 
                (VTK_TT *)(outPtr), outExt, id);
        default:
        vtkErrorMacro(<< "Execute: Unknown ScalarType");
        return;
      }
    break;
  }

}

int vtkTensorMathematics::FixNegativeEigenvalues(vtkFloatingPointType w[3])
{
  if(w[2]<0) {
     w[1] += (-w[2]);
     w[0] += (-w[2]);
     w[2] = 0;
  }
     
  if (!((w[0]>= w[1] && w[0]>= w[2]) &&
      (w[1]>=w[2]) ))  {
        return -1;
  }
  return 0;
}

vtkFloatingPointType vtkTensorMathematics::Trace(vtkFloatingPointType D[3][3])
{
  return (D[0][0] + D[1][1] + D[2][2]);

}

vtkFloatingPointType vtkTensorMathematics::Determinant(vtkFloatingPointType D[3][3])
{
  return vtkMath::Determinant3x3(D);
}

vtkFloatingPointType vtkTensorMathematics::RelativeAnisotropy(vtkFloatingPointType w[3]) 
{
  vtkFloatingPointType trace = w[0]+w[1]+w[2];   
  
  if (trace < VTK_EPS)
     trace = trace + VTK_EPS;
  
  return ((0.70710678)*
                (sqrt((w[0]-w[1])*(w[0]-w[1]) + 
                      (w[2]-w[1])*(w[2]-w[1]) +
                      (w[2]-w[0])*(w[2]-w[0])))/trace);
}

vtkFloatingPointType vtkTensorMathematics::FractionalAnisotropy(vtkFloatingPointType w[3])
{
  vtkFloatingPointType norm = sqrt(w[0]*w[0]+ w[1]*w[1] +  w[2]*w[2]); 
   
   if (norm < VTK_EPS)
      norm = norm + VTK_EPS;
  
  return ((0.70710678)*
                (sqrt((w[0]-w[1])*(w[0]-w[1]) + 
                      (w[2]-w[1])*(w[2]-w[1]) +
                      (w[2]-w[0])*(w[2]-w[0])))/norm);
} 

vtkFloatingPointType vtkTensorMathematics::LinearMeasure(vtkFloatingPointType w[3])
{
  if (w[0] < VTK_EPS) 
     return (w[0] - w[1])/(w[0]+VTK_EPS);
  else
     return (w[0] - w[1])/(w[0]);

}

vtkFloatingPointType vtkTensorMathematics::PlanarMeasure(vtkFloatingPointType w[3])
{
  if (w[0] < VTK_EPS)
     return (w[1] - w[2])/(w[0]+VTK_EPS);
  else
     return (w[1] - w[2])/(w[0]);
}

vtkFloatingPointType vtkTensorMathematics::SphericalMeasure(vtkFloatingPointType w[3])
{
  if (w[0] < VTK_EPS)
     return (w[2])/(w[0]+VTK_EPS);
  else
     return  (w[2])/(w[0]);
}


vtkFloatingPointType vtkTensorMathematics::MaxEigenvalue(vtkFloatingPointType w[3])
{
  return w[0];
}

vtkFloatingPointType vtkTensorMathematics::MiddleEigenvalue(vtkFloatingPointType w[3])
{
  return w[1];
}

vtkFloatingPointType vtkTensorMathematics::MinEigenvalue(vtkFloatingPointType w[3])
{
  return w[2];
}

vtkFloatingPointType vtkTensorMathematics::ParallelDiffusivity(vtkFloatingPointType w[3])
{
  return w[0];
}

vtkFloatingPointType vtkTensorMathematics::PerpendicularDiffusivity(vtkFloatingPointType w[3])
{
  return ( ( w[1] + w[2] ) / 2 );
}


vtkFloatingPointType vtkTensorMathematics::RAIMaxEigenvecX(vtkFloatingPointType **v, vtkFloatingPointType w[3]) 
{
  return (fabs(v[0][0])*vtkTensorMathematics::RelativeAnisotropy(w));
}

vtkFloatingPointType vtkTensorMathematics::RAIMaxEigenvecY(vtkFloatingPointType **v, vtkFloatingPointType w[3])
{
  return (fabs(v[1][0])*vtkTensorMathematics::RelativeAnisotropy(w));
}

vtkFloatingPointType vtkTensorMathematics::RAIMaxEigenvecZ(vtkFloatingPointType **v, vtkFloatingPointType w[3])
{
  return (fabs(v[2][0])*vtkTensorMathematics::RelativeAnisotropy(w));
}

vtkFloatingPointType vtkTensorMathematics::MaxEigenvalueProjectionX(vtkFloatingPointType **v, vtkFloatingPointType w[3]) 
{
  return (w[0]*fabs(v[0][0]));
}

vtkFloatingPointType vtkTensorMathematics::MaxEigenvalueProjectionY(vtkFloatingPointType **v, vtkFloatingPointType w[3]) 
{
  return (w[0]*fabs(v[1][0]));
}

vtkFloatingPointType vtkTensorMathematics::MaxEigenvalueProjectionZ(vtkFloatingPointType **v, vtkFloatingPointType w[3]) 
{
  return (w[0]*fabs(v[2][0]));
}

vtkFloatingPointType vtkTensorMathematics::Mode(vtkFloatingPointType w[3])
{

  // see PhD thesis, Gordon Kindlmann
  vtkFloatingPointType mean = (w[0] + w[1] + w[2])/3;
  vtkFloatingPointType norm = ((w[0] - mean)*(w[0] - mean) + 
                  (w[1] - mean)*(w[1] - mean) + 
                  (w[2] - mean)*(w[2] - mean))/3;
  norm = sqrt(norm);
  norm = norm*norm*norm;
  if (norm < VTK_EPS)
     norm += VTK_EPS;
  // multiply by sqrt 2: range from -1 to 1
  return  (M_SQRT2*((w[0] + w[1] - 2*w[2]) * 
                         (2*w[0] - w[1] - w[2]) * 
                         (w[0] - 2*w[1] + w[2]))/(27*norm)); 
}

vtkFloatingPointType vtkTensorMathematics::IsotropicP(vtkFloatingPointType w[3])
{
  // square root of sum of eigenvalues. the "isotropic part" 
  return ( sqrt( w[0] + w[1] + w[2] ) );
}

vtkFloatingPointType vtkTensorMathematics::AnisotropicQ(vtkFloatingPointType w[3])
{
  // the "anisotropic part"
  vtkFloatingPointType mean = (w[0] + w[1] + w[2])/3;  
  return( sqrt( (w[0] - mean)*(w[0] - mean) + 
                (w[1] - mean)*(w[1] - mean) + 
                (w[2] - mean)*(w[2] - mean) ) );
}


void vtkTensorMathematics::ColorByMode(vtkFloatingPointType w[3], vtkFloatingPointType &R, 
                                                       vtkFloatingPointType &G, vtkFloatingPointType &B)
{
  // see PhD thesis, Gordon Kindlmann
  // Compute FA for amount of gray
  vtkFloatingPointType fa = vtkTensorMathematics::FractionalAnisotropy(w);
  // Compute mode
  vtkFloatingPointType mode = vtkTensorMathematics::Mode(w);
  // Calculate RGB value for this mode and FA
  vtkTensorMathematics::ModeToRGB(mode, fa, R, G, B);
}


void vtkTensorMathematics::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "Operation: " << this->Operation << "\n";
}

// Colormap: convert our mode value (-1..1) to RGB
void vtkTensorMathematics::ModeToRGB(double Mode, double FA,
                                     double &R, double &G, double &B)
{

   double Hue, frac;
   int sextant;

   // Mode is clamped to [-1,1]
   Mode = (Mode < -0.9999
           ? -0.9999
           : (Mode > 0.9999
              ? 0.9999
              : Mode));
   // invert mode to get desired colormap effect
   // negative (blue) up to positive (red)
   Mode = -Mode;
   // Hue is in [0, 6)
   Hue = 3*(Mode+1);
   // to avoid using last two sextants
   Hue *= 4.0/6.0;
   sextant = (int) floor(Hue);
   frac = Hue - sextant;
   switch (sextant) {
   case 0: { R = 1;      G = frac;   B = 0;      break; }
   case 1: { R = 1-frac; G = 1;      B = 0;      break; }
   case 2: { R = 0;      G = 1;      B = frac;   break; }
   case 3: { R = 0;      G = 1-frac; B = 1;      break; }
   case 4: { R = frac;   G = 0;      B = 1;      break; }
   case 5: { R = 1;      G = 0;      B = 1-frac; break; }
   }
   // FA controls lerp between gray and color
   //R = FA*R + (1-FA)*0.5;
   //G = FA*G + (1-FA)*0.5;
   //B = FA*B + (1-FA)*0.5;
   R = FA*R;
   G = FA*G;
   B = FA*B;
}

int vtkTensorMathematics::TeemEigenSolver(double **m, double *w, double **v) 
{
    double t[7];
    double evec[9];
    double eval[3];
    int res;
    //TEN_M2T(t,m);
     t[1] = m[0][0];
     t[2] = m[0][1];
     t[3] = m[0][2];
     t[4] = m[1][1];
     t[5] = m[1][2];
     t[6] = m[2][2];

    if (v == NULL)
        res=tenEigensolve_d(eval,NULL,t);
    else
         res=tenEigensolve_d(eval,evec,t);

    //Asigned output eigenvalues
    if (v != NULL) {
        v[0][0] = evec[0]; v[1][0] = evec[1]; v[2][0] = evec[2];
        v[0][1] = evec[3]; v[1][1] = evec[4]; v[2][1] = evec[5];
        v[0][2] = evec[6]; v[1][2] = evec[7]; v[2][2] = evec[8];
    }
    w[0]=eval[0];
    w[1]=eval[1];
    w[2]=eval[2];
    return res;

}
