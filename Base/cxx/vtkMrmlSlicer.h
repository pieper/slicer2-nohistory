/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlSlicer.h,v $
  Date:      $Date: 2006/04/13 18:20:37 $
  Version:   $Revision: 1.52 $

=========================================================================auto=*/
// .NAME vtkMrmlSlicer - main core of the 3D Slicer
// .SECTION Description
// Handles layers of images for the 3 slices, and everything related to 
// their display.  (i.e. reformatting, orientation, cursor, filtering)
// Handles drawing before the points are applied.
// Does math w.r.t. reformat matrices, etc.
//
// Don't change this file without permission from slicer@ai.mit.edu.  It
// is intended to be general enough so developers don't need to hack it.
//

#ifndef __vtkMrmlSlicer_h
#define __vtkMrmlSlicer_h

#include "vtkObject.h"
#include "vtkImageOverlay.h" // For inline
#include "vtkImageZoom2D.h" // For inline
#include "vtkImageCrossHair2D.h" // For inline
#include "vtkImageDrawROI.h" // For inline
#include "vtkStackOfPolygons.h" // For inline
#include "vtkSlicer.h"

#define NUM_SLICES 3

#include <stdlib.h>

// Orient

#define MRML_SLICER_ORIENT_AXIAL        0
#define MRML_SLICER_ORIENT_SAGITTAL     1
#define MRML_SLICER_ORIENT_CORONAL      2
#define MRML_SLICER_ORIENT_INPLANE      3
#define MRML_SLICER_ORIENT_INPLANE90    4
#define MRML_SLICER_ORIENT_INPLANENEG90 5
#define MRML_SLICER_ORIENT_NEW_ORIENT         6
#define MRML_SLICER_ORIENT_REFORMAT_AXIAL    7
#define MRML_SLICER_ORIENT_REFORMAT_SAGITTAL 8
#define MRML_SLICER_ORIENT_REFORMAT_CORONAL  9
#define MRML_SLICER_ORIENT_PERP         10
#define MRML_SLICER_ORIENT_ORIGSLICE    11
#define MRML_SLICER_ORIENT_AXISLICE     12
#define MRML_SLICER_ORIENT_SAGSLICE     13
#define MRML_SLICER_ORIENT_CORSLICE    14
#define MRML_SLICER_ORIENT_AXISAGCOR   15
#define MRML_SLICER_ORIENT_ORTHO       16
#define MRML_SLICER_ORIENT_SLICES      17
#define MRML_SLICER_ORIENT_REFORMAT_AXISAGCOR   18
#define MRML_SLICER_NUM_ORIENT         19

class vtkCamera;
class vtkImageReformatIJK;
class vtkImageReformat;
class vtkImageMapToColors;
class vtkMatrix4x4;
class vtkTransform;
class vtkPoints;
class vtkLookupTable;
class vtkMrmlDataVolume;
class vtkMrmlVolumeNode;
class vtkImageLabelOutline;
class vtkImageDouble2D;
class vtkIndirectLookupTable;
class vtkCollection;
class vtkVoidArray;
class vtkImageSource;

class VTK_SLICER_BASE_EXPORT vtkMrmlSlicer : public vtkObject 
{
  public:
  
  // The Usual vtk class functions
  static vtkMrmlSlicer *New();
  vtkTypeMacro(vtkMrmlSlicer,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
    

  //------ Output things to be displayed in slice s: ------//

  // Description:
  // Overlay is merged fore, back, and label images, for display
  // in slice window s (where s is 0, 1, or 2)

  // >> AT 11/09/01
  //vtkImageData *GetOutput(int s) {
  //  this->Update(); return this->Overlay[s]->GetOutput();};
  vtkImageData *GetOutput(int s) {
    this->Update(); return this->Overlay3DView[s]->GetOutput();}
  // << AT 11/09/01

  // Description:
  // Cursor is the moving cross-hair for over slice s
  vtkImageData *GetCursor(int s) {
    this->Update(); return this->Cursor[s]->GetOutput();};

  // Description:
  // Active output is either the contour just drawn or the regular
  // overlay image, depending on the slice it is for.
  vtkImageData *GetActiveOutput(int s) {
    this->Update();
    if (this->ActiveSlice == s) 
      return this->PolyDraw->GetOutput();
    else 
      return this->Overlay[s]->GetOutput();
  };

  // Description:
  // The active slice is the one last touched by the user.
  void SetActiveSlice(int s);
  vtkGetMacro(ActiveSlice, int);

  // Karl - June 2005 
  vtkSetMacro(DisplayMethod,int);
  vtkGetMacro(DisplayMethod,int);
  
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

  // Description:
  // Zoom auto center
  void SetZoomAutoCenter(int s, int yes);
  int GetZoomAutoCenter(int s) {return this->Zoom[s]->GetAutoCenter();};

  // Description:
  // Double slice size outputs 512x512 images for larger display
  // (instead of 256x256)

  // >> AT 02/16/01 3/26/01
  //  void SetDouble(int s, int yes) {
  // this->DoubleSliceSize[s] = yes; this->BuildLowerTime.Modified();};
  // Should be moved to vtkMrmlSlicer.cxx
  void SetDouble(int s, int yes); 
  
  vtkSetMacro(DrawDoubleApproach,int);
  vtkGetMacro(DrawDoubleApproach,int);
  

  // << AT 02/16/01 3/26/01

  int GetDouble(int s) {return this->DoubleSliceSize[s];};

  //Deep Copy Method
  void DeepCopy(vtkMrmlSlicer *src);

  // Description:
  // The cursor is the crosshair that moves with the mouse over the slices
  void SetShowCursor(int vis);
  void SetNumHashes(int hashes);
    int GetNumHashes();
  void SetCursorColor(vtkFloatingPointType red, vtkFloatingPointType green, vtkFloatingPointType blue);
  void SetCursorPosition(int s, int x, int y) {
    this->Cursor[s]->SetCursor(x, y);};
  // turn on or off the cross hair intersection - if off there's a gap
  void SetCursorIntersect(int flag);
  void SetCursorIntersect(int s, int flag) {
     this->Cursor[s]->SetIntersectCross(flag); } ;
  int GetCursorIntersect(int s) {
     return this->Cursor[s]->GetIntersectCross(); };
    vtkFloatingPointType GetCursorHashGap() { return this->Cursor[0]->GetHashGap(); };
    void SetCursorHashGap(vtkFloatingPointType gap);
    void SetCursorHashGap(int s, vtkFloatingPointType gap) {
        this->Cursor[s]->SetHashGap(gap); };

    vtkFloatingPointType GetCursorHashLength() { return this->Cursor[0]->GetHashLength(); };
    void SetCursorHashLength(int s, vtkFloatingPointType len) {
        this->Cursor[s]->SetHashLength(len); };
    void SetCursorHashLength(vtkFloatingPointType len);
    
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

  // Description:
  // Sets whether to fade out the background even when the 
  // foreground is clearn
  void SetForeFade(int fade);
  vtkGetMacro(ForeFade, int);

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
  void SetBackVolume(vtkMrmlDataVolume *vol);
  // Description:
  // The Fore volume is the one displayed in the foreground slice layer
  void SetForeVolume(vtkMrmlDataVolume *vol);
  // Description:
  // The Label volume is displayed in the label slice layer.
  // It is passed through a vtkImageLabelOutline filter which shows only
  // the outline of the labeled regions.
  void SetLabelVolume(vtkMrmlDataVolume *vol);

  void SetBackVolume( int s, vtkMrmlDataVolume *vol);
  void SetForeVolume( int s, vtkMrmlDataVolume *vol);
  void SetLabelVolume(int s, vtkMrmlDataVolume *vol);
  vtkMrmlDataVolume* GetBackVolume( int s) {return this->BackVolume[s];};
  vtkMrmlDataVolume* GetForeVolume( int s) {return this->ForeVolume[s];};
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
  void SetDriver(int s, int d) {this->Driver[s] = d; this->Modified();};
  int GetDriver(int s) {return this->Driver[s];};
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
    void SetFirstFilter(int s, vtkObject *filter);
    
  // LastFilter is of type vtkImageSource, a superclass of
  // both vtkImageToImage and vtkMultipleInput filters.
  void SetLastFilter(int s, vtkImageSource *filter);
  vtkObject * GetFirstFilter(int s) {return this->FirstFilter[s];};
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

  //-------------------- Draw ---------------------------//
  // Description:
  // For display of temporary drawing over slices.
  // 
  // This is for display only!  It can't be used to actually change
  // the volumes in the slicer.  The editor (vtkImageEditorEffects)
  // is used for that.
  //
  // Mainly Drawing is interaction with the vtkImageDrawROI object
  // PolyDraw.
  //
  void DrawSetColor(vtkFloatingPointType r, vtkFloatingPointType g, vtkFloatingPointType b) {
      this->PolyDraw->SetPointColor(r, g, b);
      this->PolyDraw->SetLineColor(r, g, b);};
  void DrawSelectAll() {
    this->PolyDraw->SelectAllPoints();};
  void DrawDeselectAll() {
    this->PolyDraw->DeselectAllPoints();};
  void DrawDeleteSelected() {
    this->PolyDraw->DeleteSelectedPoints();};
  void DrawDeleteAll() {
    this->PolyDraw->DeleteAllPoints();};
  void DrawInsert(int x, int y) {
    this->PolyDraw->InsertPoint(x, y);};
  void DrawShowPoints(int s) {
    if (s) this->PolyDraw->SetPointRadius(1); 
    else this->PolyDraw->SetPointRadius(0);};
  void DrawSetRadius(int r) {
    this->PolyDraw->SetPointRadius(r); };
  int DrawGetRadius() {
    return this->PolyDraw->GetPointRadius(); };
  void DrawInsertPoint(int x, int y) {
    this->PolyDraw->InsertAfterSelectedPoint(x, y);};
  void DrawMoveInit(int x, int y) {
      this->DrawX = x; this->DrawY = y;};
  void DrawMove(int x, int y) {
    this->PolyDraw->MoveSelectedPoints(x-this->DrawX, y-this->DrawY);
    this->DrawX = x; this->DrawY = y;};
  int DrawGetNumPoints() {
    return this->PolyDraw->GetNumPoints();};
  int DrawGetNumSelectedPoints() {
    return this->PolyDraw->GetNumSelectedPoints();};
  void DrawStartSelectBox(int x, int y) {
    this->PolyDraw->StartSelectBox(x, y);};
  void DrawDragSelectBox(int x, int y) {
    this->PolyDraw->DragSelectBox(x, y);};
  void DrawEndSelectBox(int x, int y) {
    this->PolyDraw->EndSelectBox(x, y);};
  vtkPoints* DrawGetPoints() {
    return this->PolyDraw->GetPoints();}
  vtkPoints* DrawGetPointsInterpolated(int density) {
    return this->PolyDraw->GetPointsInterpolated(density);}
  void DrawComputeIjkPoints();
  void DrawComputeIjkPointsInterpolated(int density);
  void DrawComputeIjkPointsInterpolated(int window, int s, int p);
  vtkGetObjectMacro(DrawIjkPoints, vtkPoints);
  void DrawSetShapeToPolygon() {this->PolyDraw->SetShapeToPolygon();};
  void DrawSetShapeToLines() {this->PolyDraw->SetShapeToLines();};
  void DrawSetShapeToPoints() {this->PolyDraw->SetShapeToPoints();};
  const char* GetShapeString() {return this->PolyDraw->GetShapeString();};
  //>> AT 01/17/01 01/19/01 02/19/01
  void DrawSetSelectedPointColor(vtkFloatingPointType r, vtkFloatingPointType g, vtkFloatingPointType b)
    {
      this->PolyDraw->SetSelectedPointColor(r, g, b);
    }
  void DrawSetShapeToCrosses() { this->PolyDraw->SetShapeToCrosses(); }
  void DrawSetShapeToBoxes() { this->PolyDraw->SetShapeToBoxes(); }
  void DrawSelectPoint(int x, int y) { this->PolyDraw->SelectPoint(x, y); }
  void DrawDeselectPoint(int x, int y) { this->PolyDraw->DeselectPoint(x, y); }
  // (CTJ) To detect whether mouse (x,y) is "near" selected points
  int DrawIsNearSelected(int x, int y)
  {return this->PolyDraw->IsNearSelected(x, y);}
  void DrawSetClosed(int closed)
  { this->PolyDraw->SetClosed(closed); }
  void DrawSetHideSpline(int hide)
  { this->PolyDraw->SetHideSpline(hide); }

  void DrawSetStartMethod(void (*f)(void *), void *arg)
    {
#if !( (VTK_MAJOR_VERSION ==4 && VTK_MINOR_VERSION > 2) || (VTK_MAJOR_VERSION >= 5) )
      this->PolyDraw->SetStartMethod(f, arg);
#endif
    }
  void DrawSetStartMethodArgDelete(void (*f)(void *))
    {
#if !( (VTK_MAJOR_VERSION ==4 && VTK_MINOR_VERSION > 2) || (VTK_MAJOR_VERSION >= 5) )
      this->PolyDraw->SetStartMethodArgDelete(f);
#endif
    }

  vtkPoints* CopyGetPoints()
  {
      return this->CopyPoly;
  };

  void CopySetDrawPoints()
  {
      int n = this->DrawGetNumPoints();
      if (n < 1) return;
      this->CopyPoly->Reset();
      vtkPoints *polygon = this->DrawGetPoints();
      vtkFloatingPointType *rasPt;
      for (int i = 0; i < n; i++)
      {
          rasPt = polygon->GetPoint(i);
          this->CopyPoly->InsertNextPoint(rasPt[0], rasPt[1], rasPt[2]);
      }
  };

  // ---- Stack of polygons ---- //
  void StackSetPolygon(int window, int s, int d)
  {
    switch (window)
    {
      case 0: AxiPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, d);
              break;
      case 1: SagPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, d);
              break;
      case 2: CorPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, d);
              break; 
    }
  };

  vtkPoints* StackGetPoints(int window, int s)
  {
    switch (window)
    {
      case 0: return this->AxiPolyStack->GetPoints(s);
              break;
      case 1: return this->SagPolyStack->GetPoints(s);
              break;
      case 2: return this->CorPolyStack->GetPoints(s);
              break;
    default: fprintf(stderr,"StackGetPoints: window %d  out of valid range 0-2, returning null pointer", window);
        return NULL;
        break;
    }
  };

  vtkPoints* StackGetPoints(int window, int s, int p)
  {
    switch (window)
    {
      case 0: return this->AxiPolyStack->GetPoints(s, p);
              break;
      case 1: return this->SagPolyStack->GetPoints(s, p);
              break;
      case 2: return this->CorPolyStack->GetPoints(s, p);
              break;                 
    default: fprintf(stderr,"StackGetPoints: window %d out of valid range 0-2, returning null pointer",window);
        return NULL;
        break;
    
    }
  };

  void StackSetPolygon(int window, int s, int p, int d, int closed, int preshape, int label)
  {
    switch (window)
    {
      case 0: AxiPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, p, d, closed, preshape, label);
              break;
      case 1: SagPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, p, d, closed, preshape, label);
              break;
      case 2: CorPolyStack->SetPolygon(this->PolyDraw->GetPoints(), s, p, d, closed, preshape, label);
              break;
    }
  };

  vtkPoints* RasStackSetPolygon(int window, int s, int p, int d, int closed, int preshape, int label)
  {
      vtkPoints *polygon = this->PolyDraw->GetPoints();
      vtkFloatingPointType *screenPt;
      int as = this->GetActiveSlice();
      int n = polygon->GetNumberOfPoints();
      vtkFloatingPointType rasPt[3];

      rasPts->Reset();
      for (int i = 0; i < n; i++)
      {
          screenPt = polygon->GetPoint(i);
          this->SetReformatPoint(as, (int)(screenPt[0]), (int)(screenPt[1]));
          this->GetWldPoint(rasPt);
          rasPts->InsertNextPoint((vtkFloatingPointType)(rasPt[0]),
                                  (vtkFloatingPointType)(rasPt[1]),
                                  (vtkFloatingPointType)(rasPt[2]));
      }
      switch (window)
      {
          case 0: AxiRasPolyStack->SetPolygon(rasPts, s, p, d, closed, preshape, label);
                  break;
          case 1: SagRasPolyStack->SetPolygon(rasPts, s, p, d, closed, preshape, label);
                  break;
          case 2: CorRasPolyStack->SetPolygon(rasPts, s, p, d, closed, preshape, label);
                  break;
      }
      return this->rasPts;
  };

  void StackRemovePolygon(int window, int s, int p)
  {
      switch (window)
      {
          case 0: this->AxiPolyStack->RemovePolygon(s, p);
                  break;
          case 1: this->SagPolyStack->RemovePolygon(s, p);
                  break;
          case 2: this->CorPolyStack->RemovePolygon(s, p);
                  break;
      }
  };

  void RasStackRemovePolygon(int window, int s, int p)
  {
      switch (window)
      {
          case 0: this->AxiRasPolyStack->RemovePolygon(s, p);
                  break;
          case 1: this->SagRasPolyStack->RemovePolygon(s, p);
                  break;
          case 2: this->CorRasPolyStack->RemovePolygon(s, p);
                  break;
      }
  };

  int StackGetNumberOfPoints(int window, int s)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->GetNumberOfPoints(s);
                  break;
          case 1: return this->SagPolyStack->GetNumberOfPoints(s);
                  break;
          case 2: return this->CorPolyStack->GetNumberOfPoints(s);
                  break;
      default: fprintf(stderr,"StackGetNumberOfPoints: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetInsertPosition(int window, int s)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->ListGetInsertPosition(s);
                  break;
          case 1: return this->SagPolyStack->ListGetInsertPosition(s);
                  break;
          case 2: return this->CorPolyStack->ListGetInsertPosition(s);
                  break;
      default: fprintf(stderr,"StackGetInsertPosition: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetNextInsertPosition(int window, int s, int p)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->ListGetNextInsertPosition(s, p);
                  break;
          case 1: return this->SagPolyStack->ListGetNextInsertPosition(s, p);
                  break;
          case 2: return this->CorPolyStack->ListGetNextInsertPosition(s, p);
                  break;
      default: fprintf(stderr,"StackGetNextInsertPosition: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetRetrievePosition(int window, int s)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->ListGetRetrievePosition(s);
                  break;
          case 1: return this->SagPolyStack->ListGetRetrievePosition(s);
                  break;
          case 2: return this->CorPolyStack->ListGetRetrievePosition(s);
                  break;
      default: fprintf(stderr,"StackGetRetrievePosition: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetNextRetrievePosition(int window, int s, int p)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->ListGetNextRetrievePosition(s, p);
                  break;
          case 1: return this->SagPolyStack->ListGetNextRetrievePosition(s, p);
                  break;
          case 2: return this->CorPolyStack->ListGetNextRetrievePosition(s, p);
                  break;
      default: fprintf(stderr,"StackGetNextRetrievePosition: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetPreshape(int window, int s, int p)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->GetPreshape(s, p);
                  break;
          case 1: return this->SagPolyStack->GetPreshape(s, p);
                  break;
          case 2: return this->CorPolyStack->GetPreshape(s, p);
                  break;
      default: fprintf(stderr,"StackGetPreshape: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetLabel(int window, int s, int p)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->GetLabel(s, p);
                  break;
          case 1: return this->SagPolyStack->GetLabel(s, p);
                  break;
          case 2: return this->CorPolyStack->GetLabel(s, p);
                  break;
      default: fprintf(stderr,"StackGetLabel: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetNumApplyable(int window, int s)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->GetNumApplyable(s);
                  break;
          case 1: return this->SagPolyStack->GetNumApplyable(s);
                  break;
          case 2: return this->CorPolyStack->GetNumApplyable(s);
                  break;
      default: fprintf(stderr,"StackGetNumApplyable: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  int StackGetApplyable(int window, int s, int q)
  {
      switch (window)
      {
          case 0: return this->AxiPolyStack->GetApplyable(s, q);
                  break;
          case 1: return this->SagPolyStack->GetApplyable(s, q);
                  break;
          case 2: return this->CorPolyStack->GetApplyable(s, q);
                  break;
      default: fprintf(stderr,"StackGetApplyable: window %d out of valid range 0-2, returning -1",window);
          return -1;
          break;
      }
  };

  void StackClear(int window)
  {
      switch (window)
      {
          case 0: this->AxiPolyStack->Clear();
                  break;
          case 1: this->SagPolyStack->Clear();
                  break;
          case 2: this->CorPolyStack->Clear();
                  break;
      }
  };

  // Necessary for calculating the ROI windowsize
  // TO DO: Add check for s
  int GetBackReformatResolution(int s) { return this->BackReformat[s]->GetResolution();}
  vtkImageDrawROI *GetImageDrawROI() { return this->PolyDraw; }
  //<< AT 01/17/01 01/19/01 02/19/01

  // << AT 11/02/01
  vtkImageReformat *GetBackReformat(int s) { return this->BackReformat[s]; }
  // << AT 11/02/01

  //Hanifa
  vtkImageReformat *GetForeReformat(int s) { return this->ForeReformat[s]; }
  vtkImageReformat *GetBackReformat3DView(int s) {return this->BackReformat3DView[s];}
  vtkImageReformat *GetForeReformat3DView(int s) {return this->ForeReformat3DView[s];}
  vtkImageReformat *GetLabelReformat3DView(int s) {return this->LabelReformat3DView[s];}

  // Description:
  // Update any part of this class that needs it.
  // Call this if you are using the First, Last filter pipeline
  // and want it to execute.
  void Update();

  // Description:
  // 
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
  vtkMrmlSlicer();
  ~vtkMrmlSlicer();

  void ComputeOffsetRange();
  void ComputeOffsetRangeIJK(int s);
  vtkMrmlDataVolume* GetIJKVolume(int s);
  vtkImageReformat* GetIJKReformat(int s);
  int IsOrientIJK(int s);
  void BuildLower(int s);
  void BuildUpper(int s);
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
  vtkFloatingPointType OffsetRange[NUM_SLICES][MRML_SLICER_NUM_ORIENT][2];
  int Orient[NUM_SLICES];
  vtkFloatingPointType Offset[NUM_SLICES][MRML_SLICER_NUM_ORIENT];

  vtkImageReformat     *BackReformat[NUM_SLICES];
  vtkImageReformat     *ForeReformat[NUM_SLICES];
  vtkImageReformat     *LabelReformat[NUM_SLICES];
  vtkImageMapToColors  *BackMapper[NUM_SLICES];
  vtkImageMapToColors  *ForeMapper[NUM_SLICES];
  vtkImageMapToColors  *LabelMapper[NUM_SLICES];
  vtkImageOverlay      *Overlay[NUM_SLICES];
  // >> AT 11/09/01
  vtkImageReformat     *BackReformat3DView[NUM_SLICES];
  vtkImageReformat     *ForeReformat3DView[NUM_SLICES];
  vtkImageReformat     *LabelReformat3DView[NUM_SLICES];
  vtkImageMapToColors  *BackMapper3DView[NUM_SLICES];
  vtkImageMapToColors  *ForeMapper3DView[NUM_SLICES];
  vtkImageMapToColors  *LabelMapper3DView[NUM_SLICES];
  vtkImageOverlay      *Overlay3DView[NUM_SLICES];
  // << AT 11/09/01
  vtkMrmlDataVolume        *BackVolume[NUM_SLICES];
  vtkMrmlDataVolume        *ForeVolume[NUM_SLICES];
  vtkMrmlDataVolume        *LabelVolume[NUM_SLICES];
  vtkMatrix4x4         *ReformatMatrix[NUM_SLICES];
  vtkImageLabelOutline *LabelOutline[NUM_SLICES];
  // >> AT 11/09/01
  vtkImageLabelOutline *LabelOutline3DView[NUM_SLICES];
  // << AT 11/09/01
  vtkImageCrossHair2D  *Cursor[NUM_SLICES];
  vtkImageZoom2D       *Zoom[NUM_SLICES];
  vtkImageDouble2D     *Double[NUM_SLICES];
  vtkImageDrawROI      *PolyDraw;
  vtkStackOfPolygons *AxiPolyStack;
  vtkStackOfPolygons *AxiRasPolyStack;
  vtkStackOfPolygons *SagPolyStack;
  vtkStackOfPolygons *SagRasPolyStack;
  vtkStackOfPolygons *CorPolyStack;
  vtkStackOfPolygons *CorRasPolyStack;
  vtkPoints            *rasPts; // temporary RAS version of PolyDraw
  vtkPoints            *CopyPoly;
  vtkImageReformatIJK  *ReformatIJK;
  vtkMrmlDataVolume        *NoneVolume;
  vtkMrmlVolumeNode    *NoneNode;

  // Colors
  vtkIndirectLookupTable *LabelIndirectLUT;

  vtkObject *FirstFilter[NUM_SLICES];
  vtkImageSource *LastFilter[NUM_SLICES];
  int BackFilter;
  int ForeFilter;
  int FilterActive;
  int FilterOverlay;

  // DAVE need a better way
  vtkFloatingPointType ZoomCenter0[2];
  vtkFloatingPointType ZoomCenter1[2];
  vtkFloatingPointType ZoomCenter2[2];

  // Point
  vtkFloatingPointType WldPoint[3];
  vtkFloatingPointType IjkPoint[3];
  int ReformatPoint[2];
  int Seed[3];
  int Seed2D[3];
  int DisplayMethod;

  // Draw
  vtkPoints *DrawIjkPoints;
  int DrawX;
  int DrawY;

  // >> AT 3/26/01
  int DrawDoubleApproach;
  // << AT 3/26/01

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

private:
  vtkMrmlSlicer(const vtkMrmlSlicer&);
  void operator=(const vtkMrmlSlicer&);
};

#endif

