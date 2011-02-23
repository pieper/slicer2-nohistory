/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlMultiSlicer.h,v $
  Date:      $Date: 2006/02/23 02:29:34 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
// .NAME vtkMrmlMultiSlicer - adaptation of the main core of the 3D Slicer
// .SECTION Description
// Handles layers of images for the 9 multi slices and the mosaik slice, and
// everything related to their display.  (i.e. reformatting, orientation, cursor,
// filtering)
// Doesn't handles 3D display and drawing (not needed for the module purpose).
// Does math w.r.t. reformat matrices, etc.
//
// Don't change this file without permission from slicer@ai.mit.edu.  It
// is intended to be general enough so developers don't need to hack it.
// The comment above was completely discarded since this class is a copy/paste
// of the vtkMrmlSlicer, which simply duplicates code...

#ifndef __vtkMrmlMultiSlicer_h
#define __vtkMrmlMultiSlicer_h

#include "vtkCompareModuleConfigure.h"

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
#include "vtkCollection.h"
#include "vtkVoidArray.h"
#include "vtkSlicer.h"

// FIXME : added Mosaik
#include "vtkImageMosaik.h"
// FIXME Changing number of slices to 9 (should be user defined)
#define NUM_SLICES 10
// FIXME Set mosaik slice index among slicer members
#define MOSAIK_INDEX 9

#include <stdlib.h>

#define MRML_SLICER_LIGHT_ORIENT_AXIAL        0
#define MRML_SLICER_LIGHT_ORIENT_SAGITTAL     1
#define MRML_SLICER_LIGHT_ORIENT_CORONAL      2
#define MRML_SLICER_LIGHT_ORIENT_INPLANE      3
#define MRML_SLICER_LIGHT_ORIENT_INPLANE90    4
#define MRML_SLICER_LIGHT_ORIENT_INPLANENEG90 5
#define MRML_SLICER_LIGHT_ORIENT_NEW_ORIENT         6
#define MRML_SLICER_LIGHT_ORIENT_REFORMAT_AXIAL    7
#define MRML_SLICER_LIGHT_ORIENT_REFORMAT_SAGITTAL 8
#define MRML_SLICER_LIGHT_ORIENT_REFORMAT_CORONAL  9
#define MRML_SLICER_LIGHT_ORIENT_PERP         10
#define MRML_SLICER_LIGHT_ORIENT_ORIGSLICE    11
#define MRML_SLICER_LIGHT_ORIENT_AXISLICE     12
#define MRML_SLICER_LIGHT_ORIENT_SAGSLICE     13
#define MRML_SLICER_LIGHT_ORIENT_CORSLICE    14
#define MRML_SLICER_LIGHT_ORIENT_AXISAGCOR   15
#define MRML_SLICER_LIGHT_ORIENT_ORTHO       16
#define MRML_SLICER_LIGHT_ORIENT_SLICES      17
#define MRML_SLICER_LIGHT_ORIENT_REFORMAT_AXISAGCOR   18
#define MRML_SLICER_LIGHT_NUM_ORIENT         19


class VTK_COMPAREMODULE_EXPORT vtkMrmlMultiSlicer : public vtkObject
{
  public:

  // The Usual vtk class functions
  static vtkMrmlMultiSlicer *New();
  vtkTypeMacro(vtkMrmlMultiSlicer,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);


  //------ Output things to be displayed in slice s: ------//

  // Description:
  // Cursor is the moving cross-hair for over slice s
  vtkImageData *GetCursor(int s) {
    this->Update(); return this->Cursor[s]->GetOutput();};

  // Description:
  // The active slice is the one last touched by the user.
  void SetActiveSlice(int s);
  vtkGetMacro(ActiveSlice, int);


  //------ Factors that affect how slices are displayed: ------//

  // Description:
  // Zoom factor
  void SetZoom(int s, vtkFloatingPointType mag);
  void SetZoom(vtkFloatingPointType mag);
  vtkFloatingPointType GetZoom(int s) {return this->Zoom[s]->GetMagnification();};
  // >> AT 11/07/01
  void SetZoomNew(int s, vtkFloatingPointType mag);
  void SetZoomNew(vtkFloatingPointType mag);
  vtkFloatingPointType GetZoomNew(int s) {return this->BackReformat[s]->GetZoom();}
  void SetOriginShift(int s, vtkFloatingPointType sx, vtkFloatingPointType sy);
  // << AT 11/07/11

  // Description:
  // Zoom center
  void SetZoomCenter(int s, vtkFloatingPointType x, vtkFloatingPointType y);
  void GetZoomCenter();
  vtkGetVector2Macro(ZoomCenter0, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter1, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter2, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter3, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter4, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter5, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter6, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter7, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter8, vtkFloatingPointType);
  vtkGetVector2Macro(ZoomCenter9, vtkFloatingPointType);

  // Description:
  // Zoom auto center
  void SetZoomAutoCenter(int s, int yes);
  int GetZoomAutoCenter(int s) {return this->Zoom[s]->GetAutoCenter();};

  // Description:
  // Double slice size outputs 512x512 images for larger display
  // (instead of 256x256)
  void SetDouble(int s, int yes) {
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
        if (resolution>=512){
            this->BackReformat[s]->SetResolution(512);
            this->ForeReformat[s]->SetResolution(512);
            this->LabelReformat[s]->SetResolution(512);
        }
        else{
            this->DoubleSliceSize[s] = yes;
            this->BackReformat[s]->SetResolution(256);
            this->ForeReformat[s]->SetResolution(256);
            this->LabelReformat[s]->SetResolution(256);
        }
     }
     else
     {
        this->BackReformat[s]->SetResolution(256);
        this->ForeReformat[s]->SetResolution(256);
        this->LabelReformat[s]->SetResolution(256);
     }
     this->BuildLowerTime.Modified();
  }

  int GetDouble(int s) {return this->DoubleSliceSize[s];};

  //Deep Copy Method
  void DeepCopy(vtkMrmlMultiSlicer *src);

  // Description:
  // The cursor is the crosshair that moves with the mouse over the slices
  void SetShowCursor(int vis);
  void SetNumHashes(int hashes);
  void SetCursorColor(vtkFloatingPointType red, vtkFloatingPointType green, vtkFloatingPointType blue);
  void SetCursorPosition(int s, int x, int y) {
    this->Cursor[s]->SetCursor(x, y);};
  // turn on or off the cross hair intersection - if off there's a gap
  void SetCursorIntersect(int flag);
  void SetCursorIntersect(int s, int flag) {
     this->Cursor[s]->SetIntersectCross(flag); } ;
  int GetCursorIntersect(int s) {
     return this->Cursor[s]->GetIntersectCross(); };

  // Description:
  // Field of view for slices.  Also used for reformatting...
  vtkGetMacro(FieldOfView, vtkFloatingPointType);
  void SetFieldOfView(vtkFloatingPointType x);

  // Cursor Annotation
  vtkFloatingPointType GetForePixel(int s, int x, int y);
  vtkFloatingPointType GetBackPixel(int s, int x, int y);

  // Description:
  // Sets the opacity used to overlay this layer on the others
  void SetForeOpacity(vtkFloatingPointType opacity);
  vtkGetMacro(ForeOpacity, vtkFloatingPointType);

  // FIXME : added mosaik opacity
  // Sets the opacity used to overlay this layer on the others
  void SetMosaikOpacity(vtkFloatingPointType opacity);
  vtkGetMacro(MosaikOpacity, vtkFloatingPointType);

  void SetMosaikDivision(int width, int height);

  // Description:
  // Coloring label maps
  void SetLabelIndirectLUT(vtkIndirectLookupTable *lut);


  //--------- Volumes layered in the 3 slice windows -----------//

  // Description:
  // The None volume is a single slice, all 0's, used as input to
  // the pipeline when no volume is selected.
  void SetNoneVolume(vtkMrmlDataVolume *vol);
  vtkGetObjectMacro(NoneVolume, vtkMrmlDataVolume);
  // Description:
  // The Back volume is the one displayed in the background slice layer
  void SetBackVolume( int s, vtkMrmlDataVolume *vol);
  vtkMrmlDataVolume* GetBackVolume( int s) {return this->BackVolume[s];};
  // Description:
  // The Fore volume is the one displayed in the foreground slice layer
  void SetForeVolume( int s, vtkMrmlDataVolume *vol);
  vtkMrmlDataVolume* GetForeVolume( int s) {return this->ForeVolume[s];};
  // Description:
  // The Label volume is displayed in the label slice layer.
  // It is passed through a vtkImageLabelOutline filter which shows only
  // the outline of the labeled regions.
  void SetLabelVolume(int s, vtkMrmlDataVolume *vol);
  vtkMrmlDataVolume* GetLabelVolume(int s) {return this->LabelVolume[s];};

  //--------- Slice reformatting, orientation, point conversion  -----------//

  // Description:
  // Slice Orientation
  void SetOrient(int orient);
  void SetOrient(int s, int orient);
  void SetOrientString(const char *str);
  void SetOrientString(int s, const char *str);
  int GetOrient(int s) {return this->Orient[s];};
  const char *GetOrientString(int s);
  const char *GetOrientList() {return
"Axial Sagittal Coronal InPlane InPlane90 InPlaneNeg90 Perp OrigSlice AxiSlice SagSlice CorSlice ReformatAxial ReformatSagittal ReformatCoronal NewOrient";};

  // Description:
  // Slice Offset
  vtkFloatingPointType GetOffsetRangeLow(int s) {
    return this->OffsetRange[s][this->Orient[s]][0];};
  vtkFloatingPointType GetOffsetRangeHigh(int s) {
    return this->OffsetRange[s][this->Orient[s]][1];};
  void SetOffset(int s, vtkFloatingPointType offset);
  void InitOffset(int s, const char *str, vtkFloatingPointType offset);
  vtkFloatingPointType GetOffset(int s) {return this->Offset[s][this->Orient[s]];};
  vtkFloatingPointType GetOffset(int s, char *str) {return
      this->Offset[s][ConvertStringToOrient(str)];};

  // Description:
  // Matrix
  vtkMatrix4x4 *GetReformatMatrix(int s) {return this->ReformatMatrix[s];};
  void ComputeNTPFromCamera(vtkCamera *camera);
  void SetDirectNTP(vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz,
    vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz);

  double *GetP(int s);
  double *GetT(int s);
  double *GetN(int s);
  vtkGetVector3Macro(DirP, double);
  vtkGetVector3Macro(CamP, double);
  // user defined matrix
  void SetNewOrientNTP(int s, vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz,
    vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz);
  // reformat matrix
  void SetReformatNTP(char *orientation, vtkFloatingPointType nx, vtkFloatingPointType ny, vtkFloatingPointType nz, vtkFloatingPointType tx, vtkFloatingPointType ty, vtkFloatingPointType tz, vtkFloatingPointType px, vtkFloatingPointType py, vtkFloatingPointType pz);

  // Points
  void SetReformatPoint(int s, int x, int y);
  void SetReformatPoint(vtkMrmlDataVolume *vol, vtkImageReformat *ref, int s, int x, int y);
  vtkGetVectorMacro(WldPoint, vtkFloatingPointType, 3);
  vtkGetVectorMacro(IjkPoint, vtkFloatingPointType, 3);
  void SetScreenPoint(int s, int x, int y);
  vtkGetVectorMacro(ReformatPoint, int, 2);
  vtkGetVectorMacro(Seed, int, 3);
  vtkGetVectorMacro(Seed2D, int, 3);


  //-------------------- Filter pipeline  -------------------------//

  // Description:
  // Convenient pipeline hook for developers.
  // First and last filters of any pipeline (or part of pipeline)
  // whose output should be displayed in a slice.
  // For example, this is used in Editor/EdThreshold.tcl for
  // dynamic thresholding.
  // This is for display only!  It can't be used to actually change
  // the volumes in the slicer.  Use the editor (vtkImageEditorEffects)
  // for that.
  void SetFirstFilter(int s, vtkSlicerImageAlgorithm *filter);
  // LastFilter is of type vtkImageSource, a superclass of
  // both vtkImageToImage and vtkMultipleInput filters.
  void SetLastFilter(int s, vtkImageSource *filter);
  vtkSlicerImageAlgorithm * GetFirstFilter(int s) {return this->FirstFilter[s];};
  vtkImageSource* GetLastFilter(int s) {return this->LastFilter[s];};

  // Description:
  // Whether to apply pipeline defined by first, last filter
  // to the Back slice
  vtkGetMacro(BackFilter, int);
  vtkSetMacro(BackFilter, int);
  vtkBooleanMacro(BackFilter, int);

  // Description:
  // Whether to apply pipeline defined by first, last filter
  // to the Fore slice
  vtkGetMacro(ForeFilter, int);
  vtkSetMacro(ForeFilter, int);
  vtkBooleanMacro(ForeFilter, int);

  // Description:
  // Whether to apply pipeline defined by first, last filter
  // only to Active slice or to all three slices
  vtkGetMacro(FilterActive, int);
  vtkSetMacro(FilterActive, int);
  vtkBooleanMacro(FilterActive, int);

  // Description:
  // Whether to overlay filter output on all layers
  // or use it to replace the fore layer.
  vtkGetMacro(FilterOverlay, int);
  vtkSetMacro(FilterOverlay, int);
  vtkBooleanMacro(FilterOverlay, int);

  //-------------------- Additional Reformatting ---------------------------//
  // For developers: convenience functions that reformat volumes
  // in the slicer.

  // Description:
  // Add a volume to the list we are reformatting.
  void AddVolumeToReformat(vtkMrmlDataVolume * v);

  // Description:
  // Call this to clear out the volumes when your module is exited.
  void RemoveAllVolumesToReformat();

  // Description:
  // Get the reformatted slice from this volume.  The volume
  // must have been added first.  Currently this reformats
  // along with the active slice in the Slicer.
  vtkImageData *GetReformatOutputFromVolume(vtkMrmlDataVolume *v) {
    return this->GetVolumeReformatter(v)->GetOutput();
  };

  // Description:
  // Set reformat matrix same as that of this slice
  void ReformatVolumeLikeSlice(vtkMrmlDataVolume * v, int s);

  // Necessary for calculating the ROI windowsize
  // TO DO: Add check for s
  //int GetBackReformatResolution(int s) { return this->BackReformat[s]->GetResolution();}
  vtkImageReformat *GetBackReformat(int s) { return this->BackReformat[s]; }
  vtkImageReformat *GetForeReformat(int s) { return this->ForeReformat[s]; }

  // Description:
  // Update any part of this class that needs it.
  // Call this if you are using the First, Last filter pipeline
  // and want it to execute.
  void Update();

  // Description:
  void ReformatModified() {this->BuildUpperTime.Modified();};

  // Description:
  // return the version number of the compiler
  int GetCompilerVersion();
  // Description:
  // return the name of the compiler
  const char *GetCompilerName();

  // Description:
  // return the vtk version
  const char *GetVTKVersion();

protected:
  vtkMrmlMultiSlicer();
  ~vtkMrmlMultiSlicer();

  void ComputeOffsetRange();
  void ComputeOffsetRangeIJK(int s);
  vtkMrmlDataVolume* GetIJKVolume(int s);
  vtkImageReformat* GetIJKReformat(int s);
  int IsOrientIJK(int s);
  void BuildLower(int s);
  void BuildUpper(int s);

  //FIXME : added mosaik build functions used in Update pipeline
  void BuildLowerMosaik();
  void BuildUpperMosaik();

  int ConvertStringToOrient(const char *str);
  const char* ConvertOrientToString(int orient);
  void ComputeReformatMatrix(int s);
  void ComputeReformatMatrixIJK(int s, vtkFloatingPointType offset, vtkMatrix4x4 *ref);
  vtkFloatingPointType GetOffsetForComputation(int s);
  void SetOffsetRange(int s, int orient, int min, int max, int *modified);

  int ActiveSlice;
  int DoubleSliceSize[NUM_SLICES];
  vtkFloatingPointType FieldOfView;
  vtkFloatingPointType ForeOpacity;
  int ForeFade;

  // FIXME : added mosaik opacity
  vtkFloatingPointType MosaikOpacity;

  double CamN[3];
  double CamT[3];
  double CamP[3];
  double DirN[3];
  double DirT[3];
  double DirP[3];
  double NewOrientN[NUM_SLICES][3];
  double NewOrientT[NUM_SLICES][3];
  double NewOrientP[NUM_SLICES][3];
  double ReformatAxialN[3];
  double ReformatAxialT[3];
  double ReformatSagittalN[3];
  double ReformatSagittalT[3];
  double ReformatCoronalN[3];
  double ReformatCoronalT[3];

  int Driver[NUM_SLICES];
  vtkFloatingPointType OffsetRange[NUM_SLICES][MRML_SLICER_LIGHT_NUM_ORIENT][2];
  int Orient[NUM_SLICES];
  vtkFloatingPointType Offset[NUM_SLICES][MRML_SLICER_LIGHT_NUM_ORIENT];

  vtkImageReformat     *BackReformat[NUM_SLICES];
  vtkImageReformat     *ForeReformat[NUM_SLICES];
  vtkImageReformat     *LabelReformat[NUM_SLICES];
  vtkImageMapToColors  *BackMapper[NUM_SLICES];
  vtkImageMapToColors  *ForeMapper[NUM_SLICES];
  vtkImageMapToColors  *LabelMapper[NUM_SLICES];
  vtkImageOverlay      *Overlay[NUM_SLICES];

  vtkMrmlDataVolume        *BackVolume[NUM_SLICES];
  vtkMrmlDataVolume        *ForeVolume[NUM_SLICES];
  vtkMrmlDataVolume        *LabelVolume[NUM_SLICES];
  vtkMatrix4x4         *ReformatMatrix[NUM_SLICES];
  vtkImageLabelOutline *LabelOutline[NUM_SLICES];

  vtkImageCrossHair2D  *Cursor[NUM_SLICES];
  vtkImageZoom2D       *Zoom[NUM_SLICES];
  vtkImageDouble2D     *Double[NUM_SLICES];

  vtkImageReformatIJK  *ReformatIJK;
  vtkMrmlDataVolume        *NoneVolume;
  vtkMrmlVolumeNode    *NoneNode;

  // Colors
  vtkIndirectLookupTable *LabelIndirectLUT;

  vtkSlicerImageAlgorithm *FirstFilter[NUM_SLICES];
  vtkImageSource *LastFilter[NUM_SLICES];
  int BackFilter;
  int ForeFilter;
  int FilterActive;
  int FilterOverlay;

  // DAVE need a better way
  vtkFloatingPointType ZoomCenter0[2];
  vtkFloatingPointType ZoomCenter1[2];
  vtkFloatingPointType ZoomCenter2[2];
  vtkFloatingPointType ZoomCenter3[2];
  vtkFloatingPointType ZoomCenter4[2];
  vtkFloatingPointType ZoomCenter5[2];
  vtkFloatingPointType ZoomCenter6[2];
  vtkFloatingPointType ZoomCenter7[2];
  vtkFloatingPointType ZoomCenter8[2];
  vtkFloatingPointType ZoomCenter9[2];

  // Point
  vtkFloatingPointType WldPoint[3];
  vtkFloatingPointType IjkPoint[3];
  int ReformatPoint[2];
  int Seed[3];
  int Seed2D[3];

  vtkTimeStamp UpdateTime;
  vtkTimeStamp BuildLowerTime;
  vtkTimeStamp BuildUpperTime;

  // Additional Reformatting capabilities
  vtkVoidArray *VolumeReformatters;
  vtkCollection *VolumesToReformat;
  vtkImageReformat *GetVolumeReformatter(vtkMrmlDataVolume *v);
  void VolumeReformattersModified();
  int MaxNumberOfVolumesToReformat;

  // Description:
  // set field of view in al reformatters when slicer's FOV updates
  void VolumeReformattersSetFieldOfView(vtkFloatingPointType fov);

  // FIXME : added new member Mosaik
  vtkImageMosaik       *Mosaik;

private:
  vtkMrmlMultiSlicer(const vtkMrmlMultiSlicer&);
  void operator=(const vtkMrmlMultiSlicer&);
};

#endif

