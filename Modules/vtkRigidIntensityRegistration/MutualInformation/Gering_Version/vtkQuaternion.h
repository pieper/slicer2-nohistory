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
// .NAME vtkQuaternion - higher-dimension complex numbers
// .SECTION Description
// Quaternions are a higher-dimension complex number with 1 real part and
// 3 imaginary parts: q = s + ia + jb + kc
//
// There useful for representing rotations because they are more suitable
// to concatenation and interpolation than the alternatives of 3x3 orthogonal
// matrices, or 3 Euler angles.

#ifndef vtkQuaternion_H 
#define vtkQuaternion_H

#include "vtkObject.h"
#include "vtkVector3.h"

#include "vtkMutualInformationRegistrationConfigure.h"

class VTK_MUTUALINFORMATIONREGISTRATION_EXPORT vtkQuaternion : public vtkObject
{
public:
  // VTK requisites
  static vtkQuaternion *New();
  vtkTypeMacro(vtkQuaternion,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Query routines
  double *GetElements();
  double GetElement(int y);
  double GetScalar();
  void GetVector(vtkVector3 *v);
  double GetRotationAngle();
  void GetRotationAxis(vtkVector3 *v);

  // Assignment routines
  void Zero();
  void Identity();
  void Copy(vtkQuaternion *q);
  void SetElement(int y, double v);
  void SetElements(double s, double x, double y, double z);
  void Set(double s, vtkVector3 *v);
  void SetRotation(vtkVector3 *axis, const double angle) ;

  // Operations
  double Length();
  void Normalize();
  void Invert(vtkQuaternion *q);
  void Invert();
  void Multiply(double s);
  void Multiply(vtkQuaternion *Q1, vtkQuaternion *Q2);
  void Multiply(vtkQuaternion *Q2);
  void Add(vtkQuaternion *q);
  void Rotate(vtkVector3 *u, vtkVector3 *v);

protected:
  // Constructor/Destructor
  vtkQuaternion();
  ~vtkQuaternion() {};

  double Element[4];
};

#endif
