/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageWarp.h,v $
  Date:      $Date: 2006/01/06 17:57:11 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
// .NAME vtkImageWarp - 
// 
// .SECTION Description
// 
// .SECTION See Also

#ifndef __vtkImageWarp_h
#define __vtkImageWarp_h

#include <vtkAGConfigure.h>

#include <vtkGridTransform.h>
#include <vtkGeneralTransform.h>
#include <vtkImageData.h>
#include <vtkIntensityTransform.h>

#include <vector>

#define VTK_IMAGE_WARP_DM 1
#define VTK_IMAGE_WARP_OF 2

class VTK_AG_EXPORT vtkImageWarp : public vtkGridTransform {
public:
  static vtkImageWarp* New();
  vtkTypeMacro(vtkImageWarp,vtkGridTransform);
  void PrintSelf(ostream& os, vtkIndent indent);

  vtkBooleanMacro(Verbose, int);
  vtkSetMacro(Verbose,int);
  vtkGetMacro(Verbose,int);

  vtkSetObjectMacro(Target,vtkImageData);
  vtkGetObjectMacro(Target,vtkImageData);
  vtkSetObjectMacro(Source,vtkImageData);
  vtkGetObjectMacro(Source,vtkImageData);
  vtkSetObjectMacro(Mask,vtkImageData);
  vtkGetObjectMacro(Mask,vtkImageData);
  vtkSetObjectMacro(GeneralTransform,vtkGeneralTransform);
  vtkGetObjectMacro(GeneralTransform,vtkGeneralTransform);
  vtkSetObjectMacro(IntensityTransform,vtkIntensityTransform);
  vtkGetObjectMacro(IntensityTransform,vtkIntensityTransform);

  vtkSetMacro(MinimumIterations, int);
  vtkGetMacro(MinimumIterations, int);
  vtkSetMacro(MaximumIterations, int);
  vtkGetMacro(MaximumIterations, int);
  vtkSetMacro(MinimumLevel, int);
  vtkGetMacro(MinimumLevel, int);
  vtkSetMacro(MaximumLevel, int);
  vtkGetMacro(MaximumLevel, int);
  vtkSetMacro(MinimumStandardDeviation, float);
  vtkGetMacro(MinimumStandardDeviation, float);
  vtkSetMacro(MaximumStandardDeviation, float);
  vtkGetMacro(MaximumStandardDeviation, float);
  vtkSetMacro(ForceType, int);
  vtkGetMacro(ForceType, int);
  vtkBooleanMacro(UseSSD,int);
  vtkSetMacro(UseSSD,int);
  vtkGetMacro(UseSSD,int);
  vtkSetMacro(SSDEpsilon,float);
  vtkGetMacro(SSDEpsilon,float);
  vtkSetMacro(Interpolation,int);
  vtkGetMacro(Interpolation,int);
  vtkBooleanMacro(ResliceTensors,int);
  vtkSetMacro(ResliceTensors,int);
  vtkGetMacro(ResliceTensors,int);
      
protected:
  vtkImageWarp();
  ~vtkImageWarp();
  vtkImageWarp(const vtkImageWarp&);
  void operator=(const vtkImageWarp&);
  void InternalUpdate();
  void CreatePyramid();
  void FreePyramid();
  void UpdatePyramid(int level);
  bool IsMaximumLevel(int l, int* ext);
  double SSD(vtkImageData* t,vtkImageData* s,vtkImageData* m);
  //  float MaxDispDiff(vtkImageData* t,vtkImageData* s,vtkImageData* m);
  
  int MinimumIterations;
  int MaximumIterations;
  int MinimumLevel;
  int MaximumLevel;
  float MinimumStandardDeviation;
  float MaximumStandardDeviation;
  int ForceType;
  int UseSSD;
  int ResliceTensors;
  float SSDEpsilon;
  //  float MaxDiff;
  int Interpolation;
  int Verbose;
  
  vtkImageData* Target;
  vtkImageData* Source;
  vtkImageData* Mask;
  vtkGridTransform* WorkTransform;
  vtkGeneralTransform* GeneralTransform;
  vtkIntensityTransform* IntensityTransform;

  //BTX
  std::vector<vtkImageData*> Targets;
  std::vector<vtkImageData*> Sources;
  std::vector<vtkImageData*> Masks;
  std::vector<vtkImageData*> Displacements;
  //ETX
};
#endif


