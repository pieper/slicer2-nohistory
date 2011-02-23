/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDeformTensors.h,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkDeformTensors - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkDeformTensors_h
#define __vtkDeformTensors_h

#include <vtkAGConfigure.h>

#include <vtkImageTwoInputFilter.h>

#define VTK_DEFORMTENSOR_RIGID 0
#define VTK_DEFORMTENSOR_NO_SCALE 1
#define VTK_DEFORMTENSOR_SCALE 2

class VTK_AG_EXPORT vtkDeformTensors : public vtkImageMultipleInputFilter
{
public:
  static vtkDeformTensors* New();
  vtkTypeMacro(vtkDeformTensors,vtkImageMultipleInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  virtual void SetTensors(vtkImageData *input)
  {
    this->SetInput(0, input);
  }
  vtkImageData* GetTensors();
  
  virtual void SetDisplacements(vtkImageData *input)
  {
    this->SetInput(1, input);
  }
  vtkImageData* GetDisplacements();
  
  vtkSetMacro(Mode,int);
  void SetModeToRigid() { this->SetMode(VTK_DEFORMTENSOR_RIGID); };
  void SetModeToNoScale() { this->SetMode(VTK_DEFORMTENSOR_NO_SCALE); };
  void SetModeToScale() { this->SetMode(VTK_DEFORMTENSOR_SCALE); };
  vtkGetMacro(Mode,int);
  const char *GetModeAsString();

protected:
  vtkDeformTensors();
  ~vtkDeformTensors();
  vtkDeformTensors(const vtkDeformTensors&);
  void operator=(const vtkDeformTensors&);
  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
               int extent[6], int id);

  int Mode;
};

//BTX
inline const char *vtkDeformTensors::GetModeAsString()
{
  switch (this->Mode)
    {
    case VTK_DEFORMTENSOR_RIGID:
      return "Rigid";
    case VTK_DEFORMTENSOR_NO_SCALE:
      return "NoScale";
    case VTK_DEFORMTENSOR_SCALE:
      return "Scale";
    default:
      return "Unrecognized";
    }
}
//ETX

#endif
