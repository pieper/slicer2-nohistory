/*=auto=========================================================================

(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


=========================================================================auto=*/
#include <time.h>
#include "vtkVersion.h"
#if ( (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2) || VTK_MAJOR_VERSION == 4 )
#include "vtkCommand.h"
#endif
#include "vtkObjectFactory.h"
#include "vtkImageMIReg.h"
#include "vtkImageFastGaussian.h"
#include "vtkImageShrink3D.h"
#include "qgauss.h"

//----------------------------------------------------------------------------
// New
//----------------------------------------------------------------------------
vtkImageMIReg* vtkImageMIReg::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageMIReg");
  if(ret)
  {
    return (vtkImageMIReg*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageMIReg;
}

//----------------------------------------------------------------------------
// Constructor
//----------------------------------------------------------------------------
vtkImageMIReg::vtkImageMIReg()
{
  int i;
  
  // Inputs
  this->Reference = NULL;
  this->Subject = NULL;
  this->RefTrans = NULL;
  this->SubTrans = NULL;
  this->InitialPose = NULL;
  
  // Output
  this->FinalPose = vtkPose::New();
  this->CurrentPose = vtkPose::New();

  // Workspace
  for (i=0; i < 4; i++) {
    this->Refs[i] = NULL;
    this->Subs[i] = NULL;
    this->RefRasToIjk[i] = vtkRasToIjkTransform::New();
    this->SubRasToIjk[i] = vtkRasToIjkTransform::New();
  }

  // Params
  this->SampleSize = 50;
  this->SigmaUU    = 2.0f;
  this->SigmaVV    = 2.0f;
  this->SigmaV     = 4.0f;
  this->PMin       = 0.01f;
  this->UpdateIterations = 200;

  // Params per resolution
  //
  // Coursest (smallest image)
  this->NumIterations[0]      = 16000;
  this->LambdaDisplacement[0] = 1.0f;
  this->LambdaRotation[0]     = 0.0005f;
  //
  this->NumIterations[1]      = 4000;
  this->LambdaDisplacement[1] = 0.4;
  this->LambdaRotation[1]     = 0.00008f;
  //
  this->NumIterations[2]      = 4000;
  this->LambdaDisplacement[2] = 0.05f;
  this->LambdaRotation[2]     = 0.000005f;
  //
  // Finest (full size image)
  this->NumIterations[3]      = 4000;
  this->LambdaDisplacement[3] = 0.01f;
  this->LambdaRotation[3]     = 0.000001f;

  this->Reset();
}

//----------------------------------------------------------------------------
// Destructor
//----------------------------------------------------------------------------
vtkImageMIReg::~vtkImageMIReg()
{
  int i;
  
  // Inputs
  if (this->Reference != NULL) {
    this->Reference->UnRegister(this);
  }
  if (this->Subject != NULL) {
    this->Subject->UnRegister(this);
  }
  if (this->RefTrans != NULL) {
    this->RefTrans->UnRegister(this);
  }
  if (this->SubTrans != NULL) {
    this->SubTrans->UnRegister(this);
  }

  // Transforms
  for (i=0; i<4; i++)
  {
    if (this->RefRasToIjk[i]) {
      this->RefRasToIjk[i]->Delete();
      this->RefRasToIjk[i] = NULL;
    }
    if (this->SubRasToIjk[i]) {
      this->SubRasToIjk[i]->Delete();
      this->SubRasToIjk[i] = NULL;
    }
  }

  // Outputs
  // Signal that we're no longer using them
  if (this->InitialPose != NULL) {
    this->InitialPose->UnRegister(this);
  }
  if (this->FinalPose != NULL) {
    this->FinalPose->UnRegister(this);
  }
  if (this->CurrentPose != NULL) {
    this->CurrentPose->UnRegister(this);
  }
}

//----------------------------------------------------------------------------
// Reset
//
// Call before the Update iterations
//----------------------------------------------------------------------------
void vtkImageMIReg::Reset()
{
  // Reset
  this->CurIteration[0] = 0;
  this->CurIteration[1] = 0;
  this->CurIteration[2] = 0;
  this->CurIteration[3] = 0;
  this->RunTime = 0;
  this->InProgress = 0;
}

//----------------------------------------------------------------------------
// Update
//
// Written with vtkImageIteratedFilter as an example.
//----------------------------------------------------------------------------
void vtkImageMIReg::Update() 
{
  // Ensure inputs exist
  if (!this->Reference) {
    vtkErrorMacro("vtkImageMIReg::Update: Reference Image not set");
    return;
  }
  if (!this->Subject) {
    vtkErrorMacro("vtkImageMIReg::Update: Subject Image not set");
    return;
  }

  // If inputs or parameters changed, then reset
  if (this->GetMTime() > this->UTime.GetMTime())
  {
    // Update upstream pipeline
    this->Reference->Update();
    this->Subject->Update();

    // Prepare to execute
    this->Reset();
    this->InProgress = 1;
    clock_t tStart = clock();
    if (this->Initialize()) return;
    this->RunTime += clock() - tStart;

    // Start progress reporting
    #if ( (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2) || VTK_MAJOR_VERSION == 4 )
      this->InvokeEvent(vtkCommand::StartEvent,NULL);
    #else
      if (this->StartMethod)
      {
        (*this->StartMethod)(this->StartMethodArg);
      }
    #endif  

    // Don't enter this loop again until something changes
    this->UTime.Modified();
    return;
  }

  // If iteration is in progress, continue executing
  if (this->InProgress) 
  {
    clock_t tStart = clock();
    this->Execute();
    this->RunTime += clock() - tStart;

    // Report progress
    int curIter=0, totIter=0, i;
    for (i=0; i<4; i++) {
      curIter += this->CurIteration[i];
      totIter += this->NumIterations[i];
    }
    this->UpdateProgress((float)curIter/(float)totIter);

    // If that ends it, de-allocate memory
    if (!this->InProgress) 
    {
      // End progress reporting
      #if ( (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2) || VTK_MAJOR_VERSION == 4 )
        this->InvokeEvent(vtkCommand::EndEvent,NULL);
      #else
        if (this->EndMethod)
        {
          (*this->EndMethod)(this->EndMethodArg);
        } 
      #endif

      this->Cleanup();
    }
  }
}

//----------------------------------------------------------------------------
// Initialize
//
// Returns -1 if unable to continue, else 0.
//----------------------------------------------------------------------------
int vtkImageMIReg::Initialize()
{
  int i, *ext, zSmooth, numSlices, numCutoff;
  vtkImageFastGaussian *smooth;
  vtkImageShrink3D *down;
  float slThick1, slThick2, *spacing1, *spacing2;
  float *spacing = this->Subject->GetSpacing();
  vtkVector3 *ftl = vtkVector3::New();
  vtkVector3 *ftr = vtkVector3::New();
  vtkVector3 *fbr = vtkVector3::New();
  vtkVector3 *ltl = vtkVector3::New();
  vtkVector3 *kDir = vtkVector3::New();
  vtkVector3 *kStep = vtkVector3::New();

  //
  // Validate inputs
  //
  if (this->Reference->GetScalarType() != VTK_SHORT) {
    vtkErrorMacro(<<"Reference scalar type must be short."); 
    return -1;
  }
  if (this->Reference->GetNumberOfScalarComponents() != 1) {
    vtkErrorMacro(<<"Reference must have 1 component."); 
    return -1;
  }
  if (this->Subject->GetScalarType() != VTK_SHORT) {
    vtkErrorMacro(<<"Subject scalar type must be short."); 
    return -1;
  }
  if (this->Subject->GetNumberOfScalarComponents() != 1) {
    vtkErrorMacro(<<"Subject must have 1 component."); 
    return -1;
  }
  if (this->RefTrans == NULL) {
    vtkErrorMacro(<<"No Reference RasToIjkTransform."); 
    return -1;
  }
  if (this->SubTrans == NULL) {
    vtkErrorMacro(<<"No Subject RasToIjkTransform."); 
    return -1;
  }
  if (!spacing[0] || !spacing[1] || !spacing[2]) {
    vtkErrorMacro(<<"Subject Spacing can't be 0, for gradient purposes.");
    return -1;
  }

  // If no poses, allocate them
  if (!this->InitialPose) {
    vtkPose *initPose = vtkPose::New();
    this->SetInitialPose(initPose);
  }

  // Highest resolution (3) corresponds to the external input images.
  this->Refs[3] = this->Reference;
  this->Refs[3]->Register((vtkObject*)NULL);
  this->Subs[3] = this->Subject;
  this->Subs[3]->Register((vtkObject*)NULL);
  this->RefRasToIjk[3]->Copy(this->RefTrans);
  this->SubRasToIjk[3]->Copy(this->SubTrans);

  //
  // Downsample images to create various resolutions
  //
  //
  // Keep the voxels roughly isotropic. So if XY-voxel size is 1mm, and Z is 2mm,
  // downsample only along X and Y. Note that in this case, the next iteration
  // would downsample in all 3 axes because they are already isotropic.
  //
  if (this->NumIterations[0] || this->NumIterations[1] || this->NumIterations[2])
  {
    for (i=2; i >= 0; i--)
    {
      //
      // Reference image
      //

      // Smooth image
      smooth = vtkImageFastGaussian::New();
      smooth->SetInput(this->Refs[i+1]);

      // Downsample image
      down = vtkImageShrink3D::New();
      down->SetMean(0);
      down->SetInput(smooth->GetOutput()); 

      // Decide whether to downsize along Z-axis
      spacing = this->Refs[i+1]->GetSpacing();
      if (spacing[2] > spacing[0]*1.5f) {
        zSmooth = 0;
        smooth->SetAxisFlags(1,1,0);
        down->SetShrinkFactors(2,2,1);
      } else {
        zSmooth = 1;
        smooth->SetAxisFlags(1,1,1);
        down->SetShrinkFactors(2,2,2);
      }

      // Execute
      smooth->Modified(); 
      down->Modified(); 
      down->Update();

      // Attach output to me
      this->Refs[i] = down->GetOutput();
      this->Refs[i]->Register((vtkObject*)NULL);

      // Detach output from source
      this->Refs[i]->SetSource(NULL);
      smooth->SetOutput(NULL);
      smooth->Delete();
      down->SetOutput(NULL);
      down->Delete();

      // Compute Ijk-To-Ras matrices for downsampled image
      //
      // Corner points same in X,Y because the points are at voxel corners. 
      //
      // But Z must move 1/2 orig voxel inward because points are at voxel centers.
      // Approach: move the original corner points in the K direction
      // by moving back 1/2 old spacing, and then forward 1/2 new spacing.
      // The last slice also needs to move forward by the number of old
      // slices that were cut-off: nz1 % Factor
      // kDir = ltl - ftl
      // kStep = kDir * (slThick2-slThick1)
      // ftl += kStep
      // ftr += kStep
      // fbr += kStep
      // ltl -= kStep
      this->RefRasToIjk[i+1]->GetCorners(ftl, ftr, fbr, ltl);
      if (zSmooth) {
        spacing1 = this->Refs[i+1]->GetSpacing();
        spacing2 = this->Refs[i  ]->GetSpacing();
        slThick1 = spacing1[2];
        slThick2 = spacing2[2];
        kDir->Subtract(ltl, ftl);
        kDir->Normalize();
        kStep->Copy(kDir);
        kStep->Multiply((slThick2 - slThick1) * 0.5);
        ftl->Add(kStep);
        ftr->Add(kStep);
        fbr->Add(kStep);
        ltl->Subtract(kStep);
        ext = this->Refs[i+1]->GetExtent();
        numSlices = ext[5]-ext[4]+1;
        numCutoff = numSlices % 2;
        if (numCutoff > 0) {
          // Input has odd number of slices (in the case of downsampling by 2)
          kStep->Copy(kDir);
          kStep->Multiply(slThick1 * numCutoff);
          ltl->Subtract(kStep);
        }
      }
      this->RefRasToIjk[i]->SetExtent(this->Refs[i]->GetExtent());
      this->RefRasToIjk[i]->SetSpacing(this->Refs[i]->GetSpacing());
      this->RefRasToIjk[i]->SetCorners(ftl, ftr, fbr, ltl);

      //
      // Subject image
      //

      // Smooth image
      smooth = vtkImageFastGaussian::New();
      smooth->SetInput(this->Subs[i+1]);

      // Downsample image
      down = vtkImageShrink3D::New();
      down->SetMean(0);
      down->SetInput(smooth->GetOutput()); 

      // Decide whether to downsize along Z-axis
      spacing = this->Subs[i+1]->GetSpacing();
      if (spacing[2] > spacing[0]*1.5f) {
        zSmooth = 0;
        smooth->SetAxisFlags(1,1,0);
        down->SetShrinkFactors(2,2,1);
      } else {
        zSmooth = 1;
        smooth->SetAxisFlags(1,1,1);
        down->SetShrinkFactors(2,2,2);
      }

      // Execute
      smooth->Modified(); 
      down->Modified(); 
      down->Update();

      // Attach output to me
      this->Subs[i] = down->GetOutput();
      this->Subs[i]->Register((vtkObject*)NULL);

      // Detach output from source
      this->Subs[i]->SetSource(NULL);
      smooth->SetOutput(NULL);
      smooth->Delete();
      down->SetOutput(NULL);
      down->Delete();

      // Compute Ras-to-Ijk matrices for downsampled image
      this->SubRasToIjk[i+1]->GetCorners(ftl, ftr, fbr, ltl);
      if (zSmooth) {
        spacing1 = this->Subs[i+1]->GetSpacing();
        spacing2 = this->Subs[i  ]->GetSpacing();
        slThick1 = spacing1[2];
        slThick2 = spacing2[2];
        kDir->Subtract(ltl, ftl);
        kDir->Normalize();
        kStep->Copy(kDir);
        kStep->Multiply((slThick2 - slThick1) * 0.5);
        ftl->Add(kStep);
        ftr->Add(kStep);
        fbr->Add(kStep);
        ltl->Subtract(kStep);
        ext = this->Subs[i+1]->GetExtent();
        numSlices = ext[5]-ext[4]+1;
        numCutoff = numSlices % 2;
        if (numCutoff > 0) {
          kStep->Copy(kDir);
          kStep->Multiply(slThick1*numCutoff);
          ltl->Subtract(kStep);
        }
      }
      this->SubRasToIjk[i]->SetExtent(this->Subs[i]->GetExtent());
      this->SubRasToIjk[i]->SetSpacing(this->Subs[i]->GetSpacing());
      this->SubRasToIjk[i]->SetCorners(ftl, ftr, fbr, ltl);
    }
  }

  // Initialize Pose
  this->CurrentPose->Copy(this->InitialPose);

  ftl->Delete();
  ftr->Delete();
  fbr->Delete();
  ltl->Delete();
  kDir->Delete();
  kStep->Delete();
  return 0;
}

//----------------------------------------------------------------------------
// Cleanup
//----------------------------------------------------------------------------
void vtkImageMIReg::Cleanup()
{
  int i;

  // Deallocate voxels of downsampled images
  for (i=0; i<4; i++) 
  {
    this->Refs[i]->UnRegister(this);
    this->Refs[i] = NULL;
    this->Subs[i]->UnRegister(this);
    this->Subs[i] = NULL;
  }
}

//----------------------------------------------------------------------------
// RandomCoordinate
//
// Draw a random integer data coordinate from an image.
// Express as 0-based IJK, not extent-based.
//----------------------------------------------------------------------------
static void RandomIjkCoordinate(vtkVector3 *B, vtkImageData *data)
{
  int *ext = data->GetExtent();
  
  B->SetElement(0, (int)(vtkMath::Random() * (float)(ext[1]-ext[0]+1))); 
  B->SetElement(1, (int)(vtkMath::Random() * (float)(ext[3]-ext[2]+1))); 
  B->SetElement(2, (int)(vtkMath::Random() * (float)(ext[5]-ext[4]+1))); 
}

//----------------------------------------------------------------------------
// ImageGradientInterpolation (templated)
//----------------------------------------------------------------------------
template <class T>
static void ImageGradientInterpolation(vtkImageData *data, 
  vtkRasToIjkTransform *rasToIjk, vtkVector3 *grad, vtkVector3 *ras, 
  T *inPtr, double *value)
{
  vtkVector3* ijk = vtkVector3::New();
  double x, y, z, x0, y0, z0, x1, y1, z1, dx0, dx1, dxy0, dxy1;
  int xi, yi, zi, nx, ny, nz, nxy, idx;
  double v000, v001, v010, v011, v100, v101, v110, v111;
  float sx, sy, sz, *spacing = data->GetSpacing();
  T *ptr;
  int *ext = data->GetExtent();
  nx = ext[1]-ext[0]+1;
  ny = ext[3]-ext[2]+1;
  nz = ext[5]-ext[4]+1;
  nxy = nx * ny;

  // Get spacing
  sx = 1.0 / (double)spacing[0];
  sy = 1.0 / (double)spacing[1];
  sz = 1.0 / (double)spacing[2];

  // Convert from RAS space (mm) to IJK space (indices)
  rasToIjk->RasToIjkTransformVector3(ras, ijk);
  x = ijk->GetElement(0);
  y = ijk->GetElement(1);
  z = ijk->GetElement(2);

  // Compute integer parts of volume coordinates
  xi = (int)x;
  yi = (int)y;
  zi = (int)z;

  // Test if coordinates are outside volume
  if ((xi < 0   ) || (yi < 0   ) || (zi < 0   ) ||
      (xi > nx-2) || (yi > ny-2) || (zi > nz-1))
  {
    // Out of bounds.
    //  DAVE: this happens a lot because coordinates are nx-1 or ny-1.
    //  It would be nice to avoid that, especially at lower resolutions.
    grad->Zero();
    *value = 0;
  }
  // Handle the case of being on the last slice
  else if (zi == nz-1)
  {
    x1 = x - (double)xi;
    y1 = y - (double)yi;
 
    x0 = 1.0 - x1;
    y0 = 1.0 - y1;

    // Get values of 4 nearest neighbors
    idx = zi*nxy + yi*nx + xi;
    ptr = &inPtr[idx];
    v000 = ptr[0];
    v100 = ptr[1]; ptr += nx;
    v010 = ptr[0];
    v110 = ptr[1];

    // Interpolate in X and Y at Z0
    dx0 = x0*v000 + x1*v100;
    dx1 = x0*v010 + x1*v110;
    *value = y0*dx0 + y1*dx1;
    
    // Gradient
    grad->SetElement(0, ((v100 - v000) + (v110 - v010)) * sx * 0.5);
    grad->SetElement(1, ((v010 - v000) + (v110 - v100)) * sy * 0.5);
    grad->SetElement(2, 0);
  }
  else 
  {
    x1 = x - (double)xi;
    y1 = y - (double)yi;
    z1 = z - (double)zi;
 
    x0 = 1.0 - x1;
    y0 = 1.0 - y1;
    z0 = 1.0 - z1;

    // Get values of 8 nearest neighbors
    idx = zi*nxy + yi*nx + xi;
    ptr = &inPtr[idx];
    v000 = ptr[0];
    v100 = ptr[1]; ptr += nx;
    v010 = ptr[0];
    v110 = ptr[1];
    ptr = &inPtr[idx + nxy];
    v001 = ptr[0];
    v101 = ptr[1]; ptr += nx;
    v011 = ptr[0];
    v111 = ptr[1];

    // Interpolate in X and Y at Z0
    dx0 = x0*v000 + x1*v100;
    dx1 = x0*v010 + x1*v110;
    dxy0 = y0*dx0 + y1*dx1;

    // Interpolate in X and Y at Z1
    dx0 = x0*v001 + x1*v101;
    dx1 = x0*v011 + x1*v111;
    dxy1 = y0*dx0 + y1*dx1;

    // Interpolate in Z
    *value = z0*dxy0 + z1*dxy1;

    // Gradient
    grad->SetElement(0, ((v100-v000)+(v110-v010)+(v101-v001)+(v111-v011))*sx*0.25);
    grad->SetElement(1, ((v010-v000)+(v110-v100)+(v101-v001)+(v111-v011))*sy*0.25);
    grad->SetElement(2, ((v001-v000)+(v101-v100)+(v011-v010)+(v111-v110))*sz*0.25);
  }
  ijk->Delete();
}

//----------------------------------------------------------------------------
// GetGradientAndInterpolation
//
// Computes the non-interpolated gradient (rasGrad) at an RAS point (ras)
// in an image (data) with an RasToIjk matrix.
// Returns the interpolated value at that point.
//----------------------------------------------------------------------------
double vtkImageMIReg::GetGradientAndInterpolation(vtkVector3 *rasGrad, 
    vtkImageData *data, vtkRasToIjkTransform *rasToIjk, vtkVector3 *ras)
{
  float *spacing = data->GetSpacing();
  void *inPtr = data->GetScalarPointer();
  double value=0;
  vtkVector3 *ijkGrad = vtkVector3::New();
  
  switch (data->GetScalarType()) {
    vtkTemplateMacro6(ImageGradientInterpolation, data, rasToIjk, ijkGrad, ras, 
      (VTK_TT *)inPtr, &value);
     default:
        vtkErrorMacro("Execute: Unknown ScalarType");
    }

  // Convert from IJK-gradient to RAS-gradient by permutation
  rasToIjk->IjkToRasGradient(rasGrad, ijkGrad);

  ijkGrad->Delete();
  return value;
}

//----------------------------------------------------------------------------
// Execute
//
// Finds the V(T(x)) associated with U(x).
// Effectively, consider T was applied to U to produce V.
// Therefore, apply inv(T) to V to align with U.
//
// This procedure computes T and returns its inverse.
//----------------------------------------------------------------------------
void vtkImageMIReg::Execute() 
{
  int i, j, i3, j3, res, SS = this->SampleSize, numIter=0;
  float inv_sigma_uu   = 1.0f / this->SigmaUU;
  float inv_sigma_vv   = 1.0f / this->SigmaVV;
  float inv_sigma_v    = 1.0f / this->SigmaV;
  float inv_sigma_v_2  = inv_sigma_v * inv_sigma_v;
  float inv_sigma_vv_2 = inv_sigma_vv * inv_sigma_vv;
  float pMin = this->PMin;
  float sum, denom, inv_denom;
  double left_part, lambda_d, lambda_r;
  vtkImageData *ref, *subj;
  vtkRasToIjkTransform* refRasToIjk;
  vtkRasToIjkTransform* subRasToIjk;
  vtkVector3 *dIdd, *dIdr, *d, *r;
  vtkQuaternion *q;
  vtkPose *delta;
  double *b, *didd, *didr;

  dIdd  = vtkVector3::New();
  dIdr  = vtkVector3::New();
  d     = vtkVector3::New();
  r     = vtkVector3::New();
  q     = vtkQuaternion::New();
  delta = vtkPose::New();

  //
  // Allocate workspace
  //
  vtkVector3*     B = vtkVector3::New();                   // Sample coordinates of ref (ijk)
  vtkVector3*     X = vtkVector3::New();                   // Sample coordinates of ref (xyz)
  vtkVector3*    Tx = vtkVector3::New();                // Transformed sample coordinates
  vtkVector3** dVdd = new vtkVector3*[SS];
  vtkVector3** dVdr = new vtkVector3*[SS];
  double*   dvdd = new double[SS*3];
  double*   dvdr = new double[SS*3];
  float*    U    = new float[SS];   // Sample data
  float*    V    = new float[SS];    
  float**   W_uv = new float*[SS]; 
  float**   W_v  = new float*[SS]; 
  for (i=0; i < SS; i++) 
  {
    dVdd[i] = vtkVector3::New();
    dVdr[i] = vtkVector3::New();
    W_uv[i] = new float[SS];
    W_v[i]  = new float[SS];
  }

  vtkMath::RandomSeed(time(NULL));

  // Foreach image resolution
  for (res=this->GetResolution(); res < 4; res++)
  {
    // Fetch params for this resolution
    lambda_d    = this->LambdaDisplacement[res];
    lambda_r    = this->LambdaRotation[res];
    ref         = this->Refs[res];
    subj        = this->Subs[res];
    refRasToIjk = this->RefRasToIjk[res];
    subRasToIjk = this->SubRasToIjk[res];

    // Iterate
    for (; this->CurIteration[res] < this->NumIterations[res] && 
        numIter < this->UpdateIterations; 
        numIter++, this->CurIteration[res]++) 
    {
        //
        // Do some O(n) stuff..
        //
        for (i=0; i < SS; i++) 
        {
            // Choose coordinates of samples at random. Expresses as voxel indices (ijk).
            RandomIjkCoordinate(B, ref);

            // Lookup scalar values of Reference at sample coordinates
            b = B->GetElements();
            U[i] = ref->GetScalarComponentAsFloat(b[0], b[1], b[2], 0);

            // Express coordinates in millimeter space (xyz).
            refRasToIjk->IjkToRasTransformVector3(B, X);

            // Transform the sample coordinates by the current pose
            this->CurrentPose->Transform(Tx, X);

            // Lookup scalar values of Subject at transformed sample coordinates
            // Lookup gradient of Subject at transformed sample coordinates.
            V[i] = (float)GetGradientAndInterpolation(dVdd[i], subj, subRasToIjk, Tx);

            // Pre-calculate the differential rotation increments
            //   dVdr = Tx x dVdd
            dVdr[i]->Cross(Tx, dVdd[i]);
        }

        //
        // Now, the O(n^2) stuff...
        // Calculate the weight matrices: W_v[i][j] and W_uv[i][j]
        // First, just fill them with the Gaussians...
        //
        for (i=0; i < SS; i++) 
        {
            for (j=0; j <= i; j++) 
            {
                W_v[i][j]  = W_v[j][i]  = qgauss(inv_sigma_v, V[i] - V[j]);

                W_uv[i][j] = W_uv[j][i] = qgauss(inv_sigma_uu, U[i] - U[j]) 
                * qgauss(inv_sigma_vv, V[i] - V[j]);
            }
        }

        // ...then, normalize them.
        for (i=0; i < SS; i++) 
        {
            // Normalize W_v
            sum=0;
            for (j=0; j < SS; j++) {
                sum += W_v[i][j];
            }
            denom = sum - W_v[i][i]; // Don't include W_v[i][i] which is a gaussian of zero
            inv_denom = 1.0f / (denom + pMin);
            for (j=0; j < SS; j++) {
                W_v[i][j] *= inv_denom;
            }

            // Normalize W_uv
            sum=0;
            for (j=0; j < SS; j++) {
                sum += W_uv[i][j];
            }
            denom = sum - W_uv[i][i];
            inv_denom = 1.0f / (denom + pMin);
            for (j=0; j < SS; j++) {
                W_uv[i][j] *= inv_denom;
            }
        }

        // Finally, calculate the transformation update.  First zero it,
        dIdd->Zero();
        dIdr->Zero();

        // The double-sum is where all the time is spent, so speed it up:
        didd = dIdd->GetElements();
        didr = dIdr->GetElements();
        for (i=0; i < SS; i++) {
            memcpy(&dvdd[i*3], dVdd[i]->GetElements(), 3*sizeof(double));
            memcpy(&dvdr[i*3], dVdr[i]->GetElements(), 3*sizeof(double));
        }

        // Next, accumulate the double sum:
        for (i=0; i < SS; i++) 
        {
            for (j=0; j < SS; j++) 
            {
                if (i != j) 
                {
                    left_part = (double)((V[i] - V[j]) * 
                    (inv_sigma_v_2 * W_v[i][j] - inv_sigma_vv_2 * W_uv[i][j]));

                    // The following block is a BIG speed-up of the next 2 lines.
                    // Using 1D arrays proved faster than 2D arrays.
                    // dIdd += (dVdd[i] - dVdd[j]) * left_part;
                    // dIdr += (dVdr[i] - dVdr[j]) * left_part;

                    i3 = i*3;
                    j3 = j*3;
                    didd[0] += (dvdd[i3+0] - dvdd[j3+0]) * left_part;
                    didd[1] += (dvdd[i3+1] - dvdd[j3+1]) * left_part;
                    didd[2] += (dvdd[i3+2] - dvdd[j3+2]) * left_part;

                    didr[0] += (dvdr[i3+0] - dvdr[j3+0]) * left_part;
                    didr[1] += (dvdr[i3+1] - dvdr[j3+1]) * left_part;
                    didr[2] += (dvdr[i3+2] - dvdr[j3+2]) * left_part;
                }
            }
        }

        // Then normalize it,
        dIdd->Multiply(1.0f / SS);
        dIdr->Multiply(1.0f / SS);

        //
        // Update the transform...
        //

        //  Calculate the small rotation and translation
        d->Copy(dIdd);
        d->Multiply(lambda_d);
        r->Copy(dIdr);
        r->Multiply(lambda_r);
    
        // Convert the small rotation to a quaternion
        // using small-angle linear approximation
        r->Multiply(0.5);
        q->Set(1.0, r);  
    
        // Compute the update for the big translation
        // and compound the small and large rotation quaternions
        // insuring that it doesn't drift from being a valid rotation
        delta->Set(q, d);
        this->CurrentPose->Concat(delta);
        this->CurrentPose->Normalize();
      }
  }

  // Are we there yet? (for good)
  if (this->CurIteration[3] >= this->NumIterations[3]) 
  {
    this->InProgress = 0;

    this->FinalPose->Copy(this->CurrentPose);
  }

  //
  // Cleanup
  //
  for (i=0; i < SS; i++) {
    delete [] W_uv[i];
    delete [] W_v[i];
    dVdd[i]->Delete();
    dVdr[i]->Delete();
  }
  dIdd->Delete();
  dIdr->Delete();
  d->Delete();
  r->Delete();
  q->Delete();
  delta->Delete();
  B->Delete();
  X->Delete();
  Tx->Delete();
  delete [] U;
  delete [] V;    
  delete [] dVdd;
  delete [] dVdr; 
  delete [] dvdd;
  delete [] dvdr;
  delete [] W_uv; 
  delete [] W_v; 
}

//----------------------------------------------------------------------------
// GetResolution
//
// Returns the index [0,3] of the resolution level we're currently at.
// If not InProgress, returns -1.
//----------------------------------------------------------------------------
int vtkImageMIReg::GetResolution()
{
  if (!this->InProgress) return -1;
  
  int i;
  for (i=0; i<3; i++) 
  {
    if (this->CurIteration[i] < this->NumIterations[i])
      break;
  }
  return i;
}

//----------------------------------------------------------------------------
// GetIteration
//
// Returns the current iteration number of the current resolution.
// Returns -1 if not InProgress.
//----------------------------------------------------------------------------
int vtkImageMIReg::GetIteration()
{
  if (!this->InProgress) return -1;
  
  return this->CurIteration[this->GetResolution()];
}

//----------------------------------------------------------------------------
// PrintSelf
//----------------------------------------------------------------------------
void vtkImageMIReg::PrintSelf(ostream& os, vtkIndent indent)
{
  // Images
  os << indent << "Reference:     " << this->Reference << "\n";
  if (this->Reference)
  {
    this->Reference->PrintSelf(os,indent.GetNextIndent());
  }
  os << indent << "Subject:     " << this->Subject << "\n";
  if (this->Subject)
  {
    this->Subject->PrintSelf(os,indent.GetNextIndent());
  }

  // Poses
  os << indent << "InitialPose:     " << this->InitialPose << "\n";
  if (this->InitialPose)
  {
    this->InitialPose->PrintSelf(os,indent.GetNextIndent());
  }
  os << indent << "FinalPose:     " << this->FinalPose << "\n";
  if (this->FinalPose)
  {
    this->FinalPose->PrintSelf(os,indent.GetNextIndent());
  }
  os << indent << "CurrentPose:     " << this->CurrentPose << "\n";
  if (this->CurrentPose)
  {
    this->CurrentPose->PrintSelf(os,indent.GetNextIndent());
  }
}


