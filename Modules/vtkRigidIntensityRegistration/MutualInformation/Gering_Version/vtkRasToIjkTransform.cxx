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

#include "vtkVersion.h"
#if (VTK_MAJOR_VERSION == 3 && VTK_MINOR_VERSION == 2)
#include "vtkCommand.h"
#endif
#include "vtkObjectFactory.h"
#include "vtkRasToIjkTransform.h"
#include "vtkMath.h"

//----------------------------------------------------------------------------
// New
//----------------------------------------------------------------------------
vtkRasToIjkTransform* vtkRasToIjkTransform::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkRasToIjkTransform");
  if(ret)
  {
    return (vtkRasToIjkTransform*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkRasToIjkTransform;
}

//----------------------------------------------------------------------------
vtkRasToIjkTransform::vtkRasToIjkTransform()
{
  this->SliceOrder = SLICE_ORDER_IS;
  
  memset(this->Extent,  0, 6*sizeof(int));
  memset(this->Spacing, 0, 3*sizeof(float));

  this->RasToIjk     = vtkMatrix4x4::New();
  this->IjkToRas     = vtkMatrix4x4::New();
  this->SlicerMatrix = vtkMatrix4x4::New();

  this->CnrFtl = vtkVector3::New();
  this->CnrFtr = vtkVector3::New();
  this->CnrFbr = vtkVector3::New();
  this->CnrLtl = vtkVector3::New();
}

//----------------------------------------------------------------------------
vtkRasToIjkTransform::~vtkRasToIjkTransform()
{
  if (this->RasToIjk) {
    this->RasToIjk->Delete();
  }
  if (this->IjkToRas) {
    this->IjkToRas->Delete();
  }
  if (this->SlicerMatrix) {
    this->SlicerMatrix->Delete();
  }

  if (this->CnrFtl) {
    this->CnrFtl->Delete();
  }
  if (this->CnrFtr) {
    this->CnrFtr->Delete();
  }
  if (this->CnrFbr) {
    this->CnrFbr->Delete();
  }
  if (this->CnrLtl) {
    this->CnrLtl->Delete();
  }
}

//------------------------------------------------------------------------
void vtkRasToIjkTransform::Copy(vtkRasToIjkTransform *t)
{
  this->SliceOrder = t->GetSliceOrder();
  
  memcpy(this->Extent,  t->GetExtent(), 6*sizeof(int));
  memcpy(this->Spacing, t->GetSpacing(), 3*sizeof(float));

  this->RasToIjk->DeepCopy(t->GetRasToIjk());
  this->IjkToRas->DeepCopy(t->GetIjkToRas());
  this->SlicerMatrix->DeepCopy(t->GetSlicerMatrix());

  this->CnrFtl->Copy(t->CnrFtl);
  this->CnrFtr->Copy(t->CnrFtr);
  this->CnrFbr->Copy(t->CnrFbr);
  this->CnrLtl->Copy(t->CnrLtl);
}

//------------------------------------------------------------------------
void vtkRasToIjkTransform::SetSliceOrderAsString(const char *s)
{
  if (!strcmp(s,"IS")) {
    this->SliceOrder = SLICE_ORDER_IS;
  } else if (!strcmp(s,"SI")) {
    this->SliceOrder = SLICE_ORDER_SI;
  } else if (!strcmp(s,"LR")) {
    this->SliceOrder = SLICE_ORDER_LR;
  } else if (!strcmp(s,"RL")) {
    this->SliceOrder = SLICE_ORDER_RL;
  } else if (!strcmp(s,"PA")) {
    this->SliceOrder = SLICE_ORDER_PA;
  } else if (!strcmp(s,"AP")) {
    this->SliceOrder = SLICE_ORDER_AP;
  } else {
    vtkErrorMacro(<<"Invalid Slice Order: "<<s);
  }
}

//------------------------------------------------------------------------
template <class T1, class T2, class T3>
inline void vtkRasToIjkTransformPoint(T1 m[4][4], 
                                           T2 in[3], T3 out[3])
{
  T3 x = m[0][0]*in[0] + m[0][1]*in[1] + m[0][2]*in[2] + m[0][3];
  T3 y = m[1][0]*in[0] + m[1][1]*in[1] + m[1][2]*in[2] + m[1][3];
  T3 z = m[2][0]*in[0] + m[2][1]*in[1] + m[2][2]*in[2] + m[2][3];

  out[0] = x;
  out[1] = y;
  out[2] = z;
}

//------------------------------------------------------------------------
void vtkRasToIjkTransform::RasToIjkTransformPoint(const float in[3], float out[3])
{
  vtkRasToIjkTransformPoint(this->RasToIjk->Element,in,out);
}
void vtkRasToIjkTransform::IjkToRasTransformPoint(const float in[3], float out[3])
{
  vtkRasToIjkTransformPoint(this->IjkToRas->Element,in,out);
}

//------------------------------------------------------------------------
void vtkRasToIjkTransform::RasToIjkTransformPoint(const double in[3], double out[3])
{
  vtkRasToIjkTransformPoint(this->RasToIjk->Element,in,out);
}
void vtkRasToIjkTransform::IjkToRasTransformPoint(const double in[3], double out[3])
{
  vtkRasToIjkTransformPoint(this->IjkToRas->Element,in,out);
}

//------------------------------------------------------------------------
void vtkRasToIjkTransform::RasToIjkTransformVector3(vtkVector3 *in, vtkVector3 *out)
{
  double in0, in1, in2;
  
  in0 = in->GetElement(0);
  in1 = in->GetElement(1);
  in2 = in->GetElement(2);
  
  out->SetElement(0, this->RasToIjk->Element[0][0]*in0 + this->RasToIjk->Element[0][1]*in1 + this->RasToIjk->Element[0][2]*in2 + this->RasToIjk->Element[0][3]);
  out->SetElement(1, this->RasToIjk->Element[1][0]*in0 + this->RasToIjk->Element[1][1]*in1 + this->RasToIjk->Element[1][2]*in2 + this->RasToIjk->Element[1][3]);
  out->SetElement(2, this->RasToIjk->Element[2][0]*in0 + this->RasToIjk->Element[2][1]*in1 + this->RasToIjk->Element[2][2]*in2 + this->RasToIjk->Element[2][3]);
}
void vtkRasToIjkTransform::IjkToRasTransformVector3(vtkVector3 *in, vtkVector3 *out)
{
  double in0, in1, in2;
  
  in0 = in->GetElement(0);
  in1 = in->GetElement(1);
  in2 = in->GetElement(2);
  
  out->SetElement(0, this->IjkToRas->Element[0][0]*in0 + this->IjkToRas->Element[0][1]*in1 + this->IjkToRas->Element[0][2]*in2 + this->IjkToRas->Element[0][3]);
  out->SetElement(1, this->IjkToRas->Element[1][0]*in0 + this->IjkToRas->Element[1][1]*in1 + this->IjkToRas->Element[1][2]*in2 + this->IjkToRas->Element[1][3]);
  out->SetElement(2, this->IjkToRas->Element[2][0]*in0 + this->IjkToRas->Element[2][1]*in1 + this->IjkToRas->Element[2][2]*in2 + this->IjkToRas->Element[2][3]);
}

//----------------------------------------------------------------------------
// SolveABeqCforA
//----------------------------------------------------------------------------
// This function solves the 4x4 matrix equation
// A*B=C for the unknown matrix A, given matrices B and C.
// While this is equivalent to A=C*Inverse(B), this function uses
// faster and more accurate methods (LU factorization) than finding a 
// matrix inverse and multiplying.  Returns 0 on failure.
//----------------------------------------------------------------------------
static int SolveABeqCforA(vtkMatrix4x4 *A, vtkMatrix4x4 *B, vtkMatrix4x4 *C)
{
  double *a[4],*ct[4];
  double ina[16],inct[16];
  int ret,i,j,index[4];
  for(i=0;i<4;i++)
  {
    a[i]=ina+4*i;
    ct[i]=inct+4*i;
    for(j=0;j<4;j++) 
    {
      a[i][j]=B->GetElement(j,i);
      ct[i][j]=C->GetElement(i,j);
    }
  }
  ret=vtkMath::LUFactorLinearSystem(a,index,4);
  if (ret)
  {
    for(i=0;i<4;i++)
      vtkMath::LUSolveLinearSystem(a,index,ct[i],4);
    for(i=0;i<4;i++)
      for(j=0;j<4;j++)
        A->SetElement(i,j,floor(ct[i][j]*1e10+0.5)*(1e-10)); 
  }
  return(ret);
}

//----------------------------------------------------------------------------
// ComputeTransforms
//
// Computes transforms from corner points. Solves the following equation:
//   RasToIjk * Ras = Ijk
//
// Assume corners in same format as given in GE MRI Signa headers.
// The corner points represent the outside corners of voxles in the X and Y 
// directions, but the centers of voxels in the Z direction.
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::ComputeTransforms()
{
  int i, *ext=this->GetExtent();
  double nx = (double)(ext[1]-ext[0]+1);
  double ny = (double)(ext[3]-ext[2]+1);
  double nz = (double)(ext[5]-ext[4]+1);
  float slThick = this->Spacing[2];
  vtkMatrix4x4 *Ijk  = vtkMatrix4x4::New();
  vtkMatrix4x4 *Ras  = vtkMatrix4x4::New();
  vtkVector3   *ltl  = vtkVector3::New();
  vtkVector3   *kDir = vtkVector3::New();
  vtkVector3   *iDir = vtkVector3::New();
  vtkVector3   *jDir = vtkVector3::New();

  // Force slice thickness
  if (slThick <= 0) {
    vtkErrorMacro(<< "Slice thickness must be positive");
    return;
  }

  // Special case for single slice
  kDir->Subtract(this->CnrLtl, this->CnrFtl);
  if (nz == 1 || kDir->Length() < 0.000001)
  {
    // Pretend it's 2 slices, and calculations below will be correct.
    //   iDir = CnrFtr - CnrFtl
    //   jDir = CnrFbr - CnrFtr
    //   kDir = iDir x jDir
    //   ltl  = CnrFtl + (kDir * slThick)
    nz = 2;
    iDir->Subtract(this->CnrFtr, this->CnrFtl);
    jDir->Subtract(this->CnrFbr, this->CnrFtr);
    kDir->Cross(iDir, jDir);
    kDir->Normalize();
    ltl->Copy(kDir);
    ltl->Multiply(slThick);
    ltl->Add(this->CnrFtl);
  } else {
    ltl->Copy(this->CnrLtl);
  }

  // Ras matrix = | |   |   |   |  |
  //              |ftl ftr fbr ltl |
  //              | |   |   |   |  |
  for (i=0; i<3; i++)
  {
    Ras->SetElement(i,0,this->CnrFtl->GetElement(i));
    Ras->SetElement(i,1,this->CnrFtr->GetElement(i));
    Ras->SetElement(i,2,this->CnrFbr->GetElement(i));
    Ras->SetElement(i,3,         ltl->GetElement(i));
  }
  for (i=0; i<4; i++) {
    Ras->SetElement(3,i,1);
  }

  // Ijk matrix = | |   |   |   |  |
  //              |ftl ftr fbr ltl |
  //              | |   |   |   |  |
  // Account for Y-axis being up instead of down because I
  // reverse rows in the ImageReader to be compatible with VTK.
  //
  // ftl in Ijk coordinates
  Ijk->SetElement(0,0,  -0.5);
  Ijk->SetElement(1,0,ny-0.5);  
  Ijk->SetElement(2,0,   0.0);
  Ijk->SetElement(3,0,1.0);  
  // ftr in Ijk coordinates
  Ijk->SetElement(0,1,nx-0.5);
  Ijk->SetElement(1,1,ny-0.5);
  Ijk->SetElement(2,1,   0.0);
  Ijk->SetElement(3,1,1.0);
  // fbr in Ijk coordinates
  Ijk->SetElement(0,2,nx-0.5);
  Ijk->SetElement(1,2,  -0.5);  
  Ijk->SetElement(2,2,   0.0);
  Ijk->SetElement(3,2,1.0);
  // ltl in Ijk coordinates
  Ijk->SetElement(0,3,  -0.5);
  Ijk->SetElement(1,3,ny-0.5);  
  Ijk->SetElement(2,3,nz-1.0);
  Ijk->SetElement(3,3,1.0);  

  // Solve RasToIjk * Ras = Ijk for RasToIjk
  SolveABeqCforA(this->RasToIjk, Ras, Ijk);
  SolveABeqCforA(this->IjkToRas, Ijk, Ras);

  // Cleanup
  Ijk->Delete();
  Ras->Delete();
  ltl->Delete();
  kDir->Delete();
  iDir->Delete();
  jDir->Delete();

  this->Modified();
}

//----------------------------------------------------------------------------
// ComputeCornersFromSlicerMatrix
//
// Computes transforms when corner points are not available.
// Call after any change to Extent, Spacing, or Matrix.
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::ComputeCornersFromSlicerMatrix()
{
  int *ext = this->GetExtent(), nx, ny, nz;
  nx = ext[1]-ext[0]+1;
  ny = ext[3]-ext[2]+1;
  nz = ext[5]-ext[4]+1;
  vtkVector3 *iftl = vtkVector3::New();
  vtkVector3 *iftr = vtkVector3::New();
  vtkVector3 *ifbr = vtkVector3::New();
  vtkVector3 *iltl = vtkVector3::New();
  vtkVector3 *ftl = vtkVector3::New();
  vtkVector3 *ftr = vtkVector3::New();
  vtkVector3 *fbr = vtkVector3::New();
  vtkVector3 *ltl = vtkVector3::New();

  // Define corner points in IJK space.
  // Points are at the voxel corners in X & Y, but voxel center in Z.
  iftl->SetElements( 0, ny,    0.5);
  iftr->SetElements(nx, ny,    0.5);
  ifbr->SetElements(nx,  0,    0.5);
  iltl->SetElements( 0, ny, nz-0.5);
  
  // Transform IJK points by the Slicer's IjkToRas matrix.
  this->RasToIjk->DeepCopy(this->SlicerMatrix);
  this->RasToIjk->Invert();
  this->RasToIjkTransformVector3(iftl, ftl);
  this->RasToIjkTransformVector3(iftr, ftr);
  this->RasToIjkTransformVector3(ifbr, fbr);
  this->RasToIjkTransformVector3(iltl, ltl);

  // Compute transforms based on RAS corner points.
  this->SetCorners(ftl, ftr, fbr, ltl);

  this->ComputeSliceOrder();

  iftl->Delete();
  iftr->Delete();
  ifbr->Delete();
  iltl->Delete();
  ftl->Delete();
  ftr->Delete();
  fbr->Delete();
  ltl->Delete();
}

//----------------------------------------------------------------------------
// ComputeSliceOrder
//
// Figure out scan direction description based on corner points. 
// If oblique, take best approximation.
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::ComputeSliceOrder()
{
  vtkVector3 *sliceDir = vtkVector3::New();
  double x, y, z;

  // Get scan direction vector
  sliceDir->Subtract(this->CnrLtl, this->CnrFtl);
  x = sliceDir->GetElement(0);
  y = sliceDir->GetElement(1);
  z = sliceDir->GetElement(2);

  if (fabs(x) >= fabs(y) && fabs(x) >= fabs(z))
  { 
    // Sagittal
    if (x >= 0.0) 
      this->SetSliceOrderToLR();
    else
      this->SetSliceOrderToRL();
  }
  else
  {
    if (fabs(y) >= fabs(x) && fabs(y) >= fabs(z))
    { 
      // Coronal
      if (y >= 0.0) 
        this->SetSliceOrderToPA();
      else 
        this->SetSliceOrderToAP();
    }
    else
    { 
      // Axial
      if (z >= 0.0) 
        this->SetSliceOrderToIS();
      else 
        this->SetSliceOrderToSI();      
    }
  }

  sliceDir->Delete();
}

//----------------------------------------------------------------------------
// ComputeCorners
//
// Computes transforms when corner points are not available.
// Call after any change to Extent, Spacing, or SliceOrder.
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::ComputeCorners()
{
  int *ext = this->GetExtent(), nx, ny, nz;
  double cnr[4][3], *ftl, *ftr, *fbr, *ltl, ctr[3], tmp;
  float *sp=this->Spacing;
  int i, c, sl=this->SliceOrder;
  nx = ext[1]-ext[0]+1;
  ny = ext[3]-ext[2]+1;
  nz = ext[5]-ext[4]+1;

  // Ensure slice has thickness
  if (sp[2] <= 0.f) {
    vtkErrorMacro(<<"Slice must have positive thickness.");
    return;
  }

  // Initialize for storing a corner point in each row of cnr
  memset(cnr, 0, 12*sizeof(double));
  ftl = cnr[0];
  ftr = cnr[1];
  fbr = cnr[2];
  ltl = cnr[3];

  // Compute XYZ from IJK.
  // Note: IJK coords are 0-based array indices, not the extent.

  // Apply Spacing
  ftr[0] = (double) nx    * (double)sp[0]; // voxel corners in X direction
  fbr[0] = ftr[0];
  fbr[1] = (double) ny    * (double)sp[1]; // voxel corners in Y direction
  ltl[2] = (double)(nz-1) * (double)sp[2]; // voxel centers in Z direction

  // Computing RAS from XYZ

  // Apply slice order
  if (sl == SLICE_ORDER_SI || sl == SLICE_ORDER_RL || sl == SLICE_ORDER_AP)
    ltl[2] = -ltl[2];

  // Center the volume midway between opposite corners
  for (i=0; i<3; i++) 
  {
    ctr[i] = (fbr[i] + ltl[i]) * 0.5f;

    for (c=0; c<4; c++)
      cnr[c][i] -= ctr[i];
  }

  // Apply slice orientation
  if (sl == SLICE_ORDER_SI || sl == SLICE_ORDER_IS)
  {
    // Axial: (r,a,s) = (-x,-y,z)
    for (c=0; c<4; c++) {
      cnr[c][0] = -cnr[c][0]; // Send  -x to x
      cnr[c][1] = -cnr[c][1]; // Send  -y to y
    }
  }
  else if (sl == SLICE_ORDER_LR || sl == SLICE_ORDER_RL)
  {
    // Saggital: (r,a,s) = (z,-x,-y)
    for (c=0; c<4; c++) {
      tmp       = -cnr[c][0]; // Send  -x to tmp
      cnr[c][0] =  cnr[c][2]; // Send   z to x
      cnr[c][2] = -cnr[c][1]; // Send  -y to z
      cnr[c][1] =  tmp      ; // Send tmp to y
    }
  }
  else
  {
    // Coronal: (r,a,s) = (-x,z,-y)
    for (c=0; c<4; c++) {
      cnr[c][0] = -cnr[c][0]; // Send  -x to x
      tmp       =  cnr[c][2]; // Send   z to tmp
      cnr[c][2] = -cnr[c][1]; // Send  -y to z
      cnr[c][1] =  tmp      ; // Send tmp to y
    }
  }

  // Compute transforms based on corner points.
  this->SetCorners(ftl, ftr, fbr, ltl);
}

//----------------------------------------------------------------------------
// SetCorners
//
// Provide corners in same format as given in GE MRI Signa headers.
// The corner points represent the outside corners of voxles in the X and Y 
// directions, but the centers of voxels in the Z direction.
// The X-axis points Left-to-Right, but the Y-axis points Up-to-Down.
//
// ftl = First Top    Left (first meaning first slice)
// ftr = First Top    Right
// fbr = First Bottom Right
// ltl = Last  Top    Left
//
// Calls ComputeTransforms()
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::SetCorners(vtkVector3 *ftl, vtkVector3 *ftr, 
                                      vtkVector3 *fbr, vtkVector3 *ltl)
{
  this->CnrFtl->Copy(ftl);
  this->CnrFtr->Copy(ftr);
  this->CnrFbr->Copy(fbr);
  this->CnrLtl->Copy(ltl);
  
  this->ComputeSliceOrder();
  this->ComputeTransforms();
}

void vtkRasToIjkTransform::SetCorners(double *ftl, double *ftr, double *fbr,
                                  double *ltl)
{
  vtkVector3 *vftl = vtkVector3::New();
  vtkVector3 *vftr = vtkVector3::New();
  vtkVector3 *vfbr = vtkVector3::New();
  vtkVector3 *vltl = vtkVector3::New();

  vftl->SetElements(ftl[0], ftl[1], ftl[2]);
  vftr->SetElements(ftr[0], ftr[1], ftr[2]);
  vfbr->SetElements(fbr[0], fbr[1], fbr[2]);
  vltl->SetElements(ltl[0], ltl[1], ltl[2]);

  this->SetCorners(vftl, vftr, vfbr, vltl);

  vftl->Delete();
  vftr->Delete();
  vfbr->Delete();
  vltl->Delete();
}

//----------------------------------------------------------------------------
// GetCorners
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::GetCorners(vtkVector3 *ftl, vtkVector3 *ftr, 
                                      vtkVector3 *fbr, vtkVector3 *ltl)
{
  ftl->Copy(this->CnrFtl);
  ftr->Copy(this->CnrFtr);
  fbr->Copy(this->CnrFbr);
  ltl->Copy(this->CnrLtl);
}

//----------------------------------------------------------------------------
// IjkToRasGradient
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::IjkToRasGradient(vtkVector3 *Ras, vtkVector3 *Ijk)
{
  int sl=this->SliceOrder;
  double *ras = Ras->GetElements();
  double *ijk = Ijk->GetElements();

  /* NOTE: the following would be the code if the y-axis were down:

  // Apply slice orientation
  if (sl == SLICE_ORDER_SI || sl == SLICE_ORDER_IS)
  {
    // Axial: (r,a,s) = (-x,-y,z)
    ras[0] = -ijk[0];
    ras[1] = -ijk[1];
    ras[2] =  ijk[2];
  }
  else if (sl == SLICE_ORDER_LR || sl == SLICE_ORDER_RL)
  {
    // Saggital: (r,a,s) = (z,-x,-y)
    ras[0] =  ijk[2]; // Send  z to x
    ras[1] = -ijk[0]; // Send -x to y
    ras[2] = -ijk[1]; // Send -y to z
  }
  else
  {
    // Coronal: (r,a,s) = (-x,z,-y)
    ras[0] = -ijk[0]; // Send -x to x
    ras[1] =  ijk[2]; // Send  z to y
    ras[2] = -ijk[1]; // Send -y to z
  }
  */
  // Apply slice orientation
  if (sl == SLICE_ORDER_SI || sl == SLICE_ORDER_IS)
  {
    // Axial: (r,a,s) = (-x,y,z)
    ras[0] = -ijk[0];
    ras[1] =  ijk[1];
    ras[2] =  ijk[2];
  }
  else if (sl == SLICE_ORDER_LR || sl == SLICE_ORDER_RL)
  {
    // Saggital: (r,a,s) = (z,-x,y)
    ras[0] =  ijk[2]; // Send  z to x
    ras[1] = -ijk[0]; // Send -x to y
    ras[2] =  ijk[1]; // Send  y to z
  }
  else
  {
    // Coronal: (r,a,s) = (-x,z,y)
    ras[0] = -ijk[0]; // Send -x to x
    ras[1] =  ijk[2]; // Send  z to y
    ras[2] =  ijk[1]; // Send  y to z
  }
}
  
//----------------------------------------------------------------------------
void vtkRasToIjkTransform::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkObject::PrintSelf(os, indent);

  // SlicerMatrix
  os << indent << "SlicerMatrix: (" << this->SlicerMatrix << ")\n";
  if (this->SlicerMatrix) {
    this->SlicerMatrix->PrintSelf(os, indent.GetNextIndent());
  }

  // RasToIjk
  os << indent << "RasToIjk: (" << this->RasToIjk << ")\n";
  if (this->RasToIjk) {
    this->RasToIjk->PrintSelf(os, indent.GetNextIndent());
  }

  // IjkToRas
  os << indent << "IjkToRas: (" << this->IjkToRas << ")\n";
  if (this->IjkToRas) {
    this->IjkToRas->PrintSelf(os, indent.GetNextIndent());
  }
}

//----------------------------------------------------------------------------
void vtkRasToIjkTransform::Dump()
{
  char s[100];
  int i;

  this->Print("SlicerMatrix:");
  for (i = 0; i < 4; i++) 
  {
    sprintf(s, "%6.2f, %6.2f, %6.2f, %6.2f", 
      this->SlicerMatrix->Element[i][0],
      this->SlicerMatrix->Element[i][1],
      this->SlicerMatrix->Element[i][2],
      this->SlicerMatrix->Element[i][3]);
    this->Print(s);
  }

  this->Print("RasToIjk:");
  for (i = 0; i < 4; i++) 
  {
    sprintf(s, "%6.2f, %6.2f, %6.2f, %6.2f", 
      this->RasToIjk->Element[i][0],
      this->RasToIjk->Element[i][1],
      this->RasToIjk->Element[i][2],
      this->RasToIjk->Element[i][3]);
    this->Print(s);
  }

  this->Print("IjkToRas:");
  for (i = 0; i < 4; i++) 
  {
    sprintf(s, "%6.2f, %6.2f, %6.2f, %6.2f", 
      this->IjkToRas->Element[i][0],
      this->IjkToRas->Element[i][1],
      this->IjkToRas->Element[i][2],
      this->IjkToRas->Element[i][3]);
    this->Print(s);
  }
}

//----------------------------------------------------------------------------
void vtkRasToIjkTransform::Print(const char *x)
{
  char *msgbuff; 
  ostrstream msg;
  msg << "<p><font color=blue>" __FILE__ "</font>, line <font color=blue>" << __LINE__ << "</font><br>" << x << ends;
  msgbuff = msg.str();
  ofstream file;
  file.open("debug.html", ios::app);
  if (file.fail()) {;} else {file << msgbuff;}
  file.close();
  msg.rdbuf()->freeze(0);
}
