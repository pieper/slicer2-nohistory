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
#include "vtkPose.h"

//----------------------------------------------------------------------------
// New
//----------------------------------------------------------------------------
vtkPose* vtkPose::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPose");
  if(ret)
  {
    return (vtkPose*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkPose;
}

//----------------------------------------------------------------------------
// Constructor/Destructor
//----------------------------------------------------------------------------
vtkPose::vtkPose() 
{
  this->Translation = vtkVector3::New();
  this->Rotation    = vtkQuaternion::New();
  this->Identity();
}
vtkPose::~vtkPose() 
{
  this->Translation->Delete();
  this->Rotation->Delete();
}

//----------------------------------------------------------------------------
// Copy
//----------------------------------------------------------------------------
void vtkPose::Copy(vtkPose *p) 
{
  // Check not in place
  if (this == p) {
    vtkErrorMacro(<<"Can't copy self!"); return;
  }
  this->Translation->Copy(p->GetTranslation());
  this->Rotation->Copy(p->GetRotation());
  this->Modified();
}
  
//----------------------------------------------------------------------------
// Identity
//----------------------------------------------------------------------------
void vtkPose::Identity() 
{
  this->Translation->Zero();
  this->Rotation->Identity();
  this->Modified();
}

//----------------------------------------------------------------------------
// Normalize
//
// Ensure that the rotation is legal (normalize the quaternion).
//----------------------------------------------------------------------------
void vtkPose::Normalize() 
{
  this->Rotation->Normalize();
  this->Modified();
}

//----------------------------------------------------------------------------
// Invert
//
// r2 = inv(r)
// t2 = inv(r2 * t)
//
// So that: p*inv(p) = inv(p)*p = identity(p) = [(0,0,0), (1,0,0,0)]
//----------------------------------------------------------------------------
void vtkPose::Invert(vtkPose *p) 
{
  // Invert the rotation
  this->Rotation->Invert(p->GetRotation());
  
  // Invert the translation
  this->Rotation->Rotate(this->Translation, p->GetTranslation());
  this->Translation->Invert();
  this->Modified();
}

//----------------------------------------------------------------------------
// Invert
//----------------------------------------------------------------------------
void vtkPose::Invert()
{
  vtkPose *p = vtkPose::New();
  p->Invert(this);
  this->Copy(p);
  p->Delete();
  this->Modified();
}

//----------------------------------------------------------------------------
// Transform
//
// Transforms point, p, to compute point, r.
// Rotate, then translate:
//   r = q * p + t
//----------------------------------------------------------------------------
void vtkPose::Transform(vtkVector3 *r, vtkVector3 *p)
{
  this->Rotation->Rotate(r, p);
  r->Add(this->Translation);
}

//----------------------------------------------------------------------------
// Concat
//
// Set the pose to be the concatenation of poses: perform p1 first, then p2.
//
// Concatenate rotations by multiplication, translations by addition:
//
// t = concat(r2*t1, t2) = r2*t1 + t2
// r = concat(r1   , r2) = r2 * r1
//
// (See comments on Quaternion::Multiply for why it's r2*r1 instead of r1*r2.)
//----------------------------------------------------------------------------
void vtkPose::Concat(vtkPose *p1, vtkPose *p2)
{
  vtkQuaternion *r1 = p1->GetRotation();
  vtkQuaternion *r2 = p2->GetRotation();
  vtkQuaternion *r  = this->GetRotation();
  vtkVector3    *t1 = p1->GetTranslation();
  vtkVector3    *t2 = p2->GetTranslation();
  vtkVector3    *t  = this->GetTranslation();

  // Translation
  r2->Rotate(t, t1);
  t->Add(t2);

  // Rotation
  r->Multiply(r2, r1);

  this->Modified();
}

//----------------------------------------------------------------------------
// Concat
//
// this = this * p2
//----------------------------------------------------------------------------
void vtkPose::Concat(vtkPose *p2)
{
  vtkPose *p1 = vtkPose::New();
  p1->Copy(this);
  this->Concat(p1, p2);
  p1->Delete();
  this->Modified();
}

//----------------------------------------------------------------------------
// ConvertToMatrix4x4
//
// Compute a 3x3 orthogonal rotation matrix by rotating each of the 3 standard
// basis vectors by the quaternion. The matrix's column space is defined by
// the 3 rotated basis vectors.
//----------------------------------------------------------------------------
void vtkPose::ConvertToMatrix4x4(vtkMatrix4x4 *m)
{
  vtkVector3 *x  = vtkVector3::New();
  vtkVector3 *y  = vtkVector3::New();
  vtkVector3 *z  = vtkVector3::New();
  vtkVector3 *xr = vtkVector3::New();
  vtkVector3 *yr = vtkVector3::New();
  vtkVector3 *zr = vtkVector3::New();
  vtkVector3 *t  = this->Translation;

  // Create the columns of the 3x3 rotation matrix.
  x->XHat();
  y->YHat();
  z->ZHat();
  this->Rotation->Rotate(xr, x);
  this->Rotation->Rotate(yr, y);
  this->Rotation->Rotate(zr, z);
  
  // Copy the 3 rotation columns, and the translation, into the vtkMatrix4x4.
  // (index i goes down the rows)
  for (int i=0; i<3; i++) 
  {
    m->SetElement(i, 0, xr->GetElement(i));
    m->SetElement(i, 1, yr->GetElement(i));
    m->SetElement(i, 2, zr->GetElement(i));
    m->SetElement(i, 3,  t->GetElement(i));
  }
  // Set the bottom row
  m->SetElement(3,0,0);
  m->SetElement(3,1,0);
  m->SetElement(3,2,0);
  m->SetElement(3,3,1);

  x->Delete();
  y->Delete();
  z->Delete();
  xr->Delete();
  yr->Delete();
  zr->Delete();
  // Don't delete t
}

//----------------------------------------------------------------------------
// ConvertFromMatrix4x4
//
// Thanks BKPH 
//
// Reference:
//   B.K.P. Horn, "Closed-form solution of absolute orientation using unit 
//   quaternions", J. Opt. Soc. Am. Vol 4, pp 629, April 1987
//----------------------------------------------------------------------------
void vtkPose::ConvertFromMatrix4x4(vtkMatrix4x4 *m)
{
#define FOUR 4.0
#define TWO  2.0
  
  // Rotation:
  // Notation: r<row><column>
  double r11 = m->GetElement(0,0);
  double r12 = m->GetElement(0,1);
  double r13 = m->GetElement(0,2);
              
  double r21 = m->GetElement(1,0);
  double r22 = m->GetElement(1,1);
  double r23 = m->GetElement(1,2);
            
  double r31 = m->GetElement(2,0);
  double r32 = m->GetElement(2,1);
  double r33 = m->GetElement(2,2);

  double d0 = 1.0 + r11 + r22 + r33;
  double d1 = 1.0 + r11 - r22 - r33;
  double d2 = 1.0 - r11 + r22 - r33;
  double d3 = 1.0 - r11 - r22 + r33;

  int case_number = 0;
  double biggest = d0;
  if (d1 > biggest) {
    case_number = 1;
    biggest = d1;
  }
  if (d2 > biggest) {
    case_number = 2;
    biggest = d2;
  }
  if (d3 > biggest) {
    case_number = 3;
    biggest = d3;
  }
  
  double q0, qx, qy, qz;

  switch (case_number) {
  case 0:
    q0 = sqrt(d0) / TWO;
    qx = (r32 - r23) / (FOUR * q0);
    qy = (r13 - r31) / (FOUR * q0);
    qz = (r21 - r12) / (FOUR * q0);
    break;
  case 1:
    qx = sqrt(d1) / TWO;
    q0 = (r32 - r23) / (FOUR * qx);
    qy = (r21 + r12) / (FOUR * qx);
    qz = (r13 + r31) / (FOUR * qx);
    break;
  case 2:
    qy = sqrt(d2) / TWO;
    q0 = (r13 - r31) / (FOUR * qy);
    qx = (r21 + r12) / (FOUR * qy);
    qz = (r32 + r23) / (FOUR * qy);
    break;
  case 3:
    qz = sqrt(d3) / TWO;
    q0 = (r21 - r12) / (FOUR * qz);
    qx = (r13 + r31) / (FOUR * qz);
    qy = (r32 + r23) / (FOUR * qz);
  }
  
  vtkQuaternion *q = vtkQuaternion::New();
  q->SetElements(q0, qx, qy, qz);
  this->SetRotation(q);

  // Translation
  vtkVector3 *v = vtkVector3::New();
  v->SetElements(m->GetElement(0,3), m->GetElement(1,3), m->GetElement(2,3));
  this->SetTranslation(v);

  q->Delete();
  v->Delete();

  this->Modified();

#undef FOUR
#undef TWO
}

//----------------------------------------------------------------------------
// PrintSelf
//----------------------------------------------------------------------------
void vtkPose::PrintSelf(ostream& os, vtkIndent indent)
{
  os << indent << "Translation: " << endl;
  this->Translation->PrintSelf(os,indent);

  os << indent << "Rotation: " << endl;
  this->Rotation->PrintSelf(os,indent);
}

//----------------------------------------------------------------------------
void vtkPose::Dump()
{
  this->Print("dump");
}

//----------------------------------------------------------------------------
void vtkPose::Print(const char *x)
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
