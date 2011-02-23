/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageEditorEffects.cxx,v $
  Date:      $Date: 2008/01/31 22:02:27 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/
#include "vtkImageEditorEffects.h"

#include "vtkObjectFactory.h"
#include "vtkImageErode.h"
#include "vtkImageConnectivity.h"
#include "vtkImageLabelChange.h"
#include "vtkImageFillROI.h"
#include "vtkImageThreshold.h"
#include "vtkImageCopy.h"
#include "vtkImageLabelVOI.h"

//------------------------------------------------------------------------------
vtkImageEditorEffects* vtkImageEditorEffects::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageEditorEffects");
  if(ret)
  {
    return (vtkImageEditorEffects*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageEditorEffects;
}
//----------------------------------------------------------------------------
vtkImageEditorEffects::vtkImageEditorEffects()
{
  this->IslandSize = 0;
  this->LargestIslandSize = 0;
}

//----------------------------------------------------------------------------
vtkImageEditorEffects::~vtkImageEditorEffects()
{
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::Threshold(float min, float max, 
  float in, float out, int replaceIn, int replaceOut)
{
  vtkImageThreshold *thresh = vtkImageThreshold::New();
  thresh->ThresholdBetween(min, max);
  // set the values first, as they automatically set the replace in and out
  // flags to on
  thresh->SetInValue(in);
  thresh->SetOutValue(out);
  thresh->SetReplaceIn(replaceIn);
  thresh->SetReplaceOut(replaceOut);
  thresh->SetOutputScalarTypeToShort(); // needed for later drawing

  this->Apply(thresh, thresh);

  thresh->SetInput(NULL);
  thresh->SetOutput(NULL);
  thresh->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::Draw(int value, vtkPoints *points, int radius, 
    char *shape)
{
  vtkImageFillROI *fill = vtkImageFillROI::New();

  fill->SetValue(value);
  fill->SetRadius(radius);
  fill->SetShapeString(shape);
  fill->SetPoints(points);

  this->Apply(fill, fill);

  fill->SetInput(NULL);
  fill->SetOutput(NULL);
  fill->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::Erode(float fg, float bg, int neighbors,
                              int iterations)
{
  vtkImageErode *erode = vtkImageErode::New();

  erode->SetForeground(fg);
  erode->SetBackground(bg);

  if (neighbors == 8) 
    {
    erode->SetNeighborTo8();
    }
  else
    {
    erode->SetNeighborTo4();
    }

  for (int i=0; i<iterations; i++)
    {
    this->Apply(erode, erode);
    }

  erode->SetInput(NULL);
  erode->SetOutput(NULL);
  erode->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::Dilate(float fg, float bg, int neighbors,
                               int iterations)
{
  vtkImageErode *erode = vtkImageErode::New();
  
  // Swap bg and fg to dilate
  erode->SetForeground(bg);
  erode->SetBackground(fg);

  if (neighbors == 8) 
    {
    erode->SetNeighborTo8();
    }
  else
    {
    erode->SetNeighborTo4();
    }

  for (int i=0; i<iterations; i++)
    {
    this->Apply(erode, erode);
    }

  erode->SetInput(NULL);
  erode->SetOutput(NULL);
  erode->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::ErodeDilate(float fg, float bg, int neighbors,
                                    int iterations)
{
  vtkImageErode *erode  = vtkImageErode::New();
  vtkImageErode *dilate = vtkImageErode::New();
  
  erode->SetForeground(fg);
  erode->SetBackground(bg);
  dilate->SetForeground(bg);
  dilate->SetBackground(fg);
  dilate->SetInput(erode->GetOutput());

    if (neighbors == 8)
  {
        dilate->SetNeighborTo8();
  }
    else
  {
          dilate->SetNeighborTo4();
  }

    if (neighbors == 8) 
  {
        erode->SetNeighborTo8();
  }
    else
  {
        erode->SetNeighborTo4();
  }

  for (int i=0; i<iterations; i++)
  {
    this->Apply(erode, dilate);
  }

  erode->SetInput(NULL);
  erode->SetOutput(NULL);
  erode->Delete();

  dilate->SetInput(NULL);
  dilate->SetOutput(NULL);
  dilate->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::DilateErode(float fg, float bg, int neighbors,
                                    int iterations)
{
  vtkImageErode *erode  = vtkImageErode::New();
  vtkImageErode *dilate = vtkImageErode::New();
  
  erode->SetForeground(fg);
  erode->SetBackground(bg);
  dilate->SetForeground(bg);
  dilate->SetBackground(fg);
  erode->SetInput(dilate->GetOutput());

    if (neighbors == 8) 
  {
    erode->SetNeighborTo8();
  }
    else
  {
    erode->SetNeighborTo4();
  }

  if (neighbors == 8) 
  {
    dilate->SetNeighborTo8();
  }
  else
  {
    dilate->SetNeighborTo4();
  }

  for (int i=0; i<iterations; i++)
  {
    this->Apply(dilate, erode);
  }
  erode->SetInput(NULL);
  erode->SetOutput(NULL);
  erode->Delete();

  dilate->SetInput(NULL);
  dilate->SetOutput(NULL);
  dilate->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::IdentifyIslands(int bg, int fgMin, int fgMax)
{
  vtkImageConnectivity *con  = vtkImageConnectivity::New();

  con->SetBackground(bg);
  con->SetMinForeground(fgMin);
  con->SetMaxForeground(fgMax);

  con->SetFunctionToIdentifyIslands();

  this->Apply(con, con);

  con->SetInput(NULL);
  con->SetOutput(NULL);
  con->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::RemoveIslands(int bg, int fgMin, int fgMax,
                                      int minSize)
{
  vtkImageConnectivity *con  = vtkImageConnectivity::New();
  int native = 0;

  con->SetBackground(bg);
  con->SetMinForeground(fgMin);
  con->SetMaxForeground(fgMax);

  con->SetFunctionToRemoveIslands();
  con->SetMinSize(minSize);

   // Can we use native slicing for speed?
  if (!strcmp(this->GetOutputSliceOrder(),"SI") || 
      !strcmp(this->GetOutputSliceOrder(),"IS"))
  {
    if (!strcmp(this->GetInputSliceOrder(),"SI") || 
        !strcmp(this->GetInputSliceOrder(),"IS"))
    {
      native = 1;
    }
  }
  if (!strcmp(this->GetOutputSliceOrder(),"PA") || 
      !strcmp(this->GetOutputSliceOrder(),"AP"))
  {
    if (!strcmp(this->GetInputSliceOrder(),"PA") || 
        !strcmp(this->GetInputSliceOrder(),"AP"))
    {
      native = 1;
    }
  }
  if (!strcmp(this->GetOutputSliceOrder(),"RL") || 
      !strcmp(this->GetOutputSliceOrder(),"LR"))
  {
    if (!strcmp(this->GetInputSliceOrder(),"RL") || 
        !strcmp(this->GetInputSliceOrder(),"LR"))
    {
      native = 1;
    }
  }
  if (this->GetDimension() != EDITOR_DIM_MULTI)
  {
    native = 0;
  }
  if (native)
  {
    con->SliceBySliceOn();
    this->SetDimensionTo3D();
  }

  this->Apply(con, con);

  if (native)
  {
    this->SetDimensionToMulti();
  }

  con->SetInput(NULL);
  con->SetOutput(NULL);
  con->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::ChangeIsland(int outputLabel, 
    int xSeed, int ySeed, int zSeed)
{
  vtkImageConnectivity *con  = vtkImageConnectivity::New();

    con->SetFunctionToChangeIsland();
    con->SetOutputLabel(outputLabel);
    con->SetSeed(xSeed, ySeed, zSeed);
  con->SetBackground(0);

  this->Apply(con, con);

  con->SetInput(NULL);
  con->SetOutput(NULL);
  con->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::MeasureIsland(int xSeed, int ySeed, int zSeed)
{
  vtkImageConnectivity *con = vtkImageConnectivity::New();
  con->SetFunctionToMeasureIsland();
  con->SetSeed(xSeed, ySeed, zSeed);
  con->SetBackground(0);

  this->Apply(con, con);

  this->LargestIslandSize = con->GetLargestIslandSize();
  this->IslandSize = con->GetIslandSize();

  con->SetInput(NULL);
  con->SetOutput(NULL);
  con->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::SaveIsland(int xSeed, int ySeed, int zSeed)
{
  vtkImageConnectivity *con  = vtkImageConnectivity::New();

    con->SetFunctionToSaveIsland();
    con->SetSeed(xSeed, ySeed, zSeed);
  con->SetBackground(0);

  this->Apply(con, con);

  con->SetInput(NULL);
  con->SetOutput(NULL);
  con->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::ChangeLabel(int inputLabel, int outputLabel)
{
  vtkImageLabelChange *change  = vtkImageLabelChange::New();

  change->SetInputLabel(inputLabel);
    change->SetOutputLabel(outputLabel);

  this->Apply(change, change);

  change->SetInput(NULL);
  change->SetOutput(NULL);
  change->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::Clear()
{
  vtkImageCopy *clear  = vtkImageCopy::New();

  clear->ClearOn();

  this->Apply(clear, clear);

  clear->SetInput(NULL);
  clear->SetOutput(NULL);
  clear->Delete();
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageEditor::PrintSelf(os, indent);
}

//----------------------------------------------------------------------------
void vtkImageEditorEffects::LabelVOI(int c1x, int c1y, int c1z, 
                                     int c2x, int c2y, int c2z, int method)
{
  vtkImageLabelVOI *change  = vtkImageLabelVOI::New();

  //  change->SetInputLabel(inputLabel);
  //  change->SetOutputLabel(outputLabel);
  change->SetCorner1(c1x, c1y, c1z);
  change->SetCorner2(c2x, c2y, c2z);
  change->SetMethod(method);
  
  this->Apply(change, change);

  change->SetInput(NULL);
  change->SetOutput(NULL);
  change->Delete();
}
