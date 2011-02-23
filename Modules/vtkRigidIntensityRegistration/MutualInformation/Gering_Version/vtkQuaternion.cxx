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
#include "vtkQuaternion.h"

//----------------------------------------------------------------------------
// New
//----------------------------------------------------------------------------
vtkQuaternion* vtkQuaternion::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkQuaternion");
  if(ret)
  {
    return (vtkQuaternion*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkQuaternion;
}

//----------------------------------------------------------------------------
// Constructor
//----------------------------------------------------------------------------
vtkQuaternion::vtkQuaternion() 
{
  this->Identity();
}

//----------------------------------------------------------------------------
// GetElements
//----------------------------------------------------------------------------
double *vtkQuaternion::GetElements() 
{
  return this->Element;
}

//----------------------------------------------------------------------------
// GetElement
//----------------------------------------------------------------------------
double vtkQuaternion::GetElement(int y) 
{
  return this->Element[y];
}

//----------------------------------------------------------------------------
// GetScalar
//----------------------------------------------------------------------------
double vtkQuaternion::GetScalar() 
{
  return this->Element[0];
}

//----------------------------------------------------------------------------
// GetVector
//----------------------------------------------------------------------------
void vtkQuaternion::GetVector(vtkVector3 *v) 
{
  v->SetElement(0, this->Element[1]);
  v->SetElement(1, this->Element[2]);
  v->SetElement(2, this->Element[3]);
}

//----------------------------------------------------------------------------
// GetRotationAngle
//----------------------------------------------------------------------------
double vtkQuaternion::GetRotationAngle() 
{
  return 2.0 * acos(this->GetScalar());
}

//----------------------------------------------------------------------------
// GetRotationAxis
//----------------------------------------------------------------------------
void vtkQuaternion::GetRotationAxis(vtkVector3 *v) 
{
  this->GetVector(v);
  v->Normalize();
}

//----------------------------------------------------------------------------
// Copy
//----------------------------------------------------------------------------
void vtkQuaternion::Copy(vtkQuaternion *q) 
{
  // Check not in place
  if (this == q) {
    vtkErrorMacro(<<"Can't copy self!"); return;
  }

  // Copy if differ
  if (this->Element[0] != q->Element[0] || this->Element[1] != q->Element[1] 
   || this->Element[2] != q->Element[2] || this->Element[3] != q->Element[3])
  {
    memcpy(this->Element, q->Element, 4*sizeof(double));
    this->Modified();
  }
}
  
//----------------------------------------------------------------------------
// SetElement
//----------------------------------------------------------------------------
void vtkQuaternion::SetElement(int y, double v) 
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
void vtkQuaternion::SetElements(double s, double x, double y, double z)
{
  if (this->Element[0] != s || this->Element[1] != x
   || this->Element[2] != y || this->Element[3] != z)
  {
    this->Element[0] = s;
    this->Element[1] = x;
    this->Element[2] = y;
    this->Element[3] = z;
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// SetElements
//----------------------------------------------------------------------------
void vtkQuaternion::Set(double s, vtkVector3 *v)
{
  if (this->Element[0] != s || this->Element[1] != v->GetElement(0)
   || this->Element[2] != v->GetElement(1) || this->Element[3] != v->GetElement(2))
  {
    this->Element[0] = s;
    memcpy(&this->Element[1], v->GetElements(), 3*sizeof(double));
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// Zero
//----------------------------------------------------------------------------
void vtkQuaternion::Zero() 
{
  if (this->Element[0] != 0 || this->Element[1] != 0
   || this->Element[2] != 0 || this->Element[3] != 0)
  {
    memset(this->Element, 0, 4*sizeof(double));
    this->Modified();
  }
}

//----------------------------------------------------------------------------
// Identity
//
// q = (1,0)
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Identity() 
{
  this->Element[0] = 1.0;
  memset(&this->Element[1], 0, 3*sizeof(double));
  this->Modified();
}

//----------------------------------------------------------------------------
// SetRotation
//
// A rotation by angle, a, about any axis, u, passing throught the origin is 
// performed by setting a unit quaternion with these scalar and vector parts:
//   s = cos(a/2)
//   v = sin(a/2) * u
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 419. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::SetRotation(vtkVector3 *u, double a) 
{
  if (fabs(a) > VECTOR3_EPSILON) 
  {
    vtkVector3 *v = vtkVector3::New();
    v->Copy(u);
    this->Element[0] = cos((a/2.0));
    v->Normalize();
    v->Multiply(sin(a/2.0));
    memcpy(&this->Element[1], v->GetElements(), 3*sizeof(double));
    v->Delete();
    this->Modified();
  } else 
  {
    this->Identity();
  }
}

//----------------------------------------------------------------------------
// Length
//
// |q|^2 = s^2 + v*v
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
double vtkQuaternion::Length() 
{
  double sum=0;
  for (int y=0; y<4; y++) {
    sum += this->Element[y] * this->Element[y];
  }
  return sqrt(sum);
}

//----------------------------------------------------------------------------
// Normalize
//
// This insures that the magnitude is one, and that the real
// part isn't negative.
//----------------------------------------------------------------------------
void vtkQuaternion::Normalize() 
{
  double len = this->Length();
  if (this->Element[0] < 0) {
    len = -len;
  }

  if (len < VECTOR3_EPSILON) {
    this->Identity(); 
    return;
  }
    
  for (int y=0; y<4; y++) {
    this->Element[y] /= len;
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Invert
//
// inv(q) = 1/|q|^2 (s, -v)
//
// So that: q*inv(q) = inv(q)*q = (1,0)
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Invert(vtkQuaternion *Q) 
{
  double d = Q->Length();
  d *= d;
  if (d < VECTOR3_EPSILON) {
    this->Identity(); 
    return;
  }

  this->Element[0] =  Q->GetElement(0) / d;
  this->Element[1] = -Q->GetElement(1) / d;
  this->Element[2] = -Q->GetElement(2) / d;
  this->Element[3] = -Q->GetElement(3) / d;
  this->Modified();
}

//----------------------------------------------------------------------------
// Invert
//
// vtkQuaternion becomes inverse of itself.
//----------------------------------------------------------------------------
void vtkQuaternion::Invert()
{
  vtkQuaternion *q = vtkQuaternion::New();
  q->Invert(this);
  this->Copy(q);
  q->Delete();
  this->Modified();
}

//----------------------------------------------------------------------------
// Rotate
//
// Rotate point, p, by this quaternion to compute point r.
// Express points as quaternions with zero scalar part, so that P = (0,p).
// Then:
//   R = q * P * inv(q)
//
// Suppose we wish to apply 2 rotations: q1 followed by q2. Then:
//   R = q2 * (q1 * P * inv(q1)) * inv(q2)
//     = (q2*q1) * P * inv(q2*q1)
// Therefore, first call q.Multiply(q2. q1)
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 419. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Rotate(vtkVector3 *r, vtkVector3 *p)
{
  vtkQuaternion *P    = vtkQuaternion::New();
  vtkQuaternion *R    = vtkQuaternion::New();
  vtkQuaternion *qInv = vtkQuaternion::New();

  P->Set(0,p);
  qInv->Invert(this);
  R->Multiply(this, P);
  R->Multiply(qInv);
  R->GetVector(r);

  P->Delete();
  R->Delete();
  qInv->Delete();
  this->Modified();
}

//----------------------------------------------------------------------------
// Multiply
//
// Each component is multiplied by the scalar value, s.
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Multiply(double s)
{
  for (int y=0; y<4; y++) {
    this->Element[y] *= s;
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// Multiply
//
// Express quaternions in ordered-pair notation: 
//   q = (s,v)
// Then, using dot and cross products:
//   q1 * q2 = (s1,v2)*(s2,v2)
//           = (s1*s2 - v1*v2, s1*v2 + s2*v1 + v1 x v2)
//           = (s1*s2 - x1*x2 - y1*y2 - z1*z2)  + 
//             (s1*x2 + x1*s2 + y1*z2 - z1*y2)i +
//             (s1*y2 - x1*z2 + y1*w2 + z1*x2)j + 
//             (s1*z2 + x1*y2 - y1*x2 + z1*s2)k
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Multiply(vtkQuaternion *Q1, vtkQuaternion *Q2)
{
  double *q  = this->Element;
  double *q1 = Q1->GetElements();
  double *q2 = Q2->GetElements();

  // S 0
  // X 1
  // Y 2
  // Z 3

  q[0] = q1[0]*q2[0] - q1[1]*q2[1] - q1[2]*q2[2] - q1[3]*q2[3];
  q[1] = q1[0]*q2[1] + q1[1]*q2[0] + q1[2]*q2[3] - q1[3]*q2[2];
  q[2] = q1[0]*q2[2] - q1[1]*q2[3] + q1[2]*q2[0] + q1[3]*q2[1];
  q[3] = q1[0]*q2[3] + q1[1]*q2[2] - q1[2]*q2[1] + q1[3]*q2[0];
  this->Modified();
}

//----------------------------------------------------------------------------
// Multiply
//
// this = this * q
//----------------------------------------------------------------------------
void vtkQuaternion::Multiply(vtkQuaternion *Q2)
{
  vtkQuaternion *Q1 = vtkQuaternion::New();
  Q1->Copy(this);
  this->Multiply(Q1, Q2);
  Q1->Delete();
  this->Modified();
}

//----------------------------------------------------------------------------
// Add
//
// Add quaternion, q, to this one componentwise:
//   q1 + q2 = (s1 + s2) + i(a1 + a2) + j(b1 + b2) + k(c1 + c2)
//
// Reference:
//  D. Hearn, M.P. Baker, "Computer Graphics", page 618. 1997.
//----------------------------------------------------------------------------
void vtkQuaternion::Add(vtkQuaternion *q)
{
  for (int y=0; y<4; y++) {
    this->Element[y] += q->GetElement(y);
  }
  this->Modified();
}

//----------------------------------------------------------------------------
// PrintSelf
//----------------------------------------------------------------------------
void vtkQuaternion::PrintSelf(ostream& os, vtkIndent indent)
{
  int i;
  os << indent << "Elements: (r i j k)" << "\n";
  for (i=0; i<4; i++) {
    os << indent << this->Element[i] << "\n";
  }
}
