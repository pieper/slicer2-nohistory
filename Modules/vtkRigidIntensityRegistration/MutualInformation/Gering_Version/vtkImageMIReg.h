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
#ifndef vtkImageMIReg_H
#define vtkImageMIReg_H

#include "vtkSlicer.h"
#include "vtkProcessObject.h"
#include "vtkImageData.h"
#include "vtkMatrix4x4.h"
#include "vtkRasToIjkTransform.h"
#include "vtkTimeStamp.h"
#include "vtkMath.h"
#include "vtkVector3.h"
#include "vtkQuaternion.h"
#include "vtkPose.h"

#include "vtkMutualInformationRegistrationConfigure.h"

class VTK_MUTUALINFORMATIONREGISTRATION_EXPORT vtkImageMIReg : public vtkProcessObject
{
public:
  // VTK requisites
  static vtkImageMIReg *New();
  vtkTypeMacro(vtkImageMIReg,vtkProcessObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Inputs/Outputs
  vtkGetObjectMacro(Reference, vtkImageData);
  vtkSetObjectMacro(Reference, vtkImageData);

  vtkGetObjectMacro(Subject, vtkImageData);
  vtkSetObjectMacro(Subject, vtkImageData);

  vtkGetObjectMacro(RefTrans, vtkRasToIjkTransform);
  vtkSetObjectMacro(RefTrans, vtkRasToIjkTransform);

  vtkGetObjectMacro(SubTrans, vtkRasToIjkTransform);
  vtkSetObjectMacro(SubTrans, vtkRasToIjkTransform);

  vtkGetObjectMacro(InitialPose, vtkPose);
  vtkSetObjectMacro(InitialPose, vtkPose);

  vtkGetObjectMacro(CurrentPose, vtkPose);
  vtkGetObjectMacro(FinalPose, vtkPose);

  // Parameters
  vtkGetMacro(SampleSize, int);
  vtkSetMacro(SampleSize, int);
  vtkGetMacro(SigmaUU, float);
  vtkSetMacro(SigmaUU, float);
  vtkGetMacro(SigmaVV, float);
  vtkSetMacro(SigmaVV, float);
  vtkGetMacro(SigmaV, float);
  vtkSetMacro(SigmaV, float);
  vtkGetMacro(PMin, float);
  vtkSetMacro(PMin, float);
  vtkGetMacro(UpdateIterations, int);
  vtkSetMacro(UpdateIterations, int);

  // Parameters per resolution
  vtkSetVector4Macro(NumIterations, int);
  vtkGetVector4Macro(NumIterations, int);
  vtkSetVector4Macro(LambdaDisplacement, float);
  vtkGetVector4Macro(LambdaDisplacement, float);
  vtkSetVector4Macro(LambdaRotation, float);
  vtkGetVector4Macro(LambdaRotation, float);

  // Downsampled images (made accessible for interactive rendering)
  vtkImageData *GetRef(int res) {return this->Refs[res];};
  vtkImageData *GetSub(int res) {return this->Subs[res];};
  vtkRasToIjkTransform *GetRefRasToIjk(int res) {return this->RefRasToIjk[res];};
  vtkRasToIjkTransform *GetSubRasToIjk(int res) {return this->SubRasToIjk[res];};

  // Pipeline
  void Update();

  // Status reporting
  vtkGetMacro(InProgress, int);
  int GetResolution();
  int GetIteration();
  vtkSetMacro(RunTime, int);
  vtkGetMacro(RunTime, int);

  // Should be protected, but public for debugging
  void Reset();
  int Initialize();

protected:
  // Constructor/Destructor
  vtkImageMIReg();
    ~vtkImageMIReg();

  vtkImageData *Reference;
  vtkImageData *Subject;
  vtkRasToIjkTransform *RefTrans;
  vtkRasToIjkTransform *SubTrans;
  vtkPose *InitialPose;
  vtkPose *FinalPose;

  vtkImageData *Subs[4];
  vtkImageData *Refs[4];
  vtkRasToIjkTransform *RefRasToIjk[4];
  vtkRasToIjkTransform *SubRasToIjk[4];
  vtkPose *CurrentPose;

  float LambdaDisplacement[4];
  float LambdaRotation[4];
  int NumIterations[4];
  int CurIteration[4];

  vtkTimeStamp UTime;
  int RunTime;
  int SampleSize;
  float PMin;
  float SigmaUU;
  float SigmaVV;
  float SigmaV;
  int InProgress;
  int UpdateIterations;

  // Pipeline
  void Execute();
  void Cleanup();

  // Helpers
  double GetGradientAndInterpolation(vtkVector3 *rasGrad, 
    vtkImageData *data, vtkRasToIjkTransform *rasToIjk, vtkVector3 *ras);
};
#endif

