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
// .NAME vtkVector3 - 3-element column vectors
// .SECTION Description
#ifndef vtkVector3_H 
#define vtkVector3_H

#include "vtkObject.h"
#include "vtkSlicer.h"

#include "vtkMutualInformationRegistrationConfigure.h"

#define VECTOR3_EPSILON 0.000001f

class VTK_MUTUALINFORMATIONREGISTRATION_EXPORT vtkVector3 : public vtkObject
{
public:
  // VTK requisites
  static vtkVector3 *New();
  vtkTypeMacro(vtkVector3,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Query routines
  double *GetElements() {return this->Element;};
  double GetElement(int y);
//void PrintSelf();

  // Assignment routines
  void Copy(vtkVector3 *v);
  void SetElement(int y, double v);
  void SetElements(double x, double y, double z);
  void Zero();
  void XHat() {this->Zero(); this->Element[0] = 1.0f;};
  void YHat() {this->Zero(); this->Element[1] = 1.0f;};
  void ZHat() {this->Zero(); this->Element[2] = 1.0f;};

  // Operations
  double Length();
  void Normalize();
  void Invert();
  void Add(double s);
  void Add(vtkVector3 *v);
  void Add(vtkVector3 *A, vtkVector3* B);
  void Subtract(vtkVector3 *v);
  void Subtract(vtkVector3 *A, vtkVector3 *B);
  void Multiply(double s);
  double Dot(vtkVector3 *v);
  void Cross(vtkVector3 *A, vtkVector3 *B);

protected:
  // Constructor/Destructor
  vtkVector3();
  ~vtkVector3() {};

  double Element[3];
};

#endif
