/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageDrawROI.h,v $
  Date:      $Date: 2006/02/14 20:40:11 $
  Version:   $Revision: 1.20 $

=========================================================================auto=*/
// .NAME vtkImageDrawROI -  Draw contour on an image
// .SECTION Description
// Drawing and user interaction (select, etc.) for drawing on images

#ifndef __vtkImageDrawROI_h
#define __vtkImageDrawROI_h

#include "vtkImageData.h"
#include "vtkImageInPlaceFilter.h"
#include "vtkPoints.h"
#include "point.h"
#include "vtkSlicer.h"
#include "vtkImageReformat.h"

#define ROI_SHAPE_POLYGON 1
#define ROI_SHAPE_LINES   2
#define ROI_SHAPE_POINTS  3
//>> AT 01/17/01 01/19/01
#define ROI_SHAPE_CROSSES 4
#define ROI_SHAPE_BOXES   5
//<< AT 01/17/01 01/19/01

class VTK_SLICER_BASE_EXPORT vtkImageDrawROI : public vtkImageInPlaceFilter
{
public:    
    static vtkImageDrawROI *New();
  vtkTypeMacro(vtkImageDrawROI,vtkImageInPlaceFilter);
    void PrintSelf(ostream& os, vtkIndent indent);

    // Description:
    // Display user interaction (mainly selection) in image
    void SelectPoint(int x, int y);
    void DeselectPoint(int x, int y);
    void TogglePoint(int x, int y);
    void StartSelectBox(int x, int y);
    void DragSelectBox(int x, int y);
    void EndSelectBox(int x, int y);
    void SelectAllPoints();
    void DeselectAllPoints();
    void AppendPoint(int x, int y);
    void InsertPoint(int x, int y);
    void InsertAfterSelectedPoint(int x, int y);
    void DeleteSelectedPoints();
    void DeleteAllPoints();
    void MoveSelectedPoints(int deltaX, int deltaY);
    void MoveAllPoints(int deltaX, int deltaY);
    int  IsNearSelected(int x, int y);

    void SetClosed(int closed)
    { this->Closed = closed; }

    // Description:
    // Attributes of the poly/line/points drawn in the slice
    vtkSetVector3Macro(PointColor, float);
    vtkGetVectorMacro(PointColor, float, 3);
    vtkSetVector3Macro(SelectedPointColor, float);
    vtkGetVectorMacro(SelectedPointColor, float, 3);
    vtkSetVector3Macro(LineColor, float);
    vtkGetVectorMacro(LineColor, float, 3);

    vtkGetMacro(NumSelectedPoints, int);
    vtkGetMacro(NumPoints, int);

    vtkGetMacro(PointRadius, int);
    vtkSetMacro(PointRadius, int);

    vtkGetMacro(HideROI, int);
    vtkSetMacro(HideROI, int);
    vtkBooleanMacro(HideROI, int);
    void SetImageReformat( vtkImageReformat* ir) {
      this->image_reformat = ir;
    }

    vtkGetMacro(HideSpline, int);
    vtkSetMacro(HideSpline, int);
    vtkBooleanMacro(HideSpline, int);

    // Description:
    // Shape functions affect the way the contour is drawn
    // based on the input points
    void SetShapeToPolygon() {
        this->Shape = ROI_SHAPE_POLYGON; this->Modified();};
    void SetShapeToLines() {
        this->Shape  = ROI_SHAPE_LINES; this->Modified();};
    void SetShapeToPoints() {
        this->Shape = ROI_SHAPE_POINTS; this->Modified();};
    int GetShape() {return this->Shape;};
    // >> AT 01/17/01 01/19/01
    void SetShapeToCrosses() 
      {
        this->Shape = ROI_SHAPE_CROSSES;
        this->Modified();
      }
    void SetShapeToBoxes() 
      {
        this->Shape = ROI_SHAPE_BOXES;
        this->Modified();
      }
    /*char *GetShapeString() {switch (this->Shape) {
        case ROI_SHAPE_POLYGON: return "Polygon";
        case ROI_SHAPE_LINES: return "Lines";
        case ROI_SHAPE_POINTS: return "Points";
        default: return "None";};};*/
    const char *GetShapeString()
      {
        switch (this->Shape) {
        case ROI_SHAPE_POLYGON: return "Polygon";
        case ROI_SHAPE_LINES: return "Lines";
        case ROI_SHAPE_POINTS: return "Points";
        case ROI_SHAPE_CROSSES: return "Crosses";
        case ROI_SHAPE_BOXES: return "Boxes";
        default: return "None";}
      }
    // << AT 01/17/01 01/19/01

    // Description:
    // Get the points from the contour drawn on the slice.
    // Used for Apply (to actually mark the points in the volume)
    vtkPoints* GetPoints();
    vtkPoints* GetPointsInterpolated(int density);
    void LoadStackPolygon(vtkPoints* pts);

protected:
        vtkImageDrawROI();
    ~vtkImageDrawROI();
    vtkImageDrawROI(const vtkImageDrawROI&);
    void operator=(const vtkImageDrawROI&);

    vtkPoints *Points;
    vtkImageReformat* image_reformat;
    vtkPoints *Samples;
    
    Point *firstPoint;
    Point *lastPoint;

    int drawSelectBox;
    Point sbox;
    Point sbox1;
    Point sbox2;

    int NumPoints;
    int NumSelectedPoints;
    int PointRadius;
    int HideROI;
    int HideSpline;
    int Shape;
    int Closed;

    float PointColor[3];
    float SelectedPointColor[3];
    float LineColor[3];

    void DrawPoints(vtkImageData *outData, int extent[6]);
    void DrawLines(vtkImageData *outData, int extent[6]);
    void DrawSelectBox(vtkImageData *outData, int extent[6]);
    //>> AT 01/17/01 01/19/01
    void DrawCrosses(vtkImageData *outData, int extent[6]);
    void DrawBoxes(vtkImageData *outData, int extent[6]);
    //<< AT 01/17/01 01/19/01
    void DrawSpline(vtkImageData *outData, int outExt[6]);
    // Not threaded because its too simple of a filter
    void ExecuteData(vtkDataObject *);
};

#endif

