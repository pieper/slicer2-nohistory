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
#include "vtkVector3.h"

//----------------------------------------------------------------------------
// New
//----------------------------------------------------------------------------
vtkVector3* vtkVector3::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkVector3");
  if(ret)
  {
    return (vtkVector3*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkVector3;
}

//----------------------------------------------------------------------------
// Constructor
//----------------------------------------------------------------------------
vtkVector3::vtkVector3() 
{
  this->Zero();
}

//----------------------------------------------------------------------------
// GetElement
//----------------------------------------------------------------------------
double vtkVector3::GetElement(int y) 
{
  return this->Element[y];
}

//----------------------------------------------------------------------------
// Copy
//----------------------------------------------------------------------------
void vtkVector3::Copy(vtkVector3 *v) 
{
  // Check not in place
  if (this == v) {
    vtkErrorMacro(<<"Can't copy self!"); return;
  }

  // Copy if differ
  if (this->Element[0] != v->Element[0] || this->Element[1] != v->Element[1] 
    || this->Element[2] != v->Element[2])
  {
    memcpy(this->Element, v->Element, 3*sizeof(double));
    this->Modified();
  }
}
  
//----------------------------------------------------------------------------
// SetElement
//----------------------------------------------------------------------------
void vtkVector3::SetElement(int y, double v) 
{
  if (this->Element[y] != v)
  {
    this->Element[y] = v;
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// SetElements
//----------------------------------------------------------------------------
void vtkVector3::SetElements(double x, double y, double z)
{
  if (this->Element[0] != x || this->Element[1] != y || this->Element[2] != z)
  {
    this->Element[0] = x;
    this->Element[1] = y;
    this->Element[2] = z;
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// Zero
//----------------------------------------------------------------------------
void vtkVector3::Zero() 
{
  if (this->Element[0] != 0 || this->Element[1] != 0 || this->Element[2] != 0)
  {
    memset(this->Element, 0, 3*sizeof(double));
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// Length
//----------------------------------------------------------------------------
double vtkVector3::Length() 
{
  return (double)sqrt((double)this->Dot(this));
}

//----------------------------------------------------------------------------
// Normalize
//----------------------------------------------------------------------------
void vtkVector3::Normalize() 
{
  double len = this->Length();
  if (len < VECTOR3_EPSILON) {
    this->Zero();
    return;
  }
    
  for (int y=0; y<3; y++) {
    this->Element[y] /= len;
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Invert
//
// Negate all components so that:
//   v + inv(v) = 0
//----------------------------------------------------------------------------
void vtkVector3::Invert() 
{
  for (int y=0; y<3; y++) {
    this->Element[y] *= -1;
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Add
//----------------------------------------------------------------------------
void vtkVector3::Add(double s) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] += s;
  }
}

//----------------------------------------------------------------------------
// Add
//----------------------------------------------------------------------------
void vtkVector3::Add(vtkVector3 *v) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] += v->Element[y];
  }
  this->Modified();
}

void vtkVector3::Add(vtkVector3 *A, vtkVector3 *B) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] = A->Element[y] + B->Element[y];
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Subtract
//----------------------------------------------------------------------------
void vtkVector3::Subtract(vtkVector3 *v) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] -= v->Element[y];
  }
  this->Modified();
}

void vtkVector3::Subtract(vtkVector3 *A, vtkVector3 *B) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] = A->Element[y] - B->Element[y];
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Multiply
//----------------------------------------------------------------------------
void vtkVector3::Multiply(double s) 
{
  for (int y=0; y<3; y++) {
    this->Element[y] *= s;
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Dot
//----------------------------------------------------------------------------
double vtkVector3::Dot(vtkVector3 *v) 
{
  double sum=0;
  
  for (int y=0; y<3; y++) {
    sum += this->Element[y]*v->Element[y];
  }
  return sum;
}

//----------------------------------------------------------------------------
// Cross
//----------------------------------------------------------------------------
void vtkVector3::Cross(vtkVector3 *A, vtkVector3 *B) 
{  
  double *a = A->GetElements();
  double *b = B->GetElements();
  double *c = this->GetElements();

  c[0] = a[1]*b[2] - a[2]*b[1];
  c[1] = a[2]*b[0] - a[0]*b[2];
  c[2] = a[0]*b[1] - a[1]*b[0];
  this->Modified();
}

//----------------------------------------------------------------------------
// PrintSelf
//----------------------------------------------------------------------------
void vtkVector3::PrintSelf(ostream& os, vtkIndent indent)
{
  int i;
  os << indent << "Elements:" << "\n";
  for (i=0; i<3; i++) {
    os << indent << this->Element[i] << "\n";
  }
}
