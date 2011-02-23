/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageEditorEffects.h,v $
  Date:      $Date: 2006/02/15 02:50:56 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/
// .NAME vtkImageEditorEffects - Implementation of effects that 
// can be performed on volumes when editing.
// .SECTION Description
//
//  Draw, threshold, clear, change island, measure island, 
//  dilate, erode, and more.
//

#ifndef __vtkImageEditorEffects_h
#define __vtkImageEditorEffects_h

#include "vtkImageEditor.h"
#include "vtkSlicer.h"

class vtkPoints;
class VTK_SLICER_BASE_EXPORT vtkImageEditorEffects : public vtkImageEditor
{
public:
  static vtkImageEditorEffects *New();
  vtkTypeMacro(vtkImageEditorEffects,vtkImageEditor);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  void Clear();
  void Threshold(float min, float max, float in, float out, 
    int replaceIn, int replaceOut);
  void Draw(int label, vtkPoints *pts, int radius, char *shape);
  void Erode(float fg, float bg, int neighbors, int iterations);
  void Dilate(float fg, float bg, int neighbors, int iterations);
  void ErodeDilate(float fg, float bg, int neighbors, int iterations);
  void DilateErode(float fg, float bg, int neighbors, int iterations);
  void IdentifyIslands(int bg, int fgMin, int fgMax);
  void RemoveIslands(int bg, int fgMin, int fgMax, int minSize);
  void ChangeIsland(int newLabel, int xSeed, int ySeed, int zSeed);
  void MeasureIsland(int xSeed, int ySeed, int zSeed);
  void SaveIsland(int xSeed, int ySeed, int zSeed);
  void ChangeLabel(int inputLabel, int outputLabel);

  void LabelVOI(int c1x, int c1y, int c1z, int c2x, int c2y, int c2z, int method);
  
  vtkGetMacro(IslandSize, int);
  vtkGetMacro(LargestIslandSize, int);

protected:

  vtkImageEditorEffects();
  ~vtkImageEditorEffects();
  vtkImageEditorEffects(const vtkImageEditorEffects&);
  void operator=(const vtkImageEditorEffects&);

  int IslandSize;
  int LargestIslandSize;
};

#endif


