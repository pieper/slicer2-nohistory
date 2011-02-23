/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSlicer.cxx,v $
  Date:      $Date: 2006/06/29 16:49:12 $
  Version:   $Revision: 1.68 $

=========================================================================auto=*/
#include "vtkMrmlSlicer.h"

#include "vtkObjectFactory.h"
#include "vtkCamera.h"
#include "vtkImageReformatIJK.h"
#include "vtkImageReformat.h"
#include "vtkImageOverlay.h"
#include "vtkImageMapToColors.h"
#include "vtkMatrix4x4.h"
#include "vtkTransform.h"
#include "vtkPoints.h"
#include "vtkLookupTable.h"
#include "vtkMrmlDataVolume.h"
#include "vtkMrmlVolumeNode.h"
#include "vtkImageLabelOutline.h"
#include "vtkImageCrossHair2D.h"
#include "vtkImageZoom2D.h"
#include "vtkImageDouble2D.h"
#include "vtkIndirectLookupTable.h"
#include "vtkImageDrawROI.h"
#include "vtkStackOfPolygons.h"
#include "vtkCollection.h"
#include "vtkVoidArray.h"
#include "vtkPointData.h"

//-----  This hack needed to compile using gcc3 on OSX until new stdc++.dylib
#ifdef __APPLE_CC__
extern "C"
{
  void oft_initSlicerBase() 
  {
#if __GNUC__ < 4
  extern void _ZNSt8ios_base4InitC4Ev();
  _ZNSt8ios_base4InitC4Ev();
#endif
  }
}
#endif


//------------------------------------------------------------------------------
vtkMrmlSlicer* vtkMrmlSlicer::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlSlicer");
  if(ret)
  {
    return (vtkMrmlSlicer*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlSlicer;
}


static void Normalize(double *a)
{
  double d;
  d = sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);

  if (d == 0.0) return;

  a[0] = a[0] / d;
  a[1] = a[1] / d;
  a[2] = a[2] / d;
}

// a = b x c
static void Cross(double *a, double *b, double *c)
{
  a[0] = b[1]*c[2] - c[1]*b[2];
  a[1] = c[0]*b[2] - b[0]*c[2];
  a[2] = b[0]*c[1] - c[0]*b[1];
}

//----------------------------------------------------------------------------
vtkMrmlSlicer::vtkMrmlSlicer()
{
  this->ZoomCenter0[0] = this->ZoomCenter0[1] = 0.0;
  this->ZoomCenter1[0] = this->ZoomCenter1[1] = 0.0;
  this->ZoomCenter2[0] = this->ZoomCenter2[1] = 0.0;
  this->FieldOfView = 240.0;
  this->LabelIndirectLUT = NULL;
  this->PolyDraw = vtkImageDrawROI::New();
  this->AxiPolyStack = vtkStackOfPolygons::New();
  this->AxiRasPolyStack = vtkStackOfPolygons::New();
  this->SagPolyStack = vtkStackOfPolygons::New();
  this->SagRasPolyStack = vtkStackOfPolygons::New();
  this->CorPolyStack = vtkStackOfPolygons::New();
  this->CorRasPolyStack = vtkStackOfPolygons::New();
  this->rasPts = vtkPoints::New();
  this->CopyPoly = vtkPoints::New();
  this->ReformatIJK = vtkImageReformatIJK::New();
  this->DrawIjkPoints = vtkPoints::New();

  // NoneVolume's MrmlNode
  this->NoneNode = vtkMrmlVolumeNode::New();
  this->NoneNode->Register(this);
  this->NoneNode->Delete();
  this->NoneNode->SetID(0);
  this->NoneNode->SetDescription("NoneVolume created by vtkMrmlSlicer");
  this->NoneNode->SetName("None");

    // Create a NoneVolume
  this->NoneVolume = vtkMrmlDataVolume::New();
  this->NoneVolume->Register(this);
  this->NoneVolume->Delete();
  this->NoneVolume->SetMrmlNode(this->NoneNode);

  this->ComputeOffsetRange();

  for (int s=0; s<NUM_SLICES; s++)
  {
    this->ReformatMatrix[s] = vtkMatrix4x4::New();

    // Lower Pipeline

    // Volumes
    this->BackVolume[s]  = NULL;
    this->SetBackVolume(s, this->NoneVolume);
    this->ForeVolume[s]  = NULL;
    this->SetForeVolume(s, this->NoneVolume);
    this->LabelVolume[s] = NULL;
    this->SetLabelVolume(s, this->NoneVolume);

    // Reformatters
    this->BackReformat[s]  = vtkImageReformat::New();
    this->BackReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);

    this->ForeReformat[s]  = vtkImageReformat::New();
    this->ForeReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);

    this->LabelReformat[s] = vtkImageReformat::New();
    this->LabelReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);
    this->LabelReformat[s]->InterpolateOff();

    // >> AT 11/09/01
    this->BackReformat3DView[s]  = vtkImageReformat::New();
    this->BackReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);

    this->ForeReformat3DView[s]  = vtkImageReformat::New();
    this->ForeReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);

    this->LabelReformat3DView[s] = vtkImageReformat::New();
    this->LabelReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);
    this->LabelReformat3DView[s]->InterpolateOff();
    // << AT 11/09/01

    // Mappers
    this->BackMapper[s]  = vtkImageMapToColors::New();
    this->BackMapper[s]->SetOutputFormatToRGBA();
    this->ForeMapper[s]  = vtkImageMapToColors::New();
    this->ForeMapper[s]->SetOutputFormatToRGBA();
    this->LabelMapper[s] = vtkImageMapToColors::New();
    this->LabelMapper[s]->SetOutputFormatToRGBA();

    // >> AT 11/09/01
    this->BackMapper3DView[s]  = vtkImageMapToColors::New();
    this->BackMapper3DView[s]->SetOutputFormatToRGBA();
    this->ForeMapper3DView[s]  = vtkImageMapToColors::New();
    this->ForeMapper3DView[s]->SetOutputFormatToRGBA();
    this->LabelMapper3DView[s] = vtkImageMapToColors::New();
    this->LabelMapper3DView[s]->SetOutputFormatToRGBA();
    // << AT 11/09/01

    // Label outline
    this->LabelOutline[s] = vtkImageLabelOutline::New();
    // >> AT 11/09/01
    this->LabelOutline3DView[s] = vtkImageLabelOutline::New();
    // << AT 11/09/01

    // Overlays
    this->ForeOpacity = 0.5;
    // Initialize Overlay to have 3 inputs (even though these are not
    // the actual inputs).
    // Once the inputs are created, I can then set the fore opacity.
    this->Overlay[s] = vtkImageOverlay::New();
    this->Overlay[s]->SetInput(0, this->NoneVolume->GetOutput());
    this->Overlay[s]->SetInput(1, this->NoneVolume->GetOutput());
    this->Overlay[s]->SetInput(2, this->NoneVolume->GetOutput());
    this->Overlay[s]->SetOpacity(1, this->ForeOpacity);

    // >> AT 11/09/01
    this->Overlay3DView[s] = vtkImageOverlay::New();
    this->Overlay3DView[s]->SetInput(0, this->NoneVolume->GetOutput());
    this->Overlay3DView[s]->SetInput(1, this->NoneVolume->GetOutput());
    this->Overlay3DView[s]->SetInput(2, this->NoneVolume->GetOutput());
    this->Overlay3DView[s]->SetOpacity(1, this->ForeOpacity);
    // << AT 11/09/01

    // Upper Pipeline
    
    // Double
    this->Double[s] = vtkImageDouble2D::New();
    this->DoubleSliceSize[s] = 0;

    // Zoom
    this->Zoom[s] = vtkImageZoom2D::New();

    // Cursor
    this->Cursor[s] = vtkImageCrossHair2D::New();
    // DAVE need a SetAnnoColor
    this->Cursor[s]->SetCursorColor(1.0, 1.0, 0.5);
    this->Cursor[s]->SetCursor(127, 127);
    this->Cursor[s]->SetHashGap(10);
    this->Cursor[s]->SetHashLength(6);

    // Offset and Orient

    this->ComputeOffsetRangeIJK(s);
    for (int j=0; j<MRML_SLICER_NUM_ORIENT; j++)
    {
      this->InitOffset(s, this->GetOrientString(j), 0.0);
    }
    this->Driver[s] = 0;
    this->SetOrient(s, MRML_SLICER_ORIENT_ORIGSLICE);

    // Filter
    this->FirstFilter[s] = NULL;
    this->LastFilter[s] = NULL;
  }

  this->BackFilter = 0;
  this->ForeFilter = 0;
  this->FilterActive = 0;
  this->FilterOverlay = 0;

  // Matrix
  this->DirN[0] = 0;
  this->DirN[1] = 0;
  this->DirN[2] = -1;
  this->DirT[0] = 1;
  this->DirT[1] = 0;
  this->DirT[2] = 0;
  this->DirP[0] = 0;
  this->DirP[1] = 0;
  this->DirP[2] = 0;
  this->CamN[0] = 0;
  this->CamN[1] = 0;
  this->CamN[2] = -1;
  this->CamT[0] = 1;
  this->CamT[1] = 0;
  this->CamT[2] = 0;
  this->CamP[0] = 0;
  this->CamP[1] = 0;
  this->CamP[2] = 0;


  this->ReformatAxialT[0] = -1 ;
  this->ReformatAxialT[1] = 0 ;  
  this->ReformatAxialT[2] = 0 ;
  this->ReformatAxialN[0] = 0;
  this->ReformatAxialN[1] = 0 ;
  this->ReformatAxialN[2] = -1 ;

  this->ReformatSagittalT[0] = 0 ;
  this->ReformatSagittalT[1] = -1 ;  
  this->ReformatSagittalT[2] = 0 ;
  this->ReformatSagittalN[0] = -1;
  this->ReformatSagittalN[1] = 0 ;
  this->ReformatSagittalN[2] = 0 ;

  this->ReformatCoronalT[0] = -1 ;
  this->ReformatCoronalT[1] = 0 ;  
  this->ReformatCoronalT[2] = 0 ;
  this->ReformatCoronalN[0] = 0;
  this->ReformatCoronalN[1] = 1 ;
  this->ReformatCoronalN[2] = 0 ;

  // set the user defined matrix for each slice
  for (int ss=0; ss<NUM_SLICES; ss++)  
      // sp 2002-02-13 changed var to ss since s declared above 
      // doesn't work on windows compiler
    { 
      this->NewOrientN[ss][0] = 0;
      this->NewOrientN[ss][1] = 0;
      this->NewOrientN[ss][2] = -1;
      this->NewOrientT[ss][0] = 1;
      this->NewOrientT[ss][1] = 0;
      this->NewOrientT[ss][2] = 0;
      this->NewOrientP[ss][0] = 0;
      this->NewOrientP[ss][1] = 0;
      this->NewOrientP[ss][2] = 0;
    }
  // Draw
  this->DrawX = this->DrawY = 0;

  // Point
  this->WldPoint[0] = 0;
  this->WldPoint[1] = 0;
  this->WldPoint[2] = 0;
  this->IjkPoint[0] = 0;
  this->IjkPoint[1] = 0;
  this->IjkPoint[2] = 0;
  this->Seed[0] = 0;
  this->Seed[1] = 0;
  this->Seed[2] = 0;
  this->Seed2D[0] = 0;
  this->Seed2D[1] = 0;
  this->Seed2D[2] = 0;
  this->ReformatPoint[0] = 0;
  this->ReformatPoint[1] = 0;

  this->BuildLowerTime.Modified();
  this->BuildUpperTime.Modified();
 
  // >> Bouix 4/23/03 use old approach for the Zoom. 
  // >> AT 3/26/01 11/07/01
  // Use the original approach by default.
  //this->DrawDoubleApproach = 0;

  // jc - 4.21.05
  //this->DisplayMethod=2; // method 1 or 2
  this->DisplayMethod=1; // default method is 'old' slicer 
  
  if ((this->DisplayMethod==2)||(this->DisplayMethod==3)) {
    // >> Bouix 4/23/03 use old approach for the Zoom.
    // >> AT 3/26/01 11/07/01
    // Use the original approach by default.
    this->DrawDoubleApproach = 0;  //m2
  }
  else {
    // Should be this one from now (11/07/01)
    this->DrawDoubleApproach = 1;  //m1  
  } 
    
  // << AT 3/26/01 11/07/01
  // << Bouix
  // reformatting additions
  this->VolumesToReformat = vtkCollection::New();
  this->VolumeReformatters = vtkVoidArray::New();
  this->MaxNumberOfVolumesToReformat = 20;
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
  this->VolumeReformatters->SetNumberOfValues(this->MaxNumberOfVolumesToReformat);
#else
  this->VolumeReformatters->SetNumberOfPointers(this->MaxNumberOfVolumesToReformat);
#endif
  for (int i = 0; i < this->MaxNumberOfVolumesToReformat; i++)
    {
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      this->VolumeReformatters->SetValue(i,NULL);
#else
      this->VolumeReformatters->SetVoidPointer(i,NULL);
#endif
    }

  // Active slice has polygon drawing (return with GetActiveOutput)
  this->SetActiveSlice(0);

  this->Update();
}

//----------------------------------------------------------------------------
vtkMrmlSlicer::~vtkMrmlSlicer()
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->BackReformat[s]->Delete();
      this->ForeReformat[s]->Delete();
      this->LabelReformat[s]->Delete();
    this->Overlay[s]->Delete();
    this->BackMapper[s]->Delete();
    this->ForeMapper[s]->Delete();
    this->LabelMapper[s]->Delete();

    // >> AT 11/09/01
    this->BackReformat3DView[s]->Delete();
    this->ForeReformat3DView[s]->Delete();
    this->LabelReformat3DView[s]->Delete();
    this->Overlay3DView[s]->Delete();
    this->BackMapper3DView[s]->Delete();
    this->ForeMapper3DView[s]->Delete();
    this->LabelMapper3DView[s]->Delete();
    this->LabelOutline3DView[s]->Delete();
    // << AT 11/09/01

      this->ReformatMatrix[s]->Delete();
      this->LabelOutline[s]->Delete();
      this->Cursor[s]->Delete();
      this->Zoom[s]->Delete();
      this->Double[s]->Delete();

    // Unregister objects others allocated

    if (this->BackVolume[s] != NULL) 
    {
      this->BackVolume[s]->UnRegister(this);
    }
    if (this->ForeVolume[s] != NULL) 
    {
      this->ForeVolume[s]->UnRegister(this);
    }
    if (this->LabelVolume[s] != NULL) 
    {
      this->LabelVolume[s]->UnRegister(this);
    }

    if (this->FirstFilter[s] != NULL) 
    {
      this->FirstFilter[s]->UnRegister(this);
    }
    if (this->LastFilter[s] != NULL) 
    {
      this->LastFilter[s]->UnRegister(this);
    }
  }
  this->PolyDraw->Delete();
  this->AxiPolyStack->Delete();
  this->AxiRasPolyStack->Delete();
  this->SagPolyStack->Delete();
  this->SagRasPolyStack->Delete();
  this->CorPolyStack->Delete();
  this->CorRasPolyStack->Delete();
  this->rasPts->Delete();
  this->CopyPoly->Delete();
  this->DrawIjkPoints->Delete();
  this->ReformatIJK->Delete();

  // Unregister objects others allocated
  if (this->LabelIndirectLUT)
  {
    this->LabelIndirectLUT->UnRegister(this);
  }

  // Signal that we're no longer using it
  if (this->NoneVolume != NULL) 
  {
    this->NoneVolume->UnRegister(this);
  }
  if (this->NoneNode != NULL) 
  {
    this->NoneNode->UnRegister(this);
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSlicer::PrintSelf(ostream& os, vtkIndent indent)
{
  int s;
  
  this->vtkObject::PrintSelf(os, indent);

  os << indent << "FOV:             " << this->FieldOfView << "\n";
  os << indent << "BuildLower Time: " <<this->BuildLowerTime.GetMTime()<<"\n";
  os << indent << "BuildUpper Time: " <<this->BuildUpperTime.GetMTime()<<"\n";
  os << indent << "Update Time:     " <<this->UpdateTime.GetMTime() << "\n";
  os << indent << "Active Slice:    " <<this->ActiveSlice << "\n";
  os << indent << "ForeOpacity:     " <<this->ForeOpacity << "\n";

  // vtkSetObjectMacro
  os << indent << "NoneVolume: " << this->NoneVolume << "\n";
  if (this->NoneVolume)
  {
    this->NoneVolume->PrintSelf(os,indent.GetNextIndent());
  }
  os << indent << "NoneNode: " << this->NoneNode << "\n";
  if (this->NoneNode)
  {
    this->NoneNode->PrintSelf(os,indent.GetNextIndent());
  }
  os << indent << "LabelIndirectLUT: " << this->LabelIndirectLUT << "\n";
  if (this->LabelIndirectLUT)
  {
    this->LabelIndirectLUT->PrintSelf(os,indent.GetNextIndent());
  }

  for (s=0; s<NUM_SLICES; s++)
  {
    os << indent << "BackVolume: " << s << " " << this->BackVolume[s] << "\n";
    if (this->BackVolume[s])
    {
      this->BackVolume[s]->PrintSelf(os,indent.GetNextIndent());
    }
    os << indent << "ForeVolume: " << s << " " << this->ForeVolume[s] << "\n";
    if (this->ForeVolume[s])
    {
      this->ForeVolume[s]->PrintSelf(os,indent.GetNextIndent());
    }
    os << indent << "LabelVolume: " << s << " " << this->LabelVolume[s] << "\n";
    if (this->LabelVolume[s])
    {
      this->LabelVolume[s]->PrintSelf(os,indent.GetNextIndent());
    }
    os << indent << "FirstFilter: " << s << " " << this->FirstFilter[s] << "\n";
    if (this->FirstFilter[s])
    {
      this->FirstFilter[s]->PrintSelf(os,indent.GetNextIndent());
    }
    os << indent << "LastFilter:  " << s << " " << this->LastFilter[s] << "\n";
    if (this->LastFilter[s])
    {
      this->LastFilter[s]->PrintSelf(os,indent.GetNextIndent());
    }
    os << indent << "DoubleSliceSize: " << s << " " << this->DoubleSliceSize[s] << "\n";
  }
}

//----------------------------------------------------------------------------
void vtkMrmlSlicer::DeepCopy(vtkMrmlSlicer *src)
{

  //  vtkMrmlSlicer *src = vtkMrmlSlicer::SafeDownCast(dataObject);
  
  // in case we were not passed a slicer object
  if ( src != NULL) 
    {
      this->ZoomCenter0[0] = src->ZoomCenter0[0];
      this->ZoomCenter0[1] = src->ZoomCenter0[1];
      this->ZoomCenter1[0] = src->ZoomCenter1[0];
      this->ZoomCenter1[1] = src->ZoomCenter1[1];
      this->ZoomCenter2[0] = src->ZoomCenter2[0];
      this->ZoomCenter2[1] = src->ZoomCenter2[1];

      //This updates the FOV for the reformatters
      this->SetFieldOfView(src->FieldOfView);

      this->LabelIndirectLUT = src->LabelIndirectLUT;
      // these deep copies are not implemented
      //this->PolyDraw->DeepCopy(src->PolyDraw);
      //this->ReformatIJK->DeepCopy(src->ReformatIJK);
      this->DrawIjkPoints->DeepCopy(src->DrawIjkPoints);

      for (int s=0; s<NUM_SLICES; s++)
      {
          this->ReformatMatrix[s]->DeepCopy(src->ReformatMatrix[s]);

          // Lower Pipeline

          // Volumes
          this->SetBackVolume(s, src->GetBackVolume(s));
          this->SetForeVolume(s, src->GetForeVolume(s));
          this->SetLabelVolume(s, src->GetLabelVolume(s));

          // Reformatters: set matrices to new ones
          this->BackReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);
          this->ForeReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);
          this->LabelReformat[s]->SetReformatMatrix(this->ReformatMatrix[s]);

          // the newer reformatters>> AT 11/09/01
          this->BackReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);
          this->ForeReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);
          this->LabelReformat3DView[s]->SetReformatMatrix(this->ReformatMatrix[s]);
          // << AT 11/09/01

          // Overlays
          this->ForeOpacity = src->ForeOpacity;
          this->Overlay[s]->SetOpacity(1, this->ForeOpacity);
          this->Overlay3DView[s]->SetOpacity(1, this->ForeOpacity);

          // Upper Pipeline

          // Offset and Orient
          this->Driver[s] = src->Driver[s];
          this->SetOrient(s, src->Orient[s]);

          // Filter: don't worry about this now
          //this->FirstFilter[s] = NULL;
          //this->LastFilter[s] = NULL;
      }
      
      //this->BackFilter = 0;
      //this->ForeFilter = 0;
      //this->FilterActive = 0;
      //this->FilterOverlay = 0;

      // Matrix
      this->DirN[0] = src->DirN[0];
      this->DirN[1] = src->DirN[1];
      this->DirN[2] = src->DirN[2];
      this->DirT[0] = src->DirT[0];
      this->DirT[1] = src->DirT[1];
      this->DirT[2] = src->DirT[2];
      this->DirP[0] = src->DirP[0];
      this->DirP[1]  =src->DirP[1];
      this->DirP[2] = src->DirP[2];
      this->CamN[0] = src->CamN[0];
      this->CamN[1] = src->CamN[1];
      this->CamN[2] = src->CamN[2];
      this->CamT[0] = src->CamT[0];
      this->CamT[1] = src->CamT[1];
      this->CamT[2] = src->CamT[2];
      this->CamP[0] = src->CamP[0];
      this->CamP[1] = src->CamP[1];
      this->CamP[2] = src->CamP[2];
      
      
      // ignore user-defined matrix for now
      //this->NewOrientP[ss][2] = 0;
      
      this->BuildLowerTime.Modified();
      this->BuildUpperTime.Modified();
      
      // Active slice has polygon drawing (return with GetActiveOutput)
      this->SetActiveSlice(src->ActiveSlice);
    }
}
// jc June 2005 - moved the definition from *.h to here
//----------------------------------------------------------------------------
void  vtkMrmlSlicer::SetDouble(int s, int yes) {
    if(this->DrawDoubleApproach == 0)
    {
        this->DoubleSliceSize[s] = yes;
        this->BackReformat[s]->SetResolution(256);
        this->ForeReformat[s]->SetResolution(256);
        this->LabelReformat[s]->SetResolution(256);
    }
    else
    {
        this->DoubleSliceSize[s] = 0;
        vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) this->BackVolume[s]->GetMrmlNode();
        int *dimension =node->GetDimensions();
        int resolution;
        if (dimension[0]>dimension[1]){
            resolution = dimension[0];
        }
        else {
            resolution= dimension[1];
        }
        if(yes == 1)
        {
            
            if (resolution>512){
                this->BackReformat[s]->SetResolution( 1024);
                this->ForeReformat[s]->SetResolution( 1024);
                this->LabelReformat[s]->SetResolution(1024);
            }
            else
                if (resolution>256){
                    this->BackReformat[s]->SetResolution( 512);
                    this->ForeReformat[s]->SetResolution( 512);
                    this->LabelReformat[s]->SetResolution(512);
                }
                else{
                    this->DoubleSliceSize[s] = yes;
                    this->BackReformat[s]->SetResolution(256);
                    this->ForeReformat[s]->SetResolution(256);
                    this->LabelReformat[s]->SetResolution(256);
                }
        }
        else if (yes == 0)
        {
            this->BackReformat[s]->SetResolution(256);
            this->ForeReformat[s]->SetResolution(256);
            this->LabelReformat[s]->SetResolution(256);
        }
        else if (yes == 2)
        {
            //hack for vga mode, 640x480 screen with 160x160 slices
            this->BackReformat[s]->SetResolution(160);
            this->ForeReformat[s]->SetResolution(160);
            this->LabelReformat[s]->SetResolution(160);
        }
    }
    
    this->BuildLowerTime.Modified();
}
//----------------------------------------------------------------------------

void vtkMrmlSlicer::SetNoneVolume(vtkMrmlDataVolume *vol)
{
  int s;
  
  // Only act if this is a different vtkMrmlDataVolume
  if (this->NoneVolume != vol) 
  {
    for (s=0; s<NUM_SLICES; s++)
    {
      if (this->ForeVolume[s] == this->NoneVolume ||
        this->ForeVolume[s] == NULL)
      {
        this->SetForeVolume(s, vol);
      }
      if (this->BackVolume[s] == this->NoneVolume ||
        this->BackVolume[s] == NULL)
      {
        this->SetBackVolume(s, vol);
      }
      if (this->LabelVolume[s] == this->NoneVolume ||
        this->LabelVolume[s] == NULL)
      {
        this->SetLabelVolume(s, vol);
      }
    }

    if (this->NoneVolume != NULL) 
    {
      this->NoneVolume->UnRegister(this);
    }
    this->NoneVolume = vol;

    if (this->NoneVolume != NULL) 
    {
      this->NoneVolume->Register(this);
    }

    // Node
    if (this->NoneNode != NULL) 
    {
      this->NoneNode->UnRegister(this);
    }

    if (vol != NULL) 
    {
      this->NoneNode = (vtkMrmlVolumeNode *) vol->GetMrmlNode();
    }
    else
    {
      this->NoneNode = NULL;
    }

    if (this->NoneNode != NULL) 
    {
      this->NoneNode->Register(this);
    }

    // Refresh pointers

    this->Modified();
    this->BuildUpperTime.Modified();
  }
}

//----------------------------------------------------------------------------
// IsOrientIJK
//----------------------------------------------------------------------------
int vtkMrmlSlicer::IsOrientIJK(int s)
{
  if (
    this->Orient[s] == MRML_SLICER_ORIENT_ORIGSLICE ||
      this->Orient[s] == MRML_SLICER_ORIENT_AXISLICE ||
      this->Orient[s] == MRML_SLICER_ORIENT_CORSLICE ||
      this->Orient[s] == MRML_SLICER_ORIENT_SAGSLICE) 
  {
    return 1;
  }
  return 0;
}

//----------------------------------------------------------------------------
// GetIJKVolume
//----------------------------------------------------------------------------
vtkMrmlDataVolume* vtkMrmlSlicer::GetIJKVolume(int s)
{
  if (this->BackVolume[s] != this->NoneVolume)
  {
    return this->BackVolume[s];
  }
  if (this->ForeVolume[s] != this->NoneVolume)
  {
    return this->ForeVolume[s];
  }
 
  if (this->LabelVolume[s] != this->NoneVolume)
  {
    return this->LabelVolume[s];
  }
  return this->NoneVolume;
}

vtkImageReformat* vtkMrmlSlicer::GetIJKReformat(int s)
{
  if (this->BackVolume[s] != this->NoneVolume)
  {
    return this->BackReformat[s];
  }
  if (this->ForeVolume[s] != this->NoneVolume)
  {
    return this->ForeReformat[s];
  }
  if (this->LabelVolume[s] != this->NoneVolume)
  {
    return this->LabelReformat[s];
  }
  return this->BackReformat[2];
}

////////////////////////////////////////////////////////////////////////////////
//                              PIPELINE
////////////////////////////////////////////////////////////////////////////////


//----------------------------------------------------------------------------
// Update
//----------------------------------------------------------------------------
void vtkMrmlSlicer::Update()
{
  int s;
  
  // Do we need to rebuild the pipeline?
  if (this->BuildUpperTime > this->UpdateTime)
  {
    for (s=0; s<NUM_SLICES; s++)
    {
      this->BuildUpper(s);
    }
  }
  if (this->BuildLowerTime > this->UpdateTime)
  {
    for (s=0; s<NUM_SLICES; s++)
    {
      this->BuildLower(s);
    }
  }

  this->UpdateTime.Modified();
}

//----------------------------------------------------------------------------
// Active Slice
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetActiveSlice(int s)
{
  // no change
  if (this->ActiveSlice == s)
  {
      return;
  }
  this->ActiveSlice = s;
  this->BuildUpperTime.Modified();
  this->BuildLowerTime.Modified();
  
  // arbitrary reformatting
  this->VolumeReformattersModified();
}

//----------------------------------------------------------------------------
// Background Volume
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetBackVolume(vtkMrmlDataVolume *vol)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->SetBackVolume(s, vol);
  }
}
void vtkMrmlSlicer::SetBackVolume(int s, vtkMrmlDataVolume *vol)
{
  if (this->BackVolume[s] != vol) 
  {
    if (this->BackVolume[s] != NULL) 
    { 
      this->BackVolume[s]->UnRegister(this); 
    }
    this->BackVolume[s] = vol;
    if (this->BackVolume[s] != NULL) 
    { 
      this->BackVolume[s]->Register(this); 
    }

    this->Modified(); 
    this->BuildUpperTime.Modified();
  } 
}

//----------------------------------------------------------------------------
// Foreground Volume
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetForeVolume(vtkMrmlDataVolume *vol)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->SetForeVolume(s, vol);
  }
}
void vtkMrmlSlicer::SetForeVolume(int s, vtkMrmlDataVolume *vol)
{
  if (this->ForeVolume[s] != vol) 
  {
    if (this->ForeVolume[s] != NULL) 
    { 
      this->ForeVolume[s]->UnRegister(this); 
    }
    this->ForeVolume[s] = vol;
    if (this->ForeVolume[s] != NULL) 
    { 
      this->ForeVolume[s]->Register(this); 
    }
    this->Modified(); 
    this->BuildUpperTime.Modified();
  } 
}

//----------------------------------------------------------------------------
// Label Volume
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetLabelVolume(vtkMrmlDataVolume *vol)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->SetLabelVolume(s, vol);
  }
}
void vtkMrmlSlicer::SetLabelVolume(int s, vtkMrmlDataVolume *vol)
{
  if (this->LabelVolume[s] != vol) 
  {
    if (this->LabelVolume[s] != NULL) 
    { 
      this->LabelVolume[s]->UnRegister(this); 
    }
    this->LabelVolume[s] = vol;
    if (this->LabelVolume[s] != NULL) 
    { 
      this->LabelVolume[s]->Register(this); 
    }
    this->Modified(); 
    this->BuildUpperTime.Modified();
  } 
}

//----------------------------------------------------------------------------
// Filter 
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetFirstFilter(int s, vtkObject *filter)
{
    // for vtk 4.x and 5.x compatibility, see notes in vtkSlicer.h
#ifdef SLICER_VTK5
    vtkImageAlgorithm *ia = vtkImageAlgorithm::SafeDownCast(filter);
    if (ia)
    {
        if (this->FirstFilter[s] != ia) 
        {
            if (this->FirstFilter[s] != NULL) 
            { 
                this->FirstFilter[s]->UnRegister(this); 
            }
            this->FirstFilter[s] = ia;
        }
    } else {
        vtkImageToImageFilter *itoi = vtkImageToImageFilter::SafeDownCast(filter);
        if (itoi)
        {
            if (this->FirstFilter[s] != itoi) 
            {
                if (this->FirstFilter[s] != NULL) 
                { 
                    this->FirstFilter[s]->UnRegister(this); 
                }
                this->FirstFilter[s] = itoi;
                if (this->FirstFilter[s] != NULL) 
                { 
                    this->FirstFilter[s]->Register(this); 
                }
                this->Modified(); 
                this->BuildUpperTime.Modified();
            }
        }
        else
        {
            vtkGenericWarningMacro( "Problem executing SetFirstFilter: filter isn't one of vtkImageAlgorithm or vtkImageToImageFilter");
            return;
        }
    }
#else
    vtkImageToImageFilter *itoi = vtkImageToImageFilter::SafeDownCast(filter);
    if (itoi)
    {
        if (this->FirstFilter[s] != itoi) 
        {
            if (this->FirstFilter[s] != NULL) 
            { 
                this->FirstFilter[s]->UnRegister(this); 
            }
            this->FirstFilter[s] = itoi;
            if (this->FirstFilter[s] != NULL) 
            { 
                this->FirstFilter[s]->Register(this); 
            }
            this->Modified(); 
            this->BuildUpperTime.Modified();
        }
    }
    else
    {
        vtkGenericWarningMacro( "Problem executing SetFirstFilter: filter isn't vtkImageToImageFilter");
        return;
    }
#endif

}
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetLastFilter(int s, vtkImageSource *filter)
{
  if (this->LastFilter[s] != filter) 
  {
    if (this->LastFilter[s] != NULL) 
    { 
      this->LastFilter[s]->UnRegister(this); 
    }
    this->LastFilter[s] = filter;
    if (this->LastFilter[s] != NULL) 
    { 
      this->LastFilter[s]->Register(this); 
    }
    this->Modified(); 
    this->BuildUpperTime.Modified();
  } 
}

//----------------------------------------------------------------------------
// BuildUpper
//----------------------------------------------------------------------------
void vtkMrmlSlicer::BuildUpper(int s)
{
  vtkMrmlDataVolume *v;
  int filter = 0;

  // Error checking
  if (this->NoneVolume == NULL)
  {
    vtkErrorMacro(<<"BuildUpper: NULL NoneVolume");
    return;
  }

  // if we are displaying filter output over a slice, AND
  // either this slice is the only one we are filtering
  // OR we are filtering all slices, then make sure the filter is set.
  if ((this->BackFilter || this->ForeFilter) && 
     ((this->FilterActive && s == this->ActiveSlice) || !this->FilterActive))
  {
    filter = 1;
    if ( this->FirstFilter[s] == NULL )
    {
      vtkErrorMacro(<<"Apply: FirstFilter not set: " << s);
      return;
    }
    if ( this->LastFilter[s] == NULL )
    {
      vtkErrorMacro(<<"Apply: LastFilter not set: " << s);
      return;
    }
  }

  // Back Layer
  /////////////////////////////////////////////////////
  
  v = this->BackVolume[s];
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) v->GetMrmlNode();

  // Reformatter
  this->BackReformat[s]->SetInput(v->GetOutput());
  this->BackReformat[s]->SetInterpolate(node->GetInterpolate());
  this->BackReformat[s]->SetWldToIjkMatrix(node->GetWldToIjk());

  // >> AT 11/09/01
  this->BackReformat3DView[s]->SetInput(v->GetOutput());
  this->BackReformat3DView[s]->SetInterpolate(node->GetInterpolate());
  this->BackReformat3DView[s]->SetWldToIjkMatrix(node->GetWldToIjk());
  // << AT 11/09/01

  // If data has more than one scalar component, then don't use the mapper,
  if (v->GetOutput()->GetNumberOfScalarComponents() > 1)
  {
    // Overlay
    this->Overlay[s]->SetInput(0, this->BackReformat[s]->GetOutput());
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetInput(0, this->BackReformat3DView[s]->GetOutput());
    // << AT 11/09/01
  }
  else 
  {
    // Mapper
    this->BackMapper[s]->SetInput(this->BackReformat[s]->GetOutput());
    this->BackMapper[s]->SetLookupTable(v->GetIndirectLUT());
    // Overlay
    this->Overlay[s]->SetInput(0, this->BackMapper[s]->GetOutput());

    // >> AT 11/09/01
    this->BackMapper3DView[s]->SetInput(this->BackReformat3DView[s]->GetOutput());
    this->BackMapper3DView[s]->SetLookupTable(v->GetIndirectLUT());
    this->Overlay3DView[s]->SetInput(0, this->BackMapper3DView[s]->GetOutput());
    // << AT 11/09/01
  }  


  // Fore Layer
  /////////////////////////////////////////////////////
  
  v = this->ForeVolume[s];
  node = (vtkMrmlVolumeNode*) v->GetMrmlNode();

  // If the None volume, then turn the Fore input off
  if (v == this->NoneVolume) 
  {
#ifdef SLICER_VTK5
    this->Overlay[s]->SetInput(1, this->NoneVolume->GetOutput());
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetInput(1, this->NoneVolume->GetOutput());
    // << AT 11/09/01
#else
    this->Overlay[s]->SetInput(1, NULL);
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetInput(1, NULL);
    // << AT 11/09/01
#endif
  } 
  else 
  {
    // Reformatter
    this->ForeReformat[s]->SetInput(v->GetOutput());
    this->ForeReformat[s]->SetInterpolate(node->GetInterpolate());
    this->ForeReformat[s]->SetWldToIjkMatrix(node->GetWldToIjk());

    // >> AT 11/09/01
    this->ForeReformat3DView[s]->SetInput(v->GetOutput());
    this->ForeReformat3DView[s]->SetInterpolate(node->GetInterpolate());
    this->ForeReformat3DView[s]->SetWldToIjkMatrix(node->GetWldToIjk());
    // << AT 11/09/01

    // If data has more than one scalar component, then don't use the mapper,
    if (v->GetOutput()->GetNumberOfScalarComponents() > 1)
    {
      // jc - 4.21.05 
      // Overlay
      if (this->DisplayMethod==1) {
        // >> Bouix 4/23/03 change input to 1 for the overlay was 0..
        this->Overlay[s]      ->SetInput(1, this->ForeReformat[s]->GetOutput());
        // >> AT 11/09/01
        this->Overlay3DView[s]->SetInput(1, this->ForeReformat3DView[s]->GetOutput());
        // << AT 11/09/01
        // << Bouix
      }
      if ((this->DisplayMethod==2)||(this->DisplayMethod==3)) {
        this->Overlay[s]      ->SetInput(0, this->ForeReformat[s]->GetOutput());
        this->Overlay3DView[s]->SetInput(0, this->ForeReformat3DView[s]->GetOutput());
      }
    }
    else 
    {
      // Active filter?
      if (filter)
      {
    // Filter
        if (this->ForeFilter)
        {
          SetImageInput(this->FirstFilter[s],this->ForeReformat[s]->GetOutput());
        }
        else
        {
          SetImageInput(this->FirstFilter[s],this->BackReformat[s]->GetOutput());
        }
    // Mapper
    if (this->FilterOverlay)
      {
        // If filter is being overlayed in label layer,
        // don't display the filter's output in the fore layer.
        this->ForeMapper[s]->SetInput(this->ForeReformat[s]->GetOutput());
      }
    else
      {
        // default display: just replace fore layer with filter output
        this->ForeMapper[s]->SetInput(this->LastFilter[s]->GetOutput());
      }
      } // end if filter
      else 
      {
        // Mapper
        this->ForeMapper[s]->SetInput(this->ForeReformat[s]->GetOutput());
      }
      // Mapper
      this->ForeMapper[s]->SetLookupTable(v->GetIndirectLUT());
      // Overlay
      this->Overlay[s]->SetInput(1, this->ForeMapper[s]->GetOutput());

      // >> AT 11/09/01
      this->ForeMapper3DView[s]->SetInput(this->ForeReformat3DView[s]->GetOutput());
      this->ForeMapper3DView[s]->SetLookupTable(v->GetIndirectLUT());
      this->Overlay3DView[s]->SetInput(1, this->ForeMapper3DView[s]->GetOutput());
      // << AT 11/09/01
    } 
  }


  // Label Layer
  /////////////////////////////////////////////////////
    
  v = this->LabelVolume[s];
  node = (vtkMrmlVolumeNode*) v->GetMrmlNode();

  // If the None volume, then turn the Label input off
  if (v == this->NoneVolume) 
  {
#ifdef SLICER_VTK5
    this->Overlay[s]->SetInput(2, this->NoneVolume->GetOutput());
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetInput(2, this->NoneVolume->GetOutput());
    // << AT 11/09/01
#else
    this->Overlay[s]->SetInput(2, NULL);
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetInput(2, NULL);
    // << AT 11/09/01
#endif
  }
  else
  {
    // If ForeVolume == LabelVolume, then save reformatting work
    if (v == this->ForeVolume[s])
    {
      if (filter)
      {
        // Outline
    this->LabelOutline[s]->SetInput(this->LastFilter[s]->GetOutput());
      }
      else 
      {
        // Outline
        this->LabelOutline[s]->SetInput(this->ForeReformat[s]->GetOutput());
      }
      // Overlay
      this->LabelMapper[s]->SetInput(this->LabelOutline[s]->GetOutput());
      this->Overlay[s]->SetInput(2, this->LabelMapper[s]->GetOutput());
    }
    else
    {
      // Reformatter
      this->LabelReformat[s]->SetInput(v->GetOutput());
      this->LabelReformat[s]->InterpolateOff(); // never interpolate label
      this->LabelReformat[s]->SetWldToIjkMatrix(node->GetWldToIjk());

      // Outline
      this->LabelOutline[s]->SetInput(this->LabelReformat[s]->GetOutput());

      // Overlay
      this->LabelMapper[s]->SetInput(this->LabelOutline[s]->GetOutput());
      this->Overlay[s]->SetInput(2, this->LabelMapper[s]->GetOutput());
    }

    // >> AT 11/09/01
    this->LabelReformat3DView[s]->SetInput(v->GetOutput());
    this->LabelReformat3DView[s]->InterpolateOff(); // never interpolate label
    this->LabelReformat3DView[s]->SetWldToIjkMatrix(node->GetWldToIjk());
    // We don't care about filters in 3D View
    this->LabelOutline3DView[s]->SetInput(this->LabelReformat3DView[s]->GetOutput());
    this->LabelMapper3DView[s]->SetInput(this->LabelOutline3DView[s]->GetOutput());
    //    this->Overlay3DView[s]->SetInput(2, this->LabelMapper3DView[s]->GetOutput());
    this->Overlay3DView[s]->SetInput(2, this->LabelMapper3DView[s]->GetOutput());
    // << AT 11/09/01
  }

  // The IJK reformatting depends on the volumes
  /////////////////////////////////////////////////////

  // Reset the offset range.
  // If the range changed, then reset the offset to be
  // in the center of this new range.
  this->ComputeOffsetRangeIJK(s);
    
  // IJK Orientations depends on volumes
  if (this->IsOrientIJK(s))
  {
    this->ComputeReformatMatrix(s);
  }

}

//----------------------------------------------------------------------------
// BuildLower
//----------------------------------------------------------------------------
void vtkMrmlSlicer::BuildLower(int s)
{
  int mode;

  // InActive Slices:
  //
  // 1.) Overlay --> Cursor
  // 2.) Overlay --> Zoom   --> Cursor
  // 3.) Overlay --> Double --> Cursor
  // 4.) Overlay --> Zoom   --> Double --> Cursor
  //
  // Active Slice:
  //
  // 1.) Overlay --> PolyDraw --> Cursor
  // 2.) Overlay --> PolyDraw --> Zoom   --> Cursor
  // 3.) Overlay --> PolyDraw --> Double --> Cursor
  // 4.) Overlay --> PolyDraw --> Zoom   --> Double --> Cursor
      
  vtkFloatingPointType ctr[2];
  this->Zoom[s]->GetCenter(ctr);
  if (this->Zoom[s]->GetMagnification() != 1.0 || 
    this->Zoom[s]->GetAutoCenter() == 0 ||
    (ctr[0] == 0.0 && ctr[1] == 0.0))
  {
    mode = (this->DoubleSliceSize[s] == 1) ? 4 : 2;
  } 
  else 
  {
    mode = (this->DoubleSliceSize[s] == 1) ? 3 : 1;
  }

  if (this->ActiveSlice == s)
  {
  //Karl - 5.18.05
    switch (mode)
      {
    case 1:
      this->PolyDraw->SetInput(this->Overlay[s]->GetOutput());
      if (this->DisplayMethod==2)
        this->PolyDraw->SetImageReformat(this->BackReformat[s]);
        
      this->Cursor[s]->SetInput(this->PolyDraw->GetOutput());
      break;
    case 2:
      this->PolyDraw->SetInput(this->Overlay[s]->GetOutput());
       if (this->DisplayMethod==2)
        this->PolyDraw->SetImageReformat(this->BackReformat[s]);
        
      this->Zoom[s]->SetInput(this->PolyDraw->GetOutput());
      this->Cursor[s]->SetInput(this->Zoom[s]->GetOutput());
      break;
    case 3:
      this->PolyDraw->SetInput(this->Overlay[s]->GetOutput());
       if (this->DisplayMethod==2)
        this->PolyDraw->SetImageReformat(this->BackReformat[s]);
        
      this->Double[s]->SetInput(this->PolyDraw->GetOutput());
      this->Cursor[s]->SetInput(this->Double[s]->GetOutput());
      break;
    case 4:
      this->PolyDraw->SetInput(this->Overlay[s]->GetOutput());
       if (this->DisplayMethod==2)
        this->PolyDraw->SetImageReformat(this->BackReformat[s]);
        
      this->Zoom[s]->SetInput(this->PolyDraw->GetOutput());
      this->Double[s]->SetInput(this->Zoom[s]->GetOutput());
      this->Cursor[s]->SetInput(this->Double[s]->GetOutput());
      break;
      }
  }
  else
  {
    switch (mode)
      {
    case 1:
      this->Cursor[s]->SetInput(this->Overlay[s]->GetOutput());
        break;
    case 2:
      this->Zoom[s]->SetInput(this->Overlay[s]->GetOutput());
      this->Cursor[s]->SetInput(this->Zoom[s]->GetOutput());
      break;
    case 3:
        this->Double[s]->SetInput(this->Overlay[s]->GetOutput());
      this->Cursor[s]->SetInput(this->Double[s]->GetOutput());
        break;
    case 4:
      this->Zoom[s]->SetInput(this->Overlay[s]->GetOutput());
      this->Double[s]->SetInput(this->Zoom[s]->GetOutput());
      this->Cursor[s]->SetInput(this->Double[s]->GetOutput());
      break;
      }
  }
}


////////////////////////////////////////////////////////////////////////////////
//                          SLICE OFFSET & ORIENT
////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------
// Offset
//----------------------------------------------------------------------------
void vtkMrmlSlicer::ComputeOffsetRange()
{
  int s, orient;
  vtkFloatingPointType fov = this->FieldOfView / 2.0;

  for (s=0; s<NUM_SLICES; s++)
  {
    for (orient = MRML_SLICER_ORIENT_AXIAL; orient <= MRML_SLICER_ORIENT_PERP;
      orient++)
    {
      this->OffsetRange[s][orient][0] = -fov;
      this->OffsetRange[s][orient][1] =  fov;
      this->Offset[s][orient] = 0;
    }
  }
}

void vtkMrmlSlicer::SetOffsetRange(int s, int orient, int min, int max, int *modified)
{
  if (this->OffsetRange[s][orient][0] != min)
  {
    this->OffsetRange[s][orient][0] = min;
    *modified = 1;
  }
  if (this->OffsetRange[s][orient][1] != max)
  {
    this->OffsetRange[s][orient][1] = max;
    *modified = 1;
  }
}

void vtkMrmlSlicer::ComputeOffsetRangeIJK(int s)
{
  int xMax, yMax, zMax, xMin, yMin, zMin, xAvg, yAvg, zAvg, *ext;
  vtkFloatingPointType fov = this->FieldOfView / 2.0;
  int orient = this->GetOrient(s);
  int modified = 0;
  vtkMrmlDataVolume *vol = this->GetIJKVolume(s);
  if (vol == NULL) return;
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) vol->GetMrmlNode();
  char* order = node->GetScanOrder();
  if (order == NULL) return;

  ext = vol->GetOutput()->GetWholeExtent();
  xMin = ext[0];
  yMin = ext[2];
  zMin = ext[4];
  xMax = ext[1];
  yMax = ext[3];
  zMax = ext[5];
  xAvg = (ext[1] + ext[0])/2;
  yAvg = (ext[3] + ext[2])/2;
  zAvg = (ext[5] + ext[4])/2;

  this->OffsetRange[s][MRML_SLICER_ORIENT_ORIGSLICE][0] = zMin;
  this->OffsetRange[s][MRML_SLICER_ORIENT_ORIGSLICE][1] = zMax;

      // sp 2002-10-01 - changed for non square slices to use yMin yMax for 
      // sagittal and coronal ranges.  Tested for Axial (IS) input where coronal
      // dim larger than sagittal dim.  Other branches changed symmetrically,
      // but not tested.
      //
    // Sagittal
  if (!strcmp(order,"LR") || !strcmp(order,"RL")) 
  {
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_AXISLICE, yMin, yMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_SAGSLICE, zMin, zMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_CORSLICE, xMin, xMax, &modified);

    if (modified)
    {
      this->Offset[s][MRML_SLICER_ORIENT_ORIGSLICE] = zAvg;
      this->Offset[s][MRML_SLICER_ORIENT_AXISLICE]  = yAvg;
      this->Offset[s][MRML_SLICER_ORIENT_SAGSLICE]  = zAvg;
      this->Offset[s][MRML_SLICER_ORIENT_CORSLICE]  = xAvg;
    }
  }
  // Coronal
    else if (!strcmp(order,"AP") || !strcmp(order,"PA")) 
  {
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_AXISLICE, yMin, yMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_SAGSLICE, xMin, xMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_CORSLICE, zMin, zMax, &modified);

    if (modified)
    {
      this->Offset[s][MRML_SLICER_ORIENT_ORIGSLICE] = zAvg;
      this->Offset[s][MRML_SLICER_ORIENT_AXISLICE]  = yAvg;
      this->Offset[s][MRML_SLICER_ORIENT_SAGSLICE]  = xAvg;
      this->Offset[s][MRML_SLICER_ORIENT_CORSLICE]  = zAvg;
    }
  }
  // Axial (and oblique)
    else 
  {
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_AXISLICE, zMin, zMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_SAGSLICE, xMin, xMax, &modified);
      this->SetOffsetRange(s, MRML_SLICER_ORIENT_CORSLICE, yMin, yMax, &modified); 

    if (modified)
    {
      this->Offset[s][MRML_SLICER_ORIENT_ORIGSLICE] = zAvg;
      this->Offset[s][MRML_SLICER_ORIENT_AXISLICE]  = zAvg;
      this->Offset[s][MRML_SLICER_ORIENT_SAGSLICE]  = xAvg;
      this->Offset[s][MRML_SLICER_ORIENT_CORSLICE]  = yAvg; 
    }
  }
}

void vtkMrmlSlicer::InitOffset(int s, const char *str, vtkFloatingPointType offset)
{
  int orient = (int) ConvertStringToOrient(str);
  this->Offset[s][orient] = offset;
}

//----------------------------------------------------------------------------
// Orient
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetOrient(int orient)
{
  if (orient == MRML_SLICER_ORIENT_AXISAGCOR) 
  {
      this->SetOrient(0, MRML_SLICER_ORIENT_AXIAL);
      this->SetOrient(1, MRML_SLICER_ORIENT_SAGITTAL);
      this->SetOrient(2, MRML_SLICER_ORIENT_CORONAL);
  } 
  else if (orient == MRML_SLICER_ORIENT_SLICES) 
  {
      this->SetOrient(0, MRML_SLICER_ORIENT_AXISLICE);
      this->SetOrient(1, MRML_SLICER_ORIENT_SAGSLICE);
      this->SetOrient(2, MRML_SLICER_ORIENT_CORSLICE);
  } 
  else if (orient == MRML_SLICER_ORIENT_ORTHO) 
  {
      this->SetOrient(0, MRML_SLICER_ORIENT_PERP);
      this->SetOrient(1, MRML_SLICER_ORIENT_INPLANE);
      this->SetOrient(2, MRML_SLICER_ORIENT_INPLANE90);
  }
  if (orient == MRML_SLICER_ORIENT_REFORMAT_AXISAGCOR) 
    {
      this->SetOrient(0, MRML_SLICER_ORIENT_REFORMAT_AXIAL);
      this->SetOrient(1, MRML_SLICER_ORIENT_REFORMAT_SAGITTAL);
      this->SetOrient(2, MRML_SLICER_ORIENT_REFORMAT_CORONAL);
    } 
}

void vtkMrmlSlicer::SetOrient(int s, int orient)
{
  this->Orient[s] = orient;

  this->ComputeReformatMatrix(s);
}

void vtkMrmlSlicer::SetOrientString(const char *str)
{
  if (strcmp(str, "AxiSagCor") == 0)
       this->SetOrient(MRML_SLICER_ORIENT_AXISAGCOR);
  else if (strcmp(str, "Orthogonal") == 0)
       this->SetOrient(MRML_SLICER_ORIENT_ORTHO);
  else if (strcmp(str, "Slices") == 0)
       this->SetOrient(MRML_SLICER_ORIENT_SLICES);
  else if (strcmp(str, "ReformatAxiSagCor") == 0)
       this->SetOrient(MRML_SLICER_ORIENT_REFORMAT_AXISAGCOR);
  else
       this->SetOrient(MRML_SLICER_ORIENT_AXISAGCOR);
}

const char* vtkMrmlSlicer::GetOrientString(int s)
{
  return ConvertOrientToString(this->Orient[s]);
}

void vtkMrmlSlicer::SetOrientString(int s, const char *str)
{
  int orient = ConvertStringToOrient(str);
  this->SetOrient(s, orient);
}

int vtkMrmlSlicer::ConvertStringToOrient(const char *str)
{
  if      (strcmp(str, "Axial") == 0)
       return MRML_SLICER_ORIENT_AXIAL;
  else if (strcmp(str, "Sagittal") == 0)
       return MRML_SLICER_ORIENT_SAGITTAL;
  else if (strcmp(str, "Coronal") == 0)
       return MRML_SLICER_ORIENT_CORONAL;
  else if (strcmp(str, "InPlane") == 0)
       return MRML_SLICER_ORIENT_INPLANE;
  else if (strcmp(str, "InPlane90") == 0)
       return MRML_SLICER_ORIENT_INPLANE90;
  else if (strcmp(str, "InPlaneNeg90") == 0)
       return MRML_SLICER_ORIENT_INPLANENEG90;
  else if (strcmp(str, "Perp") == 0)
       return MRML_SLICER_ORIENT_PERP;
  else if (strcmp(str, "OrigSlice") == 0)
       return MRML_SLICER_ORIENT_ORIGSLICE;
  else if (strcmp(str, "AxiSlice") == 0)
       return MRML_SLICER_ORIENT_AXISLICE;
  else if (strcmp(str, "CorSlice") == 0)
       return MRML_SLICER_ORIENT_CORSLICE;
  else if (strcmp(str, "SagSlice") == 0)
       return MRML_SLICER_ORIENT_SAGSLICE;
  else if (strcmp(str, "NewOrient") == 0)
       return MRML_SLICER_ORIENT_NEW_ORIENT;
  else if (strcmp(str, "ReformatAxial") == 0)
       return MRML_SLICER_ORIENT_REFORMAT_AXIAL;
  else if (strcmp(str, "ReformatSagittal") == 0)
          return MRML_SLICER_ORIENT_REFORMAT_SAGITTAL;
  else if (strcmp(str, "ReformatCoronal") == 0)
       return MRML_SLICER_ORIENT_REFORMAT_CORONAL;

  else
       return MRML_SLICER_ORIENT_AXIAL;
}

const char* vtkMrmlSlicer::ConvertOrientToString(int orient)
{
  switch (orient) 
    {
    case MRML_SLICER_ORIENT_AXIAL:
      return "Axial";
    case MRML_SLICER_ORIENT_SAGITTAL:
      return "Sagittal";
    case MRML_SLICER_ORIENT_CORONAL:
      return "Coronal";
    case MRML_SLICER_ORIENT_INPLANE:
      return "InPlane";
    case MRML_SLICER_ORIENT_INPLANE90:
      return "InPlane90";
    case MRML_SLICER_ORIENT_INPLANENEG90:
      return "InPlaneNeg90";
    case MRML_SLICER_ORIENT_PERP:
      return "Perp";
    case MRML_SLICER_ORIENT_ORIGSLICE:
      return "OrigSlice";
    case MRML_SLICER_ORIENT_AXISLICE:
      return "AxiSlice";
    case MRML_SLICER_ORIENT_CORSLICE:
      return "CorSlice";
    case MRML_SLICER_ORIENT_SAGSLICE:
      return "SagSlice";
    case MRML_SLICER_ORIENT_NEW_ORIENT:
      return "NewOrient";
    case MRML_SLICER_ORIENT_REFORMAT_AXIAL:
      return "ReformatAxial";
    case MRML_SLICER_ORIENT_REFORMAT_SAGITTAL:
      return "ReformatSagittal";
    case MRML_SLICER_ORIENT_REFORMAT_CORONAL:
      return "ReformatCoronal";
        default:
      return "Axial";
  }      
}


////////////////////////////////////////////////////////////////////////////////
//                    REFORMAT
////////////////////////////////////////////////////////////////////////////////


void vtkMrmlSlicer::ComputeReformatMatrixIJK(int s, 
    vtkFloatingPointType offset, vtkMatrix4x4 *ref)
{
  char orderString[3];
  vtkMrmlDataVolume *vol = this->GetIJKVolume(s);
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) vol->GetMrmlNode();


  if (this->IsOrientIJK(s) == 0)
  {
      vtkErrorMacro(<<"ComputeReformatMatrixIJK: orient is "<<this->Orient[s]);
    return;
  }

  switch (this->Orient[s])
  {
    case MRML_SLICER_ORIENT_ORIGSLICE:
      sprintf(orderString, "%s", node->GetScanOrder());
      break;
    case MRML_SLICER_ORIENT_AXISLICE:
      sprintf(orderString, "IS");
      break;
    case MRML_SLICER_ORIENT_SAGSLICE:
      sprintf(orderString, "LR");
      break;
    case MRML_SLICER_ORIENT_CORSLICE:
      sprintf(orderString, "PA");
      break;
  }//switch

  vtkImageReformatIJK *ijk = this->ReformatIJK;
  ijk->SetWldToIjkMatrix(node->GetWldToIjk());
  ijk->SetInput(vol->GetOutput());
  ijk->SetInputOrderString(node->GetScanOrder());
  ijk->SetOutputOrderString(orderString);
  ijk->SetSlice((int)offset);
  ijk->ComputeTransform();
  ijk->ComputeOutputExtent();
  ijk->ComputeReformatMatrix(ref);
}

vtkFloatingPointType vtkMrmlSlicer::GetOffsetForComputation(int s)
{
  vtkFloatingPointType uOff, cOff;
  
  uOff = this->GetOffset(s);

  // Reformatted slices are defined by:
  //   origin = 2D point in lower left of reformatted image
  //   P  = 3D focal point
  //   Ux = 3D vector from origin to right side
  //   Uy = 3D vector from origin to top side
  //   Uz = Ux cross Uy
  //   Up = center of reformatted image = P + offset*Uz
  // For axial slices:
  //   Ux=(-1,0,0) to go from R to L
  //   Uy=( 0,1,0) to go from P to A
  //   therefore:
  //   Uz=(0,0,-1) to go from S to I
  //
  // To allow the user to specify the location of the slice, 
  // we provide a number called "offset" that goes from I to S.
  // Note that this has opposite polarity of the number that one
  // would multiply by Uz to arrive at the center of the slice, Up.
  //
  // It is the user's view of offset that is stored in this object's
  // this->Offset[slice][orient] array.  So the GetOffsetForComputation()
  // function inverts this user's offset in the case of Axial orientation.
  //
  // The full spectrum is as follows: 
  //
  //   Notation: uOff = user's offset for GUI
  //             cOff = offset for computation: Up = P + cOff*Uz
  //
  //   cOff = -uOff whenever uOff and Uz are of opposite polarity
  //   in the table below
  //
  // Orient   Vec  Direction    
  // ---------------------------
  // Axi      Ux   RL (-1, 0, 0)
  //          Uy   PA ( 0, 1, 0)
  //          Uz   SI ( 0, 0,-1)
  //          uOff IS 
  //
  // Sag      Ux   AP ( 0,-1, 0)
  //          Uy   IS ( 0, 0, 1)
  //          Uz   RL (-1, 0, 0)
  //          uOff LR 
  //
  // Cor      Ux   RL (-1, 0, 0)
  //          Uy   IS ( 0, 0, 1)
  //          Uz   PA ( 0, 1, 0)
  //          uOff PA 
  //

  // If the driver is the locator, then the offset is 0
  if (this->Driver[s])
  {
    return 0.0f;
  }

  switch (this->Orient[s])
  {
    case MRML_SLICER_ORIENT_AXIAL:    cOff = -uOff; break;
    case MRML_SLICER_ORIENT_SAGITTAL: cOff = -uOff; break;
    case MRML_SLICER_ORIENT_CORONAL:  cOff =  uOff; break;
    default:                          cOff =  uOff; break;
  }
  return cOff;
}

void vtkMrmlSlicer::SetOffset(int s, vtkFloatingPointType userOffset)
{
  double Uz[3], *P;
  vtkMatrix4x4 *ref = this->ReformatMatrix[s];
  vtkFloatingPointType offset;

  this->Offset[s][this->Orient[s]] = userOffset;
  offset = this->GetOffsetForComputation(s);

  if (this->IsOrientIJK(s))
  {
    this->ComputeReformatMatrixIJK(s, offset, ref);
  }
  else
  {
    Uz[0] = ref->GetElement(0, 2);
    Uz[1] = ref->GetElement(1, 2);
    Uz[2] = ref->GetElement(2, 2);

    P = this->GetP(s);

    for (int i=0; i<3; i++)
    {
      ref->SetElement(i, 3, P[i] + offset * Uz[i]);
    }
    ref->SetElement(3, 3, 1.0);
  }

  // Use reformat matrix for other arbitrary volumes we may be reformatting
  this->VolumeReformattersModified();
}

//----------------------------------------------------------------------------
// Reformat Matrix
//----------------------------------------------------------------------------
void vtkMrmlSlicer::ComputeReformatMatrix(int s)
{
  double Ux[3], Uy[3], Uz[3], *P, *T, *N;
  int i;
  vtkMatrix4x4 *ref = this->ReformatMatrix[s];
  vtkFloatingPointType offset = this->GetOffsetForComputation(s);
  
  P = this->GetP(s);
  N = this->GetN(s);
  T = this->GetT(s);

  // 1.) Create the R rotation matrix.  If the plane's reference frame has
  //     axis Ux, Uy, Uz, then Ux is the left col of R, Uy is the second, etc.
  // 2.) Concatenate a translation, T, from the origin to the plane's center.
  // Then: M = T*R.
  //
  // (See page 419 and 429 of "Computer Graphics", Hearn & Baker, 1997,
  //  ISBN 0-13-530924-7 for more details.)
  //
  // The Ux axis is the vector across the top of the image from left to right.
  // The Uy axis is the vector down the side of the image from top to bottom.
  // The Uz axis is the vector from the focal point to the camera.
  // The rightmost column of the matrix is the offset, P, to the image center.

  // Use the Reformatters convenience functions to form the reformat matrix.
  // The matrix is a function of the scan orientation and slice order of
  // the background volume.
  //
  if (this->IsOrientIJK(s))
  {
    this->ComputeReformatMatrixIJK(s, offset, ref);
  }
  //
  // Compute reformat matrix from N, T, P
  // 
  else
  {
    switch (this->Orient[s])
      {
    case MRML_SLICER_ORIENT_AXIAL:
      Ux[0] = -1.0;
      Ux[1] =  0.0;
      Ux[2] =  0.0;
      Uy[0] =  0.0;
      Uy[1] =  1.0;
      Uy[2] =  0.0;
      break;

    case MRML_SLICER_ORIENT_SAGITTAL:
      Ux[0] =  0.0;
      Ux[1] = -1.0;
      Ux[2] =  0.0;
      Uy[0] =  0.0;
      Uy[1] =  0.0;
      Uy[2] =  1.0;
      break;

    case MRML_SLICER_ORIENT_CORONAL:
      Ux[0] = -1.0;
      Ux[1] =  0.0;
      Ux[2] =  0.0;
      Uy[0] =  0.0;
      Uy[1] =  0.0;
      Uy[2] =  1.0;
      break;

    case MRML_SLICER_ORIENT_INPLANE:
      // In the plane of N, and normal to T
      // Ux = -N x T = T x N
      // Uy = -N
      // Uz =  T
      Cross(Ux, T, N);
      Uy[0] = - N[0];
      Uy[1] = - N[1];
      Uy[2] = - N[2];
      break;

    case MRML_SLICER_ORIENT_INPLANE90:
      // Ux = -T
      // Uy = -N
      Ux[0] = - T[0];
      Ux[1] = - T[1];
      Ux[2] = - T[2];
      Uy[0] = - N[0];
      Uy[1] = - N[1];
      Uy[2] = - N[2];
      break;

    case MRML_SLICER_ORIENT_INPLANENEG90:
      // Ux =  T
      // Uy = -N
      Ux[0] =   T[0];
      Ux[1] =   T[1];
      Ux[2] =   T[2];
      Uy[0] = - N[0];
      Uy[1] = - N[1];
      Uy[2] = - N[2];
      break;

    case MRML_SLICER_ORIENT_PERP:
      // Ux = N x T
      // Uy = T
      // Uz = -N
      Cross(Ux, N, T);
      Uy[0] =   T[0];
      Uy[1] =   T[1];
      Uy[2] =   T[2];
      break;

      // by default, the reformat values are the regular
      // axial, sagittal and coronal matrices
    case MRML_SLICER_ORIENT_REFORMAT_AXIAL:
      N[0] = this->ReformatAxialN[0];
      N[1] = this->ReformatAxialN[1];
      N[2] = this->ReformatAxialN[2];
      T[0] = this->ReformatAxialT[0];
      T[1] = this->ReformatAxialT[1];
      T[2] = this->ReformatAxialT[2];
      Ux[0] = T[0];
      Ux[1] = T[1];
      Ux[2] = T[2];
      Cross(Uy,N,T);
      break;

    case MRML_SLICER_ORIENT_REFORMAT_SAGITTAL:
      N[0] = this->ReformatSagittalN[0];
      N[1] = this->ReformatSagittalN[1];
      N[2] = this->ReformatSagittalN[2];
      T[0] = this->ReformatSagittalT[0];
      T[1] = this->ReformatSagittalT[1];
      T[2] = this->ReformatSagittalT[2];
      Ux[0] = T[0];
      Ux[1] = T[1];
      Ux[2] = T[2];
      Cross(Uy,N,T);
      break;

    case MRML_SLICER_ORIENT_REFORMAT_CORONAL:
      N[0] = this->ReformatCoronalN[0];
      N[1] = this->ReformatCoronalN[1];
      N[2] = this->ReformatCoronalN[2];
      T[0] = this->ReformatCoronalT[0];
      T[1] = this->ReformatCoronalT[1];
      T[2] = this->ReformatCoronalT[2];
      Ux[0] = T[0];
      Ux[1] = T[1];
      Ux[2] = T[2];
      Cross(Uy,N,T);
      break;
      
    case MRML_SLICER_ORIENT_NEW_ORIENT:

      // In the plane of T, and normal to N
      // Ux = T
      // Uy = N x T
      // Uz =  N
      N[0] = this->NewOrientN[s][0];
      N[1] = this->NewOrientN[s][1];
      N[2] = this->NewOrientN[s][2];
      T[0] = this->NewOrientT[s][0];
      T[1] = this->NewOrientT[s][1];
      T[2] = this->NewOrientT[s][2];
      Ux[0] = T[0];
      Ux[1] = T[1];
      Ux[2] = T[2];
      Cross(Uy,N,T);

      break;
      }//switch

    // Form Uz
      Cross(Uz, Ux, Uy);
    Normalize(Ux);
    Normalize(Uy);
    Normalize(Uz);
        
    // Set ReformatMatrix
    for(i=0; i<3; i++) 
    {
      ref->SetElement(i, 0, Ux[i]);
      ref->SetElement(i, 1, Uy[i]);
      ref->SetElement(i, 2, Uz[i]);
      ref->SetElement(i, 3, P[i] + offset * Uz[i]);
      }
    for(i=0; i<3; i++) 
    {
      ref->SetElement(3, i, 0.0);
      }
    ref->SetElement(3, 3, 1.0);

  }//else

}


////////////////////////////////////////////////////////////////////////////////
//                    POINTS
////////////////////////////////////////////////////////////////////////////////


//----------------------------------------------------------------------------
// SetScreenPoint
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetScreenPoint(int s, int x, int y)
{
  // Convert from 512x512 to 256x256
  if (this->DoubleSliceSize[s] == 1) {
    x /= 2;
    y /= 2;
  }

  // Convert from zoom space to reformat space
  vtkFloatingPointType ctr[2];
  this->Zoom[s]->GetCenter(ctr);
  if (this->Zoom[s]->GetMagnification() != 1.0 || 
    this->Zoom[s]->GetAutoCenter() == 0 ||
    (ctr[0] == 0.0 && ctr[1] == 0.0))
  {
    this->Zoom[s]->SetZoomPoint(x, y);
    this->Zoom[s]->GetOrigPoint(this->ReformatPoint);
  } 
  else 
  {
    this->ReformatPoint[0] = x;
    this->ReformatPoint[1] = y;
  }
}

//----------------------------------------------------------------------------
// Point
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetReformatPoint(int s, int x, int y)
{ 
  vtkMrmlDataVolume *vol = this->GetIJKVolume(s);
  vtkImageReformat *ref = this->GetIJKReformat(s);
  SetReformatPoint(vol, ref, s, x, y);
}

void vtkMrmlSlicer::SetReformatPoint(vtkMrmlDataVolume *vol, 
                                     vtkImageReformat *ref,  
                                     int s, int x, int y)
{
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) vol->GetMrmlNode();
  // Convert (s,x,y) to (i,j,k), (r,a,s), and (x,y,z).
  // (s,x,y) = slice, x,y coordinate on slice
  // (r,a,s) = this->WldPoint = mm vtkFloatingPointType
  // (i,j,k) = this->IjkPoint = 0-based vtkFloatingPointType
  // (x,y,z) = this->Seed     = extent-based int (x = extent[0]+i)

  // First convert to ras, then ijk, then xyz
  ref->SetPoint(x, y);
  ref->GetWldPoint(this->WldPoint);
  ref->GetIjkPoint(this->IjkPoint);
  
  int ext[6];
  vol->GetOutput()->GetWholeExtent(ext);

  this->Seed[0] = ext[0] + (int)(this->IjkPoint[0] + 0.49);
  this->Seed[1] = ext[2] + (int)(this->IjkPoint[1] + 0.49);
  this->Seed[2] = ext[4] + (int)(this->IjkPoint[2] + 0.49);

  if (this->IsOrientIJK(s))
  {
    char orderString[3];

    switch (this->Orient[s])
    {
      case MRML_SLICER_ORIENT_ORIGSLICE:
        sprintf(orderString, "%s", node->GetScanOrder());
        break;
      case MRML_SLICER_ORIENT_AXISLICE:
        sprintf(orderString, "IS");
        break;
      case MRML_SLICER_ORIENT_SAGSLICE:
        sprintf(orderString, "LR");
        break;
      case MRML_SLICER_ORIENT_CORSLICE:
        sprintf(orderString, "PA");
        break;
    }//switch

    vtkImageReformatIJK *ijk = this->ReformatIJK;
    ijk->SetWldToIjkMatrix(node->GetWldToIjk());
    ijk->SetInput(vol->GetOutput());
    ijk->SetInputOrderString(node->GetScanOrder());
    ijk->SetOutputOrderString(orderString);
    ijk->SetSlice((int)(this->Offset[s][this->Orient[s]]));
    ijk->ComputeTransform();
    ijk->ComputeOutputExtent();
    ijk->SetIJKPoint(this->Seed[0], this->Seed[1], this->Seed[2]);
    ijk->GetXYPoint(this->Seed2D);
  }
  else
  {
    this->Seed2D[0] = ext[0] + x;
    this->Seed2D[1] = ext[2] + y;
  }
  this->Seed2D[2] = 0;
}

//----------------------------------------------------------------------------
// DrawComputeIjkPoints
//----------------------------------------------------------------------------
void vtkMrmlSlicer::DrawComputeIjkPoints()
{
  vtkFloatingPointType *rasPt;
  int ijkPt[3], i, n, x=0, y=0;
  int s = this->GetActiveSlice();
  vtkPoints *ijk = this->DrawIjkPoints;
  vtkPoints *ras = this->PolyDraw->GetPoints();

  ijk->Reset();
  n = ras->GetNumberOfPoints();
  for (i=0; i<n; i++)
  {
    rasPt = ras->GetPoint(i);
    this->SetReformatPoint(s, (int)(rasPt[0]), (int)(rasPt[1]));
    this->GetSeed2D(ijkPt);

    if (i == 0 || ijkPt[0] != x || ijkPt[1] != y)
    {
      ijk->InsertNextPoint((vtkFloatingPointType)(ijkPt[0]), (vtkFloatingPointType)(ijkPt[1]),
        (vtkFloatingPointType)(ijkPt[2]));
    } 
    x = ijkPt[0];
    y = ijkPt[1];
  }
}

//----------------------------------------------------------------------------
// DrawComputeIjkPointsInterpolated
//----------------------------------------------------------------------------
void vtkMrmlSlicer::DrawComputeIjkPointsInterpolated(int density)
{
  vtkFloatingPointType *rasPt;
  int ijkPt[3], i, n, x=0, y=0;
  int s = this->GetActiveSlice();
  vtkPoints *ijk = this->DrawIjkPoints;
  vtkPoints *ras = this->PolyDraw->GetPointsInterpolated(density);

  ijk->Reset();
  n = ras->GetNumberOfPoints();
  for (i=0; i<n; i++)
  {
    rasPt = ras->GetPoint(i);
    this->SetReformatPoint(s, (int)(rasPt[0]), (int)(rasPt[1]));
    this->GetSeed2D(ijkPt);

    if (i == 0 || ijkPt[0] != x || ijkPt[1] != y)
    {
      ijk->InsertNextPoint((vtkFloatingPointType)(ijkPt[0]), (vtkFloatingPointType)(ijkPt[1]),
        (vtkFloatingPointType)(ijkPt[2]));
    } 
    x = ijkPt[0];
    y = ijkPt[1];
  }
}

//----------------------------------------------------------------------------
// DrawComputeIjkPointsInterpolated
//----------------------------------------------------------------------------
void vtkMrmlSlicer::DrawComputeIjkPointsInterpolated(int window, int s, int p)
{
  vtkFloatingPointType *rasPt;
  int ijkPt[3], i, n, x=0, y=0;
  int as = this->GetActiveSlice();
  vtkPoints *ijk = this->DrawIjkPoints;
  vtkPoints *ras;

  switch(window)
  {
    case 0: ras = AxiPolyStack->GetSampledPolygon(s, p);
            break;
    case 1: ras = SagPolyStack->GetSampledPolygon(s, p);
            break;
    case 2: ras = CorPolyStack->GetSampledPolygon(s, p);
            break;
  }

  ijk->Reset();
  n = ras->GetNumberOfPoints();
  for (i=0; i<n; i++)
  {
    rasPt = ras->GetPoint(i);
    this->SetReformatPoint(as, (int)(rasPt[0]), (int)(rasPt[1]));
    this->GetSeed2D(ijkPt);

    if (i == 0 || ijkPt[0] != x || ijkPt[1] != y)
    {
      ijk->InsertNextPoint((vtkFloatingPointType)(ijkPt[0]), (vtkFloatingPointType)(ijkPt[1]),
        (vtkFloatingPointType)(ijkPt[2]));
    } 
    x = ijkPt[0];
    y = ijkPt[1];
  }
}

//----------------------------------------------------------------------------
// Pixel Values
//----------------------------------------------------------------------------
vtkFloatingPointType vtkMrmlSlicer::GetBackPixel(int s, int x, int y)
{
  int ext[6];

  if (this->BackVolume[s] == this->NoneVolume)
  {
    return 0;
  }

  vtkImageData *data = this->BackReformat[s]->GetOutput();

  data->GetWholeExtent(ext);
  if (x >= ext[0] && x <= ext[1] && y >= ext[2] && y <= ext[3])
  {
    vtkPointData *pd = data->GetPointData();
    vtkDataArray *da = pd->GetScalars();
    if (da->GetNumberOfComponents() == 1) 
    {   return data->GetPointData()->GetScalars()->GetTuple1(y*(ext[1]-ext[0]+1)+x);
    }
  }
  return 0;
}

vtkFloatingPointType vtkMrmlSlicer::GetForePixel(int s, int x, int y)
{
  int ext[6];

  if (this->ForeVolume[s] == this->NoneVolume)
  {
    return 0;
  }
  vtkImageData *data = this->ForeReformat[s]->GetOutput();

  data->GetWholeExtent(ext);
  if (x >= ext[0] && x <= ext[1] && y >= ext[2] && y <= ext[3])
  {
    if (data->GetPointData()->GetScalars()->GetNumberOfComponents() == 1) 
    {   return data->GetPointData()->GetScalars()->GetTuple1(y*(ext[1]-ext[0]+1)+x);
    }
  }
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
//                          VIEW
////////////////////////////////////////////////////////////////////////////////


//----------------------------------------------------------------------------
// Cursor
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetShowCursor(int vis) 
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->Cursor[s]->SetShowCursor(vis);
  }
}

void vtkMrmlSlicer::SetCursorIntersect(int flag)
{
    for (int s=0; s<NUM_SLICES; s++)
    {
        this->SetCursorIntersect(s,flag);
    }
}

// sets the gap between hash marks on the cursor, which adjusts the opening
void vtkMrmlSlicer::SetCursorHashGap(vtkFloatingPointType gap)
{
    if (gap < this->Cursor[0]->GetHashLength() / 2.0) {
        vtkWarningMacro(<<"Cursor hash gap should be greater than half of the hash length to avoid overlap in the center: " << this->Cursor[0]->GetHashLength() / 2.0);
        //return;
    }
   for (int s=0; s<NUM_SLICES; s++)
   {
       this->SetCursorHashGap(s,gap);
   }
}

// sets the length of the cursor hash marks
void vtkMrmlSlicer::SetCursorHashLength(vtkFloatingPointType len)
{
    for (int s=0; s<NUM_SLICES; s++)
    {
        this->SetCursorHashLength(s,len);
    }
}

// DAVE need to call with SetAnnoColor
void vtkMrmlSlicer::SetCursorColor(vtkFloatingPointType red, vtkFloatingPointType green, vtkFloatingPointType blue) 
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->Cursor[s]->SetCursorColor(red, green, blue);
  }
}

void vtkMrmlSlicer::SetNumHashes(int hashes) 
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->Cursor[s]->SetNumHashes(hashes);
  }
}

int vtkMrmlSlicer::GetNumHashes()
{
    return this->Cursor[0]->GetNumHashes();
}

//----------------------------------------------------------------------------
// View direction
//----------------------------------------------------------------------------
void vtkMrmlSlicer::ComputeNTPFromCamera(vtkCamera *camera)
{
  int i;
  double *VPN; // View Plane Normal vector
  double *VU;  // View Up vector
  double *FP;  // Focal Point

  if (camera == NULL)
  {
      vtkErrorMacro(<< "ComputeNTPFromCamera: NULL camera");
  }
  VPN = camera->GetViewPlaneNormal();
  VU  = camera->GetViewUp();
  FP  = camera->GetFocalPoint();

  // Compute N, T, P as if the view direction were the locator.
  // For the locator:
  //   N points along the needle toward the tip.
  //   T points from the handle's center back toward the cable.
  // So:
  //   N = -VPN
  //   T = VPN x VU
  //   P = FP

  for (i=0; i<3; i++)
  {
      this->CamN[i] = -VPN[i];
  }
  Cross(this->CamT, VPN, VU);

  Normalize(this->CamN);
  Normalize(this->CamT);

  for (i=0; i<3; i++)
  {
      this->CamP[i] = FP[i];
  }

  for (i=0; i<3; i++)
  {
    this->ComputeReformatMatrix(i);
  }
}

// this function is used to set the reformat matrix directly for ALL the slices
// It is called from Locator.tcl to set the reformat matrix to be the same
// as the locator matrix
 
void vtkMrmlSlicer::SetDirectNTP(vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz,
  vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz)
{
  this->DirN[0] = nx;
  this->DirN[1] = ny;
  this->DirN[2] = nz;
  this->DirT[0] = tx;
  this->DirT[1] = ty;
  this->DirT[2] = tz;
  this->DirP[0] = px;
  this->DirP[1] = py;
  this->DirP[2] = pz;

  for (int s=0; s<NUM_SLICES; s++)
  {
    this->ComputeReformatMatrix(s);
  }
}

// this function is used to set the reformat matrix of a particular
// slice interactively by the user this matrix is only used in
// MRML_SLICER_ORIENT_NEW_ORIENT, for any other orientation, the standart
// matrix (relative to the camera or relative to the locator) is used
// 
// See the function ComputeReformatMatrix for more detail

void vtkMrmlSlicer::SetNewOrientNTP(int s, vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz,
  vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz)
{
  this->NewOrientN[s][0] = nx;
  this->NewOrientN[s][1] = ny;
  this->NewOrientN[s][2] = nz;
  this->NewOrientT[s][0] = tx;
  this->NewOrientT[s][1] = ty;
  this->NewOrientT[s][2] = tz;
  this->NewOrientP[s][0] = px;
  this->NewOrientP[s][1] = py;
  this->NewOrientP[s][2] = pz;
  
  this->ComputeReformatMatrix(s);
  
}

// this function is called to update the reformat matrix for the REFORMAT_AXIAL, REFORMAT_CORONAL, REFORMAT_SAGITTAL orientations

void vtkMrmlSlicer::SetReformatNTP(char *orientation, vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz, vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz)
{

  double Ux[3],Uy[3],Uz[3];
  
  if (strcmp(orientation, "ReformatAxial") == 0){
    
    Ux[0] = tx;
    Ux[1] = ty;
    Ux[2] = tz;
    Uz[0] = nx;
    Uz[1] = ny;
    Uz[2] = nz;
    Cross(Uy,Uz,Ux);

    // calculate the sagittal plane
    this->ReformatSagittalT[0] = -Uy[0];
    this->ReformatSagittalT[1] = -Uy[1];
    this->ReformatSagittalT[2] = -Uy[2];
    this->ReformatSagittalN[0] = Ux[0];
    this->ReformatSagittalN[1] = Ux[1];
    this->ReformatSagittalN[2] = Ux[2];

    //calculate the coronal plane
    this->ReformatCoronalT[0] = Ux[0];
    this->ReformatCoronalT[1] = Ux[1];
    this->ReformatCoronalT[2] = Ux[2];
    this->ReformatCoronalN[0] = Uy[0];
    this->ReformatCoronalN[1] = Uy[1];
    this->ReformatCoronalN[2] = Uy[2];

    // set the variables for axial
    this->ReformatAxialT[0] = Ux[0];
    this->ReformatAxialT[1] = Ux[1];
    this->ReformatAxialT[2] = Ux[2];
    this->ReformatAxialN[0] = Uz[0];
    this->ReformatAxialN[1] = Uz[1];
    this->ReformatAxialN[2] = Uz[2];

  }
  else if (strcmp(orientation, "ReformatSagittal") == 0){

    Ux[0] = tx;
    Ux[1] = ty;
    Ux[2] = tz;
    Uz[0] = nx;
    Uz[1] = ny;
    Uz[2] = nz;
    Cross(Uy,Uz,Ux);

    // calculate the axial plane
    this->ReformatAxialT[0] = Uz[0];
    this->ReformatAxialT[1] = Uz[1];
    this->ReformatAxialT[2] = Uz[2];
    this->ReformatAxialN[0] = -Uy[0];
    this->ReformatAxialN[1] = -Uy[1];
    this->ReformatAxialN[2] = -Uy[2];

    //calculate the coronal plane
    this->ReformatCoronalT[0] = Uz[0];
    this->ReformatCoronalT[1] = Uz[1];
    this->ReformatCoronalT[2] = Uz[2];
    this->ReformatCoronalN[0] = -Ux[0];
    this->ReformatCoronalN[1] = -Ux[1];
    this->ReformatCoronalN[2] = -Ux[2];

    // set the variables for sagittal
    this->ReformatSagittalT[0] = Ux[0];
    this->ReformatSagittalT[1] = Ux[1];
    this->ReformatSagittalT[2] = Ux[2];
    this->ReformatSagittalN[0] = Uz[0];
    this->ReformatSagittalN[1] = Uz[1];
    this->ReformatSagittalN[2] = Uz[2];

  } 
 else if (strcmp(orientation, "ReformatCoronal") == 0){


    Ux[0] = tx;
    Ux[1] = ty;
    Ux[2] = tz;
    Uz[0] = nx;
    Uz[1] = ny;
    Uz[2] = nz;
    Cross(Uy,Uz,Ux);


    // calculate the axial plane
    this->ReformatAxialT[0] = Ux[0];
    this->ReformatAxialT[1] = Ux[1];
    this->ReformatAxialT[2] = Ux[2];
    this->ReformatAxialN[0] = -Uy[0];
    this->ReformatAxialN[1] = -Uy[1];
    this->ReformatAxialN[2] = -Uy[2];

    //calculate the sagittal plane
    this->ReformatSagittalT[0] = -Uz[0];
    this->ReformatSagittalT[1] = -Uz[1];
    this->ReformatSagittalT[2] = -Uz[2];
    this->ReformatSagittalN[0] = Ux[0];
    this->ReformatSagittalN[1] = Ux[1];
    this->ReformatSagittalN[2] = Ux[2];

    // set the variables for coronal
    this->ReformatCoronalT[0] = Ux[0];
    this->ReformatCoronalT[1] = Ux[1];
    this->ReformatCoronalT[2] = Ux[2];
    this->ReformatCoronalN[0] = Uz[0];
    this->ReformatCoronalN[1] = Uz[1];
    this->ReformatCoronalN[2] = Uz[2];

  } 
  
  for (int s=0; s<NUM_SLICES; s++)
    {
      this->ComputeReformatMatrix(s);
    }
  
}

double *vtkMrmlSlicer::GetP(int s)
{
  if (this->Driver[s] == 0) 
  {
    return this->CamP;
  } else {
    return this->DirP;
  }
}

double *vtkMrmlSlicer::GetT(int s)
{
  if (this->Driver[s] == 0) 
  {
    return this->CamT;
  } else {
    return this->DirT;
  }
}

double *vtkMrmlSlicer::GetN(int s)
{
  if (this->Driver[s] == 0) 
  {
    return this->CamN;
  } else {
    return this->DirN;
  }
}

// DAVE: Update the GUI after calling this
void vtkMrmlSlicer::SetFieldOfView(vtkFloatingPointType fov)
{
  this->FieldOfView = fov;

  this->ComputeOffsetRange();

  for(int s=0; s<NUM_SLICES; s++)
  {
    this->BackReformat[s]->SetFieldOfView(fov);
    this->ForeReformat[s]->SetFieldOfView(fov);
    this->LabelReformat[s]->SetFieldOfView(fov);
    // >> AT 11/09/01
    this->BackReformat3DView[s]->SetFieldOfView(fov);
    this->ForeReformat3DView[s]->SetFieldOfView(fov);
    this->LabelReformat3DView[s]->SetFieldOfView(fov);
    // << AT 11/09/01
  }

  // arbitrary volume reformatting
  this->VolumeReformattersSetFieldOfView(fov);
}

//----------------------------------------------------------------------------
// Zoom
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetZoom(vtkFloatingPointType mag)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->SetZoom(s, mag);
  }
}

void vtkMrmlSlicer::SetZoom(int s, vtkFloatingPointType mag)
{
  this->Zoom[s]->SetMagnification(mag);
  this->BuildLowerTime.Modified();
}

// >> AT 11/07/01
void vtkMrmlSlicer::SetZoomNew(vtkFloatingPointType mag)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->SetZoomNew(s, mag);
  }
}

void vtkMrmlSlicer::SetZoomNew(int s, vtkFloatingPointType mag)
{
  this->BackReformat[s]->SetZoom(mag);
  this->ForeReformat[s]->SetZoom(mag);
  this->LabelReformat[s]->SetZoom(mag);
  this->BuildLowerTime.Modified();
}

void vtkMrmlSlicer::SetOriginShift(int s, vtkFloatingPointType sx, vtkFloatingPointType sy)
{
  this->BackReformat[s]->SetOriginShift(sx, sy);
  this->ForeReformat[s]->SetOriginShift(sx, sy);
  this->LabelReformat[s]->SetOriginShift(sx, sy);

  this->BuildLowerTime.Modified();
}
// << AT 11/07/01

void vtkMrmlSlicer::SetZoomCenter(int s, vtkFloatingPointType x, vtkFloatingPointType y)
{
  this->Zoom[s]->SetCenter(x, y);
  this->BuildLowerTime.Modified();
  this->GetZoomCenter();
}

void vtkMrmlSlicer::GetZoomCenter()
{
  this->Zoom[0]->GetCenter(this->ZoomCenter0);
  this->Zoom[1]->GetCenter(this->ZoomCenter1);
  this->Zoom[2]->GetCenter(this->ZoomCenter2);
}

void vtkMrmlSlicer::SetZoomAutoCenter(int s, int yes)
{
  this->Zoom[s]->SetAutoCenter(yes);
  this->Zoom[s]->Update();
  this->GetZoomCenter();
  this->BuildLowerTime.Modified();
}

//----------------------------------------------------------------------------
// Label LUT
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetLabelIndirectLUT(vtkIndirectLookupTable *lut)
{
  // This block is basically vtkSetObjectMacro
  if (this->LabelIndirectLUT != lut)
  { 
    if (this->LabelIndirectLUT != NULL) 
    { 
      this->LabelIndirectLUT->UnRegister(this); 
    }
    this->LabelIndirectLUT = lut;

    if (this->LabelIndirectLUT != NULL) 
    { 
      this->LabelIndirectLUT->Register(this); 
    }
    this->Modified();
  }

  for (int s=0; s<NUM_SLICES; s++)
  {
    this->LabelMapper[s]->SetLookupTable(this->LabelIndirectLUT);
    // >> AT 11/09/01
    this->LabelMapper3DView[s]->SetLookupTable(this->LabelIndirectLUT);
    // << AT 11/09/01
  }
  this->BuildUpperTime.Modified();
}

//----------------------------------------------------------------------------
// Fore Opacity
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetForeOpacity(vtkFloatingPointType opacity)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
    this->Overlay[s]->SetOpacity(1, opacity);
    // >> AT 11/09/01
    this->Overlay3DView[s]->SetOpacity(1, opacity);
    // << AT 11/09/01
  }
}

//----------------------------------------------------------------------------
// Fore Opacity
//----------------------------------------------------------------------------
void vtkMrmlSlicer::SetForeFade(int fade)
{
  for (int s=0; s<NUM_SLICES; s++)
  {
      this->Overlay[s]->SetFade(1, fade);
    // >> AT 11/09/01
      this->Overlay3DView[s]->SetFade(1, fade);
    // << AT 11/09/01
  }
}

//----------------------------------------------------------------------------
// Convenient reformatting functions: odonnell, 5/4/2001
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
// Description:
// Use the same reformat matrix as slice s.
// Causes this volume to be reformatted along with this slice.
// (reformatter will update when slice number changes.)
//
// Currently this is not used.
void vtkMrmlSlicer::ReformatVolumeLikeSlice(vtkMrmlDataVolume *v, int s)
{
  // find the reformatter for this volume
  vtkImageReformat *reformat = this->GetVolumeReformatter(v);

  if (reformat != NULL)
    reformat->SetReformatMatrix(this->ReformatMatrix[s]);
}

//----------------------------------------------------------------------------
// Description:
// Add a volume for reformatting: this may be any volume in the 
// slicer, and the reformatted output can be obtained by
// Slicer->GetReformatOutputFromVolume(vtkMrmlDataVolume *v).
// Currently only reformatting along with the slices is 
// supported, but code may be added to use arbitrary 
// reformat matrices if needed.
// Note that this does not allow duplicate entries: so now you may
// only reformat a certain volume with one reformatter.
//
//
// For now, only reformatting that mirrors the active slice is supported.
// This happens automatically and the reformatters update when the 
// active slice or slice offset change.  In the future this should
// be made more general to allow arbitrary reformatting.
void vtkMrmlSlicer::AddVolumeToReformat(vtkMrmlDataVolume *v)
{
  int index = this->VolumesToReformat->IsItemPresent(v);
  if (index) 
    {
      //vtkErrorMacro("already reformatting volume " << v );  
      return;
    }

  if (index > this->MaxNumberOfVolumesToReformat)
    {
      vtkErrorMacro("increase the number of volumes the slicer can reformat"); 
      return;
    }

  // make a reformatter object to do this
  vtkImageReformat *reformat = vtkImageReformat::New();

  // set its input to be this volume
  vtkMrmlVolumeNode *node = (vtkMrmlVolumeNode*) v->GetMrmlNode();
  reformat->SetInput(v->GetOutput());
  reformat->SetInterpolate(node->GetInterpolate());
  reformat->SetWldToIjkMatrix(node->GetWldToIjk());

  // bookkeeping: add to list of volumes
  this->VolumesToReformat->AddItem(v);
  index = this->VolumesToReformat->IsItemPresent(v);
  vtkDebugMacro("add: index of volume:" << index );

  // bookkeeping: the index of the reformatter and volume will be the same:
  // add to list of reformatters
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
  this->VolumeReformatters->InsertValue(index, reformat);
#else
  this->VolumeReformatters->InsertVoidPointer(index, reformat);
#endif
  // for now only allow reformatting along with the active slice
  reformat->SetReformatMatrix(this->ReformatMatrix[this->GetActiveSlice()]);
  reformat->Modified();
  
  // set the field of view to match other volumes reformatted in the slicer
  reformat->SetFieldOfView(this->FieldOfView);
}

//----------------------------------------------------------------------------
// Description:
// Stop reformatting all volumes.  Do this when your module is done
// with this input (such as when it is exited).
void vtkMrmlSlicer::RemoveAllVolumesToReformat()
{
  // clear all pointers to volumes
  this->VolumesToReformat->RemoveAllItems();

  // delete all reformatters
  for (int i = 0; i < this->MaxNumberOfVolumesToReformat; i++)
    {
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetValue(i);
#else
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetVoidPointer(i);
#endif
      if (ref != NULL) 
    {
      // kill it 
      ref->Delete();
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      this->VolumeReformatters->SetValue(i,NULL);
#else
      this->VolumeReformatters->SetVoidPointer(i,NULL);
#endif      
    }
    }
}

//----------------------------------------------------------------------------
// Description:
// internal use: get the reformatter used for this volume.
vtkImageReformat *vtkMrmlSlicer::GetVolumeReformatter(vtkMrmlDataVolume *v)
{
  int index = this->VolumesToReformat->IsItemPresent(v);
  if (index) 
    {
      // get pointer to reformatter
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetValue(index);
#else
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetVoidPointer(index);
#endif
      return ref;
    }
  else
    {
      vtkErrorMacro("Not reformatting this volume: " << v );  
      return NULL;
    }
}

//----------------------------------------------------------------------------
// Description:
// internal use: mark all reformatters as modified so their output
// will update. (this is called when the reformat matrix for a slice
// changes, so these reformatted slices can follow the original
// three slices in the slicer's slice windows).
void vtkMrmlSlicer::VolumeReformattersModified()
{
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
  int max = this->VolumeReformatters->GetNumberOfTuples();
#else
  int max = this->VolumeReformatters->GetNumberOfPointers();
#endif
  for (int i = 0; i < max; i++)
    {
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetValue(i);
#else
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetVoidPointer(i);
#endif
      if (ref != NULL)
    {
      // for now only allow reformatting along with the active slice
      ref->SetReformatMatrix(this->ReformatMatrix[this->GetActiveSlice()]);
      ref->Modified();
    }
    }
}

void vtkMrmlSlicer::VolumeReformattersSetFieldOfView(vtkFloatingPointType fov)
{
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
  int max = this->VolumeReformatters->GetNumberOfTuples();
#else
  int max = this->VolumeReformatters->GetNumberOfPointers();
#endif

  for (int i = 0; i < max; i++)
    {
#if (VTK_MAJOR_VERSION <= 4 && VTK_MINOR_VERSION <= 2)
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetValue(i);
#else
      vtkImageReformat *ref = 
    (vtkImageReformat *)this->VolumeReformatters->GetVoidPointer(i);
#endif
      if (ref != NULL)
    {
      ref->SetFieldOfView(fov);
    }
    }
}

//----------------------------------------------------------------------------
// Description:
// Returns the compiler version used to compile the Slicer code
// For GCC returns VVRRPP, where VV=Version, RR=Revision, PP=Patchlevel
// For Microsoft compiler, returns value of _MSC_VER which has some arcane
//relationship to the major and minor version numbers
// Else returns 0
int vtkMrmlSlicer::GetCompilerVersion()
{

#if defined(__GNUC__)
#if defined(__GNU_PATCHLEVEL__)
    return (__GNUC__ * 10000 \
            + __GNUC_MINOR__ * 100 \
            + __GNUC_PATCHLEVEL__);
# else
    return (__GNUC__ * 10000 \
            + __GNUC_MINOR__ * 100);
# endif
#endif

#if defined(_MSC_VER)
    return (_MSC_VER);
#endif
    
    return 0;
}
//----------------------------------------------------------------------------
// Description:
// Returns the compiler used to compile the Slicer code
// For GCC returns GCC
// For Microsoft compiler, MSC
// Else returns UNKNOWN

const char * vtkMrmlSlicer::GetCompilerName()
{

#if defined(__GNUC__)
    return "GCC";
#endif

#if defined(_MSC_VER)
    return "MSC";
#endif
    
    return "UKNOWN";
}
//----------------------------------------------------------------------------
// Description:
// Returns the version number of the vtk library this has been compiled with
const char * vtkMrmlSlicer::GetVTKVersion()
{
    return VTK_VERSION;
}
