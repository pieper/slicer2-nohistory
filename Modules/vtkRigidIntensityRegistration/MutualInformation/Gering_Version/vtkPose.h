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
// .NAME vtkPose - Pose for registration
// .SECTION Description
// Pose consists of a vector of translation, and a quanterion of rotation.
#ifndef vtkPose_H 
#define vtkPose_H

#include "vtkObject.h"
#include "vtkQuaternion.h"
#include "vtkVector3.h"
#include "vtkMatrix4x4.h"
#include "vtkSlicer.h"

#include "vtkMutualInformationRegistrationConfigure.h"

class VTK_MUTUALINFORMATIONREGISTRATION_EXPORT vtkPose : public vtkObject
{
public:
  // VTK requisites
  static vtkPose *New();
  vtkTypeMacro(vtkPose,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Query routines
  vtkVector3 *GetTranslation() {return this->Translation;};
  vtkQuaternion *GetRotation() {return this->Rotation;};

  // Assignment routines
  void Identity();
  void Copy(vtkPose *p);
  void SetTranslation(vtkVector3 *t) {this->Translation->Copy(t); this->Modified();};
  void SetRotation(vtkQuaternion *r) {this->Rotation->Copy(r); this->Modified();};
  void Set(vtkQuaternion *r, vtkVector3 *t) {
    this->Translation->Copy(t); this->Rotation->Copy(r); this->Modified();};

  // Operations
  void Invert(vtkPose *p);
  void Invert();
  void Normalize();
  void Concat(vtkPose *p1, vtkPose *p2);
  void Concat(vtkPose *p2);
  void Transform(vtkVector3 *u, vtkVector3 *v);

  // Conversions
  void ConvertToMatrix4x4(vtkMatrix4x4 *m);
  void ConvertFromMatrix4x4(vtkMatrix4x4 *m);

  void Print(const char *x);
  void Dump();
protected:
  // Constructors/Destructor
  vtkPose();
  ~vtkPose();

  vtkVector3 *Translation;
  vtkQuaternion *Rotation;
};
#endif
