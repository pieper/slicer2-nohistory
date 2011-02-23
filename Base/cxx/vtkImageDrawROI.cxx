/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageDrawROI.cxx,v $
  Date:      $Date: 2006/01/06 17:56:40 $
  Version:   $Revision: 1.23 $

=========================================================================auto=*/
#include "vtkImageDrawROI.h"
#include "vtkObjectFactory.h"

#define SET_PIXEL(x, y, color) { ptr = &outPtr[(y)*nxnc + (x)*nc]; \
    ptr[0] = color[0]; ptr[1] = color[1]; ptr[2] = color[2];}

//------------------------------------------------------------------------------
vtkImageDrawROI* vtkImageDrawROI::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageDrawROI");
  if(ret)
    {
    return (vtkImageDrawROI*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageDrawROI;
}

//----------------------------------------------------------------------------
// Description:
// Constructor sets default values
vtkImageDrawROI::vtkImageDrawROI()
{
    this->HideROIOff();
    this->HideSplineOn();
    
    this->firstPoint = NULL;
    this->lastPoint = NULL;

    this->NumPoints = 0;
    this->NumSelectedPoints = 0;
    this->PointRadius = 1;

    this->PointColor[0] = 1;
    this->PointColor[1] = 0;
    this->PointColor[2] = 0;

    this->SelectedPointColor[0] = 1;
    this->SelectedPointColor[1] = 1;
    this->SelectedPointColor[2] = 0;

    this->LineColor[0] = 1;
    this->LineColor[1] = 0;
    this->LineColor[2] = 0;

    this->drawSelectBox = 0;
    this->sbox.x = 0;
    this->sbox.y = 0;
    this->sbox1.x = 0;
    this->sbox1.y = 0;
    this->sbox2.x = 0;
    this->sbox2.y = 0;

    this->Points = vtkPoints::New();
    this->Samples = vtkPoints::New();
    this->Shape = ROI_SHAPE_POLYGON;

    // Karl - 4.15.05
    this->image_reformat = NULL;
}

vtkImageDrawROI::~vtkImageDrawROI()
{
    this->Points->Delete();
}

vtkPoints* vtkImageDrawROI::GetPoints()
{
    Point *p = this->firstPoint;

    // count points
    int n=0;
    this->Points->Reset();
    while (p) {
        n++;
        this->Points->InsertNextPoint(p->x, p->y, 0);
        p = p->GetNext();
    }
    return this->Points;
}

static void Interpolate (Point *p, double t, double x0, double y0, double x1,
                         double y1, double x2, double y2, double x3, double y3)
{
    double x01 = (1.0 - t) * x0 + t * x1;
    double y01 = (1.0 - t) * y0 + t * y1;
    double x11 = (1.0 - t) * x1 + t * x2;
    double y11 = (1.0 - t) * y1 + t * y2;
    double x21 = (1.0 - t) * x2 + t * x3;
    double y21 = (1.0 - t) * y2 + t * y3;
    double x02 = (1.0 - t) * x01 + t * x11;
    double y02 = (1.0 - t) * y01 + t * y11;
    double x12 = (1.0 - t) * x11 + t * x21;
    double y12 = (1.0 - t) * y11 + t * y21;
    double x03 = (1.0 - t) * x02 + t * x12;
    double y03 = (1.0 - t) * y01 + t * y12;
    p->x = (int)x03;
    p->y = (int)y03;
}

vtkPoints* vtkImageDrawROI::GetPointsInterpolated(int density)
{
    // Samples closed curves only right now
    // Can sample open curves by simply omitting lastPoint-firstPoint curve
    this->Samples->Reset();
    Point *p0 = this->firstPoint;
    Point *p1 = this->firstPoint;
    Point *p2 = NULL;
    Point *p3 = NULL;
    double oneThird = 0.333333333333;

    // Zero points
    if (!p1) return this->Samples;
    p2 = p1->GetNext();

    // One point
    if (!p2)
    {
        this->Samples->InsertNextPoint(p1->x, p1->y, 0);
        return this->Samples;
    }
    p3 = p2->GetNext();

    // Two points
    if (!p3)
    {
        this->Samples->InsertNextPoint(p1->x, p1->y, 0);
        // Linearly interpolate between the two points
        for (int j = 1; j <= density; j++)
        {
            double t = (double)j / (double)(density + 1.0);
            double Xt = (1.0 - t) * (p1->x) + t * (p2->x);
            double Yt = (1.0 - t) * (p1->y) + t * (p2->y);
            this->Samples->InsertNextPoint((int)Xt, (int)Yt, 0);
        }
        this->Samples->InsertNextPoint(p2->x, p2->y, 0);
        return this->Samples;
    }

    // Three or more points
    // p0 == p1 == this->firstPoint, p2 == second point, p3 == third point
    while (p1)
    {
        // Draw curve connecting p1 and p2
        if (p1 == this->firstPoint)
        {
            // First curve--don't increment p0
            double p2dx = 0.5 * (p3->x - p1->x);
            double p2dy = 0.5 * (p3->y - p1->y);
            double p2_p1x = p2->x - p1->x;
            double p2_p1y = p2->y - p1->y;
            double p2_p1sq = p2_p1x * p2_p1x + p2_p1y * p2_p1y;
            double A = p2_p1x;
            double B = p2_p1y;
            double C = 0.5 * ((p1->x - p2->x) * (p1->x + p2->x) +
                              (p1->y - p2->y) * (p1->y + p2->y));
            double x0 = p2->x + p2dx;
            double y0 = p2->y + p2dy;
            double ax0by0c = A * x0 + B * y0 + C;
            // Derivative at p0 is reflection of derivative at p2
            // (p2dx, p2dy) over the line bisecting the edge connecting
            // p1 and p2
            double p1dx = p2->x - p1->x + p2dx + 2.0 *
                          (p1->x - p2->x) / p2_p1sq * ax0by0c;
            double p1dy = p2->y - p1->y + p2dy + 2.0 *
                          (p1->y - p2->y) / p2_p1sq * ax0by0c;
            for (int j = 1; j <= density; j++)
            {
                Point *p = new Point(0, 0);
                double t = (double)j / (double)(density + 1.0);
                Interpolate(p, t, p1->x, p1->y,
                            p1->x + oneThird * p1dx,
                            p1->y + oneThird * p1dy,
                            p2->x - oneThird * p2dx,
                            p2->y - oneThird * p2dy,
                            p2->x, p2->y);
                this->Samples->InsertNextPoint(p->x, p->y, 0);
            }
            p1 = p1->GetNext();
            p2 = p2->GetNext();
            p3 = p3->GetNext();
        }
        else if (p3)
        {
            // Middle curve
            double p1dx = 0.5 * (p2->x - p0->x);
            double p1dy = 0.5 * (p2->y - p0->y);
            double p2dx = 0.5 * (p3->x - p1->x);
            double p2dy = 0.5 * (p3->y - p1->y);
            double plx = oneThird * p1dx + p1->x;
            double ply = oneThird * p1dy + p1->y;
            double prx = p2->x - oneThird * p2dx;
            double pry = p2->y - oneThird * p2dy;
            for (int j = 1; j <= density; j++)
            {
                Point *p = new Point(0, 0);
                double t = (double)j / (double)(density + 1.0);
                Interpolate(p, t, p1->x, p1->y, plx, ply, prx, pry,
                            p2->x, p2->y);
                this->Samples->InsertNextPoint(p->x, p->y, 0);
            }
            p0 = p0->GetNext();
            p1 = p1->GetNext();
            p2 = p2->GetNext();
            p3 = p3->GetNext();
        }
        else if (p2 && !p3)
        {
            // Curve connecting last two control points
            double p1dx = 0.5 * (p2->x - p0->x);
            double p1dy = 0.5 * (p2->y - p0->y);
            double p1_p2x = p1->x - p2->x;
            double p1_p2y = p1->y - p2->y;
            double p1_p2sq = p1_p2x * p1_p2x + p1_p2y * p1_p2y;
            double A = p1->x - p2->x;
            double B = p1->y - p2->y;
            double C = 0.5 * ((p2->x - p1->x) * (p2->x + p1->x) +
                              (p2->y - p1->y) * (p2->y + p1->y));
            double x0 = p1->x + p1dx;
            double y0 = p1->y + p1dy;
            double ax0by0c = A * x0 + B * y0 + C;
            // Derivative at p2 is reflection of derivative at p1
            // (p1dx, p1dy) over the line bisecting the edge connecting
            // p2 and p1
            double p2dx = p1->x - p2->x + p1dx + 2.0 *
                          (p2->x - p1->x) / p1_p2sq * ax0by0c;
            double p2dy = p1->y - p2->y + p1dy + 2.0 *
                          (p2->y - p1->y) / p1_p2sq * ax0by0c;
            double plx = oneThird * p1dx + p1->x;
            double ply = oneThird * p1dy + p1->y;
            double prx = p2->x - oneThird * p2dx;
            double pry = p2->y - oneThird * p2dy;
            for (int j = 1; j <= density; j++)
            {
                Point *p = new Point(0, 0);
                double t = (double)j / (double)(density + 1.0);
                Interpolate(p, t, p1->x, p1->y, plx, ply, prx, pry,
                            p2->x, p2->y);
                this->Samples->InsertNextPoint(p->x, p->y, 0);
            }
            p0 = p0->GetNext();
            p1 = p1->GetNext();
            p2 = p2->GetNext();
            // p3 is already NULL
        }
        else // !p2 && !p3; p1 is lastPoint
        {
            // Curve connecting lastPoint (p1) and firstPoint (p2)
            p2 = this->firstPoint;
            p3 = p2->GetNext();
            double p1dx = 0.5 * (p2->x - p0->x);
            double p1dy = 0.5 * (p2->y - p0->y);
            double p2dx = 0.5 * (p3->x - p1->x);
            double p2dy = 0.5 * (p3->y - p1->y);
            double plx = oneThird * p1dx + p1->x;
            double ply = oneThird * p1dy + p1->y;
            double prx = p2->x - oneThird * p2dx;
            double pry = p2->y - oneThird * p2dy;
            for (int j = 1; j <= density; j++)
            {
                Point *p = new Point(0, 0);
                double t = (double)j / (double)(density + 1.0);
                Interpolate(p, t, p1->x, p1->y, plx, ply, prx, pry,
                            p2->x, p2->y);
                this->Samples->InsertNextPoint(p->x, p->y, 0);
            }
            p1 = NULL; // this is the last iteration: exit the loop now
        }
    }
    return this->Samples;
}

void vtkImageDrawROI::LoadStackPolygon(vtkPoints* pts)
{
    this->Points->Reset();
    int n = pts->GetNumberOfPoints();
    vtkFloatingPointType *rasPt;
    for (int i = 0; i < n; i++)
    {
        rasPt = pts->GetPoint(i);
        this->Points->InsertNextPoint(rasPt[0], rasPt[1], rasPt[2]);
    }
}

void vtkImageDrawROI::AppendPoint(int x, int y)
{
    Point *p = new Point(x, y);
    // Karl - 4.15.05
    if (image_reformat!=NULL) {
      image_reformat->Slice2IJK(x,y,p->x0, p->y0, p->z0); 
    }
    //<-

    if (this->firstPoint == NULL) {
        this->firstPoint = p;
    }
    else {
        this->lastPoint->next = p;
    }
    this->lastPoint = p;
    this->NumPoints++;

    this->Modified();
}

static int ClickPoint(Point *p, int x, int y, int r)
{
    if (x >= p->x - r && x <= p->x + r &&
        y >= p->y - r && y <= p->y + r)
        return 1;
    return 0;
}

void vtkImageDrawROI::TogglePoint(int x, int y)
{
    Point *p = this->firstPoint;
    while (p != NULL) {
        if (ClickPoint(p, x, y, this->PointRadius)) {
            if (p->IsSelected()) {
                p->Deselect();
                this->NumSelectedPoints--;
            }
            else {
                p->Select();
                this->NumSelectedPoints++;
            }
            this->Modified();
            return;
        }
        p = p->GetNext();
    }
}

void vtkImageDrawROI::SelectPoint(int x, int y)
{
    Point *p = this->firstPoint;
    while (p != NULL) {
        if (ClickPoint(p, x, y, this->PointRadius)) {
            p->Select();
            this->NumSelectedPoints++;
            this->Modified();
            return;
        }
        p = p->GetNext();
    }
}

void vtkImageDrawROI::DeselectPoint(int x, int y)
{
    Point *p = this->firstPoint;
    while (p != NULL) {
        if (ClickPoint(p, x, y, this->PointRadius)) {
            p->Deselect();
            this->NumSelectedPoints--;
            this->Modified();
            return;
        }
        p = p->GetNext();
    }
}

void vtkImageDrawROI::StartSelectBox(int x, int y)
{
    this->sbox.x = x;
    this->sbox.y = y;
}

void vtkImageDrawROI::DragSelectBox(int x, int y)
{
    this->drawSelectBox = 1;

    // Set sbox (Select Box) points so #1 is lower left
    if (x < this->sbox.x) {
        sbox1.x = x;
        sbox2.x = sbox.x;
    } else {
        sbox1.x = sbox.x;
        sbox2.x = x;
    }
    if (y < this->sbox.y) {
        sbox1.y = y;
        sbox2.y = sbox.y;
    } else {
        sbox1.y = sbox.y;
        sbox2.y = y;
    }
    // Force redraw
    this->Modified();
}

void vtkImageDrawROI::EndSelectBox(int x, int y)
{
    this->drawSelectBox = 0;

    // Set sbox (Select Box) points so #1 is lower left
    if (x < this->sbox.x) {
        sbox1.x = x;
        sbox2.x = sbox.x;
    } else {
        sbox1.x = sbox.x;
        sbox2.x = x;
    }
    if (y < this->sbox.y) {
        sbox1.y = y;
        sbox2.y = sbox.y;
    } else {
        sbox1.y = sbox.y;
        sbox2.y = y;
    }

    // Select all points in box
    int r = this->PointRadius;
    Point *p = this->firstPoint;
    while (p != NULL) {
        if (p->x+r >= sbox1.x && p->x-r <= sbox2.x &&
            p->y+r >= sbox1.y && p->y-r <= sbox2.y)
        {
            if (!p->IsSelected())
            {  
                p->Select();
                this->NumSelectedPoints++;
                this->Modified();
            }
        }
        p = p->GetNext();
    }

    // Force redraw
    this->Modified();
}

void vtkImageDrawROI::SelectAllPoints()
{
    Point *p = this->firstPoint;
    while (p != NULL) {
        p->Select();
        p = p->GetNext();
    }
    this->NumSelectedPoints = this->NumPoints;
    this->Modified();
}

void vtkImageDrawROI::DeselectAllPoints()
{
    Point *p = this->firstPoint;
    while (p != NULL) {
        p->Deselect();
        p = p->GetNext();
    }
    this->NumSelectedPoints = 0;
    this->Modified();
}

// Insert a point (x,y) between two existing points (CTJ).
void vtkImageDrawROI::InsertPoint(int x, int y)
{
    this->DeselectAllPoints();
    // Select only the point after which we want to insert (x,y)
    if (this->NumPoints >= 3) {
        // 1. Find nearest control point p to (x,y)
        // 2. Find control points pLeft, pRight before and after p
        // 3. Calculate distances from pLeft and pRight to (x,y)
        // 4. If pLeft is closer, then select pLeft; otherwise select p
        // Special case 1: p is firstPoint.
        //                 Select p.  Insert point before or after p
        //                 depending on whether pLeft or pRight is closer.
        // Special case 2: p is lastPoint.
        //                 Select p.  Insert point before or after p
        //                 depending on whether pLeft or pRight is closer.
        Point *p = this->firstPoint;
        int dx = x - p->x;
        int dy = y - p->y;
        int distsq = dx * dx + dy * dy;
        int mindistsq = distsq;
        Point *minp = this->firstPoint;
        p = p->GetNext();
        Point *pLeft = this->firstPoint;
        Point *minpLeft = pLeft;
        while (p != NULL) {
            dx = x - p->x;
            dy = y - p->y;
            distsq = dx * dx + dy * dy;
            if (distsq < mindistsq) {
                minp = p;
                mindistsq = distsq;
                minpLeft = pLeft;
            }
            pLeft = p;
            p = p->GetNext();
        }
        if (minp == this->firstPoint)
        {
            minpLeft = this->lastPoint;
            Point *minpRight = minp->GetNext();
            int dxLeft = x - minpLeft->x;
            int dyLeft = y - minpLeft->y;
            int dxRight = x - minpRight->x;
            int dyRight = y - minpRight->y;
            int leftDistsq = dxLeft * dxLeft + dyLeft * dyLeft;
            int rightDistsq = dxRight * dxRight + dyRight * dyRight;
            if (leftDistsq < rightDistsq)
            {
                if (this->Closed)
                {
                    // Doesn't matter whether we add point to
                    // beginning or end of polygon; let's add
                    // to end since it's easier
                    this->lastPoint->Select();
                    this->NumSelectedPoints++;
                    this->InsertAfterSelectedPoint(x, y);
                }
                else // Open contour
                {
                    // Add to beginning of polygon since the
                    // first point is closer to (x,y) than the
                    // last point
                    Point *p = new Point(x,y);
                    p->next = this->firstPoint;
                    this->firstPoint = p;
                    p->Select();
                    this->NumSelectedPoints++;
                    this->NumPoints++;
                }
            }
            else
            {
                minp->Select();
                this->NumSelectedPoints++;
                this->InsertAfterSelectedPoint(x, y);
            }
            return;
        }
        else if (minp == this->lastPoint)
        {
            // For last point: regardless of whether curve is open or
            // closed, simply add point based on distance from last point
            // to last point's left point and first point
            Point *minpRight = this->firstPoint;
            int dxLeft = x - minpLeft->x;
            int dyLeft = y - minpLeft->y;
            int dxRight = x - minpRight->x;
            int dyRight = y - minpRight->y;
            int leftDistsq = dxLeft * dxLeft + dyLeft * dyLeft;
            int rightDistsq = dxRight * dxRight + dyRight * dyRight;
            if (leftDistsq < rightDistsq) minpLeft->Select();
            else minp->Select();
        }
        else
        {
            Point *minpRight = minp->GetNext();
            int dxLeft = x - minpLeft->x;
            int dyLeft = y - minpLeft->y;
            int dxRight = x - minpRight->x;
            int dyRight = y - minpRight->y;
            int leftDistsq = dxLeft * dxLeft + dyLeft * dyLeft;
            int rightDistsq = dxRight * dxRight + dyRight * dyRight;
            if (leftDistsq < rightDistsq) minpLeft->Select();
            else minp->Select();
        }
        this->NumSelectedPoints++;
    }
    else if (this->NumPoints == 2) {
        Point *p = this->firstPoint;
        p->Select();
        this->NumSelectedPoints++;
    }
    // Insert (x,y) after the selected point.
    this->InsertAfterSelectedPoint(x, y);
}

// Insert a new point at (x,y) after the last selected point.
// If no points exist, create a new one and select it.
// If points exist, but none are selected, select the last.
void vtkImageDrawROI::InsertAfterSelectedPoint(int x, int y)
{
    Point *p1 = this->firstPoint;
    Point *p2 = NULL;
    Point *sel = NULL;

    // special case of empty list
    if (p1 == NULL) {
        // Add and select new point
        Point *p = new Point(x, y);
         
        // Karl - 4.15.05
        if (image_reformat!=NULL) {
            image_reformat->Slice2IJK(x,y,p->x0, p->y0, p->z0); 
        }
        //<-

        this->firstPoint = p;
        this->lastPoint = p;
        this->NumPoints++;
        p->Select();
        this->NumSelectedPoints++;
        this->Modified();
        return;
    }

    // p1 traverses list
    // p2 points to last point.
    p2 = p1;
    while (p1) {
        if (p1->IsSelected()) {
            sel = p1;
        }
        p2 = p1;
        p1 = p1->GetNext();
    }

    if (!sel) {
        p2->Select();
        sel = p2;
    }

    // Add new point
    p1 = sel;
    p2 = p1->GetNext(); 
    Point *p = new Point(x, y);
    // Karl - 4.15.05
    if (image_reformat!=NULL) {
      image_reformat->Slice2IJK(x,y,p->x0, p->y0, p->z0); 
    }
    //<-
    p1->next = p;
    p->next = p2;
    // p2 = NULL if p1 is tail, that's ok
    if (!p2)
        this->lastPoint = p;
    this->NumPoints++;

    // Select the new point instead of any others
    this->DeselectAllPoints();
    p->Select();
    this->NumSelectedPoints++;

    this->Modified();
}

void vtkImageDrawROI::DeleteSelectedPoints()
{
    Point *p1 = this->firstPoint;
    Point *p2;

    if (!p1) return;
    
    // Special case: firstPoint
    while (p1 && p1->IsSelected())
    {
        p2 = p1->GetNext();
        delete p1;
        this->NumPoints--;
        this->NumSelectedPoints--;
        p1 = p2;
        this->firstPoint = p1;
        this->Modified();
    }
    // None left?
    if (p1 == NULL) {
        this->lastPoint = NULL;
        return;
    }

    // Delete points after first point
    p2 = p1->GetNext();
    while (p2) 
    {
        if (p2->IsSelected()) 
        {
            // Are we deleting the last point?
            if (p2->GetNext() == NULL)
            {
                this->lastPoint = p1;

                // If deleting last point, select last point.
                this->lastPoint->Select();

                p1->next = NULL;
                delete p2;
                this->NumPoints--;
                this->NumSelectedPoints--;
                this->Modified();
                return;
            }
            p1->next = p2->GetNext();
            delete p2;
            this->NumPoints--;
            this->NumSelectedPoints--;
            this->Modified();
            p2 = p1->GetNext();
        }
        else {
            p1 = p2;
            if (p2)
                p2 = p2->GetNext();
        }
    }
}

void vtkImageDrawROI::DeleteAllPoints()
{
    Point *p1 = this->firstPoint;
    Point *p2;

    while (p1) {
        p2 = p1->GetNext();
        delete p1;
        p1 = p2;
    }
    this->firstPoint = this->lastPoint = NULL;
    this->NumPoints = this->NumSelectedPoints = 0;

    this->Modified();
}

void vtkImageDrawROI::MoveSelectedPoints(int deltaX, int deltaY)
{
    Point *p = this->firstPoint;
    while (p) {
        if (p->IsSelected()) {
            p->x += deltaX;
            p->y += deltaY;
           if (image_reformat!=NULL) {
            image_reformat->Slice2IJK(p->x,p->y,p->x0, p->y0, p->z0); 
        }
       }
        p = p->GetNext();
    }
    this->Modified();
}

void vtkImageDrawROI::MoveAllPoints(int deltaX, int deltaY)
{
    Point *p = this->firstPoint;
    while (p) {
        p->x += deltaX;
        p->y += deltaY;
        p = p->GetNext();
    }
    this->Modified();
}

int vtkImageDrawROI::IsNearSelected(int x, int y)
{
    int r = 3; // Distance for "nearness" in pixels
    int r2 = r * r;
    if (this->NumSelectedPoints < 1) return 0;
    if (this->NumSelectedPoints == 1)
    {
        Point *p = this->firstPoint;
        while (!p->IsSelected())
            p = p->GetNext();
        // Now p is the single selected point
        int dx = x - p->x;
        int dy = y - p->y;
        return (-r <= dx && dx <= r && -r <= dy && dy <= r) ? 1 : 0;
    }
    // There are 2 or more selected points
    Point *p0 = this->firstPoint;
    while (!p0->IsSelected())
        p0 = p0->GetNext();
    // First selected point was found; p0 points to it
    Point *p1;
    int distsq = 100000;
    for (int i = 1; i < this->NumSelectedPoints; i++)
    {
        p1 = p0->GetNext();
        while (!p1->IsSelected())
            p1 = p1->GetNext();
        // Next selected point was found; p1 points to it
        // Compute distance from (x,y) to line segment p0p1
        // using algorithm from
        // http://softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm
        // in the section "Distance to Ray or Segment"
        int vx = p1->x - p0->x;
        int vy = p1->y - p0->y;
        int wx = x - p0->x;
        int wy = y - p0->y;
        int c1, c2;
        if ((c1 = wx * vx + wy * vy) <= 0) distsq = wx * wx + wy * wy;
        if (distsq <= r2) return 1;
        else if ((c2 = vx * vx + vy * vy) <= c1)
        {
            int ux = x - p1->x;
            int uy = y - p1->y;
            distsq = ux * ux + uy * uy;
        }
        if (distsq <= r2) return 1;
        float b = (float)c1 / (float)c2;
        int pbx = (int)(p0->x + b * vx + 0.5);
        int pby = (int)(p0->y + b * vy + 0.5);
        int dx = x - pbx;
        int dy = y - pby;
        distsq = dx * dx + dy * dy;
        if (distsq <= r2) return 1;
        p0 = p1;
    }
    return 0;
}

static void ConvertColor(float *f, unsigned char *c)
{
    c[0] = (int)(f[0] * 255.0);
    c[1] = (int)(f[1] * 255.0);
    c[2] = (int)(f[2] * 255.0);
}

// Draw line including first, but not second end point
static void DrawLine(int xx1, int yy1, int xx2, int yy2, unsigned char color[3],
                     unsigned char *outPtr, int pNxnc, int pNc)
{
    unsigned char *ptr;
    int dx, dy, dy2, dx2, r, dydx2;
    int x, y, xInc;
    int nxnc = pNxnc, nc=pNc;
    int x1, y1, x2, y2;

    // Sort points so x1,y1 is below x2,y2
    if (yy1 <= yy2) {
        x1 = xx1;
        y1 = yy1;
        x2 = xx2;
        y2 = yy2;
    } else {
        x1 = xx2;
        y1 = yy2;
        x2 = xx1;
        y2 = yy1;
    }
    dx = abs(x2 - x1);
    dy = abs(y2 - y1);
    dx2 = dx << 1;
    dy2 = dy << 1;
    if (x1 < x2)
        xInc = 1;
    else
        xInc = -1;
    x = x1;
    y = y1;

    // Horizontal and vertical lines don't need to be special cases,
    // but it will make them faster.

    // Horizontal
    if (dy == 0)
    {
        if (x1 < x2) {
            for (x=x1; x < x2; x++)
                SET_PIXEL(x, y1, color);
        } else {
            for (x=x2; x < x1; x++)
                SET_PIXEL(x, y1, color);
        }
    }
    // Vertical
    else if (dx == 0)
    {
        for (y=y1; y < y2; y++)
            SET_PIXEL(x1, y, color);
    }

    // < 45 degree slope
    else if (dy <= dx)
    {
        dydx2 = (dy-dx) << 1;
        r = dy2 - dx;

        // Draw first point
        SET_PIXEL(x, y, color);

        // Draw up to (not including) end point
        if (x1 < x2)
        {
            while (x < x2)
            {
                x += xInc;
                if (r <= 0)
                    r += dy2;
                else {
                    y++;
                    r += dydx2;
                }
                SET_PIXEL(x, y, color);
            }
        }
        else
        {
            while (x > x2)
            {
                x += xInc;
                if (r <= 0)
                    r += dy2;
                else {
                    y++;
                    r += dydx2;
                }
                SET_PIXEL(x, y, color);
            }
        }
    }

    // > 45 degree slope
    else
    {
        dydx2 = (dx-dy) << 1;
        r = dx2 - dy;

        // Draw first point
        SET_PIXEL(x, y, color);

        // Draw up to (not including) end point
        while (y < y2)
        {
            y++;
            if (r <= 0)
                r += dx2;
            else {
                x += xInc;
                r += dydx2;
            }
            SET_PIXEL(x, y, color);
        }
    }
}

// Draw line including first, but not second end point
static void DrawThickLine(int xx1, int yy1, int xx2, int yy2, 
                          unsigned char color[3],
                          unsigned char *outPtr, int pNxnc, int pNc, int radius)
{
    unsigned char *ptr;
    int r, dx, dy, dy2, dx2, dydx2;
    int x, y, xInc;
    int nxnc = pNxnc, nc=pNc;
    int x1, y1, x2, y2;
    int rad=radius, rx1, rx2, ry1, ry2, rx, ry;

    // Sort points so x1,y1 is below x2,y2
    if (yy1 <= yy2) {
        x1 = xx1;
        y1 = yy1;
        x2 = xx2;
        y2 = yy2;
    } else {
        x1 = xx2;
        y1 = yy2;
        x2 = xx1;
        y2 = yy1;
    }
    dx = abs(x2 - x1);
    dy = abs(y2 - y1);
    dx2 = dx << 1;
    dy2 = dy << 1;
    if (x1 < x2)
        xInc = 1;
    else
        xInc = -1;
    x = x1;
    y = y1;

    // Draw first point
    rx1 = x - rad; ry1 = y - rad;
    rx2 = x + rad; ry2 = y + rad;
    for (ry=ry1; ry <= ry2; ry++)
        for (rx=rx1; rx <= rx2; rx++)
            SET_PIXEL(rx, ry, color);

    // < 45 degree slope
    if (dy <= dx)
    {
        dydx2 = (dy-dx) << 1;
        r = dy2 - dx;

        // Draw up to (not including) end point
        if (x1 < x2)
        {
            while (x < x2)
            {
                x += xInc;
                if (r <= 0)
                    r += dy2;
                else {
                    // Draw here for a thick line
                    rx1 = x - rad; ry1 = y - rad;
                    rx2 = x + rad; ry2 = y + rad;
                    for (ry=ry1; ry <= ry2; ry++)
                        for (rx=rx1; rx <= rx2; rx++)
                            SET_PIXEL(rx, ry, color);
                    y++;
                    r += dydx2;
                }
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
                    for (rx=rx1; rx <= rx2; rx++)
                        SET_PIXEL(rx, ry, color);
            }
        }
        else
        {
            while (x > x2)
            {
                x += xInc;
                if (r <= 0)
                    r += dy2;
                else {
                    // Draw here for a thick line
                    rx1 = x - rad; ry1 = y - rad;
                    rx2 = x + rad; ry2 = y + rad;
                    for (ry=ry1; ry <= ry2; ry++)
                        for (rx=rx1; rx <= rx2; rx++)
                            SET_PIXEL(rx, ry, color);
                    y++;
                    r += dydx2;
                }
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
                    for (rx=rx1; rx <= rx2; rx++)
                        SET_PIXEL(rx, ry, color);
            }
        }
    }

    // > 45 degree slope
    else
    {
        dydx2 = (dx-dy) << 1;
        r = dx2 - dy;

        // Draw up to (not including) end point
        while (y < y2)
        {
            y++;
            if (r <= 0)
                r += dx2;
            else {
                // Draw here for a thick line
                rx1 = x - rad; ry1 = y - rad;
                rx2 = x + rad; ry2 = y + rad;
                for (ry=ry1; ry <= ry2; ry++)
                    for (rx=rx1; rx <= rx2; rx++)
                        SET_PIXEL(rx, ry, color);
                x += xInc;
                r += dydx2;
            }
            rx1 = x - rad; ry1 = y - rad;
            rx2 = x + rad; ry2 = y + rad;
            for (ry=ry1; ry <= ry2; ry++)
                for (rx=rx1; rx <= rx2; rx++)
                    SET_PIXEL(rx, ry, color);
        }
    }
}

void vtkImageDrawROI::DrawSelectBox(vtkImageData *outData, int outExt[6])
{
    unsigned char color[3];
    unsigned char *outPtr = (unsigned char *) \
        outData->GetScalarPointerForExtent(outExt);
    long nxnc, nc, nx;
    Point p1, p2, p3, p4;
    long xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    nx = outExt[1] - outExt[0] + 1;
    nc = outData->GetNumberOfScalarComponents();
    nxnc = nx*nc;

    ConvertColor(this->SelectedPointColor, color);

    //    s2
    // s1
    //
    // p4 p3
    // p1 p2
    //
    p1.x = sbox1.x;
    p1.y = sbox1.y;
    p2.x = sbox2.x;
    p2.y = sbox1.y;
    p3.x = sbox2.x;
    p3.y = sbox2.y;
    p4.x = sbox1.x;
    p4.y = sbox2.y;

    if (p1.x >= xMin && p1.x <= xMax &&
        p1.y >= yMin && p1.y <= yMax &&
        p2.x >= xMin && p2.x <= xMax &&
        p2.y >= yMin && p2.y <= yMax &&
        p3.x >= xMin && p3.x <= xMax &&
        p3.y >= yMin && p3.y <= yMax &&
        p4.x >= xMin && p4.x <= xMax &&
        p4.y >= yMin && p4.y <= yMax)
    {
        DrawLine(p1.x, p1.y, p2.x, p2.y, color, outPtr, nxnc, nc);
        DrawLine(p2.x, p2.y, p3.x, p3.y, color, outPtr, nxnc, nc);
        DrawLine(p3.x, p3.y, p4.x, p4.y, color, outPtr, nxnc, nc);
        DrawLine(p4.x, p4.y, p1.x, p1.y, color, outPtr, nxnc, nc);
    }
}

void vtkImageDrawROI::DrawLines(vtkImageData *outData, int outExt[6])
{
    unsigned char color[3];
    unsigned char *outPtr = (unsigned char *) \
        outData->GetScalarPointerForExtent(outExt);
    int r = this->PointRadius;
    int nx, nc, nxnc;
    Point *p1, *p2;
    long xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    nx = outExt[1] - outExt[0] + 1;
    nc = outData->GetNumberOfScalarComponents();
    nxnc = nx*nc;

    ConvertColor(this->LineColor, color);

    p1 = this->firstPoint;
    if (!p1) return;
    if (image_reformat!=NULL) 
      image_reformat->IJK2Slice(p1->x0,p1->y0,p1->z0,p1->x,p1->y);
      
    p2 = p1->GetNext();    
    while (p2 != NULL)
    {
    //  4.15.05
        if (image_reformat!=NULL) 
      image_reformat->IJK2Slice(p2->x0,p2->y0,p2->z0,p2->x,p2->y);
    //<-

        if (this->GetShape() == ROI_SHAPE_POLYGON)
        {
            if (p1->x >= xMin && p1->x <= xMax &&
                p1->y >= yMin && p1->y <= yMax &&
                p2->x >= xMin && p2->x <= xMax &&
                p2->y >= yMin && p2->y <= yMax)
            {
                DrawLine(p1->x, p1->y, p2->x, p2->y, color, outPtr, nxnc, nc);
            }
        }
        else
        {
            if (p1->x-r >= xMin && p1->x+r <= xMax &&
                p1->y-r >= yMin && p1->y+r <= yMax &&
                p2->x-r >= xMin && p2->x+r <= xMax &&
                p2->y-r >= yMin && p2->y+r <= yMax)
            {
                DrawThickLine(p1->x, p1->y, p2->x, p2->y, color, outPtr, 
                    nxnc, nc, r);
            }
        }
        p1 = p2;
        p2 = p1->GetNext();
    }
}

void vtkImageDrawROI::DrawPoints(vtkImageData *outData, int outExt[6])
{
    int x, y, x1, x2, y1, y2;
    unsigned char color[3], *ptr;
    unsigned char *outPtr = (unsigned char *) \
        outData->GetScalarPointerForExtent(outExt);
    int r = this->PointRadius;
    Point *p;
    int nx, nc, nxnc;
    int xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    nx = outExt[1] - outExt[0] + 1;
    nc = outData->GetNumberOfScalarComponents();
    nxnc = nx*nc;

    p = this->firstPoint;
    while (p)
    {
        if (p->IsSelected())
            ConvertColor(this->SelectedPointColor, color);
        else
            ConvertColor(this->PointColor, color);
    // 4.15.05
        if (image_reformat!=NULL) 
      image_reformat->IJK2Slice(p->x0,p->y0,p->z0,p->x,p->y);
    //<-
       x1 = p->x - r;
        x2 = p->x + r;
        y1 = p->y - r;
        y2 = p->y + r;
        if (x1 >= xMin && x1 <= xMax && y1 >= yMin && y1 <= yMax &&
            x2 >= xMin && x2 <= xMax && y2 >= yMin && y2 <= yMax)
        {
            for (y=y1; y <= y2; y++)
                for (x=x1; x <= x2; x++)
                    SET_PIXEL(x, y, color);
        }
        p = p->GetNext();
    }
}

//>> AT 01/17/01
void vtkImageDrawROI::DrawCrosses(vtkImageData *outData, int outExt[6])
{
    int x, y, x1, x2, y1, y2;
    unsigned char color[3], *ptr;
    unsigned char *outPtr = (unsigned char *) \
        outData->GetScalarPointerForExtent(outExt);
    int r = this->PointRadius;
    Point *p;
    int nx, nc, nxnc;
    int xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    nx = outExt[1] - outExt[0] + 1;
    nc = outData->GetNumberOfScalarComponents();
    nxnc = nx*nc;

    p = this->firstPoint;
    while (p)
    {
        if (p->IsSelected())
            ConvertColor(this->SelectedPointColor, color);
        else
            ConvertColor(this->PointColor, color);
        // Karl - 4.15.05
        if (image_reformat!=NULL) 
            image_reformat->IJK2Slice(p->x0,p->y0,p->z0,p->x,p->y);
        //<-

        x1 = p->x - r;
        x2 = p->x + r;
        y1 = p->y - r;
        y2 = p->y + r;
        if (x1 >= xMin && x1 <= xMax && y1 >= yMin && y1 <= yMax &&
            x2 >= xMin && x2 <= xMax && y2 >= yMin && y2 <= yMax)
          {
            for(y = y1; y <= y2; y++)
              SET_PIXEL(p->x, y, color);
            
            for(x = x1; x <= x2; x++)
              SET_PIXEL(x, p->y, color);
          }
        p = p->GetNext();
    }
}
//<< AT 01/17/01

//>> AT 01/19/01
void vtkImageDrawROI::DrawBoxes(vtkImageData *outData, int outExt[6])
{
    int x, y, x1, x2, y1, y2;
    unsigned char color[3], *ptr;
    unsigned char *outPtr = (unsigned char *) \
        outData->GetScalarPointerForExtent(outExt);
    int r = this->PointRadius;
    Point *p;
    int nx, nc, nxnc;
    int xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    nx = outExt[1] - outExt[0] + 1;
    nc = outData->GetNumberOfScalarComponents();
    nxnc = nx*nc;

    p = this->firstPoint;
    while (p)
    {
        if (p->IsSelected())
            ConvertColor(this->SelectedPointColor, color);
        else
            ConvertColor(this->PointColor, color);
        // Karl - 4.15.05
        if (image_reformat!=NULL) 
            image_reformat->IJK2Slice(p->x0,p->y0,p->z0,p->x,p->y);
        //<-
        x1 = p->x - r;
        x2 = p->x + r;
        y1 = p->y - r;
        y2 = p->y + r;
        if (x1 >= xMin && x1 <= xMax && y1 >= yMin && y1 <= yMax &&
            x2 >= xMin && x2 <= xMax && y2 >= yMin && y2 <= yMax)
          {
            for(y = y1; y <= y2; y++)
              {
            SET_PIXEL(x1, y, color);
            SET_PIXEL(x2, y, color);
              }
            
            for(x = x1; x <= x2; x++)
              {
            SET_PIXEL(x, y1, color);
            SET_PIXEL(x, y2, color);
              }
          }
        p = p->GetNext();
    }
}
//<< AT 01/19/01

static void DrawCurve(double x0, double y0, double x1, double y1,
                      double x2, double y2, double x3, double y3,
                      vtkImageData *outData, int outExt[6],
                      unsigned char color[3])
{       
    double x3_x0 = x3 - x0;
    double y3_y0 = y3 - y0;
    double d03 = x3_x0 * x3_x0 + y3_y0 * y3_y0;
    if (d03 <= 1.0)
    {
        // Curve can be approximated by a line segment
        unsigned char *outPtr = (unsigned char *) \
            outData->GetScalarPointerForExtent(outExt);
        long xMin, xMax, yMin, yMax;
        xMin = outExt[0];
        xMax = outExt[1];
        yMin = outExt[2];
        yMax = outExt[3];
        int nx, nc, nxnc;
        nx = outExt[1] - outExt[0] + 1;
        nc = outData->GetNumberOfScalarComponents();
        nxnc = nx * nc;
        int xx0 = (int)x0;
        int yy0 = (int)y0;
        int xx3 = (int)x3;
        int yy3 = (int)y3;
        //if (image_reformat!=NULL) 
        //  image_reformat->IJK2Slice(p->x0,p->y0,p->z0,p->x,p->y);
        if (xMin <= xx0 && xx0 <= xMax &&
            yMin <= yy0 && yy0 <= yMax &&
            xMin <= xx3 && xx3 <= xMax &&
            yMin <= yy3 && yy3 <= yMax)
        {
            DrawLine(xx0, yy0, xx3, yy3, color, outPtr, nxnc, nc);
        }
    }
    else
    {
        // Curve needs to be subdivided further
        double x01 = 0.5 * (x0 + x1);
        double y01 = 0.5 * (y0 + y1);
        double x11 = 0.5 * (x1 + x2);
        double y11 = 0.5 * (y1 + y2);
        double x21 = 0.5 * (x2 + x3);
        double y21 = 0.5 * (y2 + y3);
        double x02 = 0.5 * (x01 + x11);
        double y02 = 0.5 * (y01 + y11);
        double x12 = 0.5 * (x11 + x21);
        double y12 = 0.5 * (y11 + y21);
        double x03 = 0.5 * (x02 + x12);
        double y03 = 0.5 * (y02 + y12);
        DrawCurve(x0, y0, x01, y01, x02, y02, x03, y03, outData, outExt, color);
        DrawCurve(x03, y03, x12, y12, x21, y21, x3, y3, outData, outExt, color);
    }
}

void vtkImageDrawROI::DrawSpline(vtkImageData *outData, int outExt[6])
{   
    if (NumPoints < 2) return; // No nondegenerate curve to draw for < 2 points
    long xMin, xMax, yMin, yMax;
    xMin = outExt[0];
    xMax = outExt[1];
    yMin = outExt[2];
    yMax = outExt[3];
    if (NumPoints == 2)
    {
        // Connect the two points with a line segment
        unsigned char *outPtr = (unsigned char *) \
            outData->GetScalarPointerForExtent(outExt);
        int nx, nc, nxnc;
        nx = outExt[1] - outExt[0] + 1;
        nc = outData->GetNumberOfScalarComponents();
        nxnc = nx * nc;
        unsigned char color[3];
        color[0] = 0;
        color[1] = 255;
        color[2] = 0;
        Point *p = this->firstPoint;
        Point *q = p->GetNext();
        if (image_reformat!=NULL)
        {
          image_reformat->IJK2Slice(p->x0,p->y0,p->z0,p->x,p->y);
          image_reformat->IJK2Slice(q->x0,q->y0,q->z0,q->x,q->y);
        }
        if (xMin <= p->x && p->x <= xMax &&
            yMin <= p->y && p->y <= yMax &&
            xMin <= q->x && q->x <= xMax &&
            yMin <= q->y && q->y <= yMax)
        {
            DrawLine(p->x, p->y, q->x, q->y, color, outPtr, nxnc, nc);
        }
        return;
    }
    double oneThird = 0.333333333333;
    Point *p0 = this->firstPoint; 
    Point *p1 = p0->GetNext();
    Point *p2 = p1->GetNext();
    Point *p3 = p2->GetNext(); // if only 3 points, this is NULL
    double plx, ply, prx, pry; // intermediate point variables
    double p2dx, p2dy; // derivative at p2
    // Draw first segment (curve connecting p0 and p1)
    double p1dx = 0.5 * (p2->x - p0->x);
    double p1dy = 0.5 * (p2->y - p0->y);
    double p0_p1x = p0->x - p1->x;
    double p0_p1y = p0->y - p1->y;
    double p0_p1sq = p0_p1x * p0_p1x + p0_p1y * p0_p1y;
    double p0dx = p1dx;
    double p0dy = p1dy;
    if (p0_p1sq > 0.0)
    {
        double dotprod = p1dx * p0_p1x + p1dy * p0_p1y;
        dotprod *= 2.0 / p0_p1sq;
        p0dx = p0_p1x * dotprod - p1dx;
        p0dy = p0_p1y * dotprod - p1dy;
    }
    unsigned char color[3];
    color[0] = 0;
    color[1] = 255;
    color[2] = 0;
    DrawCurve(p0->x, p0->y,
              p0->x + oneThird * p0dx, p0->y + oneThird * p0dy,
              p1->x - oneThird * p1dx, p1->y - oneThird * p1dy,
              p1->x, p1->y,
              outData, outExt, color);
    while (p3 != NULL)
    {
        // Draw middle segment (curve connecting p1 and p2)
        p1dx = 0.5 * (p2->x - p0->x);
        p1dy = 0.5 * (p2->y - p0->y);
        p2dx = 0.5 * (p3->x - p1->x);
        p2dy = 0.5 * (p3->y - p1->y);
        plx = oneThird * p1dx + p1->x;
        ply = oneThird * p1dy + p1->y;
        prx = p2->x - oneThird * p2dx;
        pry = p2->y - oneThird * p2dy;
        DrawCurve(p1->x, p1->y, plx, ply, prx, pry, p2->x, p2->y,
                  outData, outExt, color);
        p0 = p0->GetNext();
        p1 = p1->GetNext();
        p2 = p2->GetNext();
        p3 = p3->GetNext();
    }
    // Draw last segment (curve connecting p1 and p2)
    p1dx = 0.5 * (p2->x - p0->x);
    p1dy = 0.5 * (p2->y - p0->y);
    double p2_p1x = p2->x - p1->x;
    double p2_p1y = p2->y - p1->y;
    double p2_p1sq = p2_p1x * p2_p1x + p2_p1y * p2_p1y;
    p2dx = p1dx;
    p2dy = p1dy;
    if (p2_p1sq > 0.0)
    {
        double dotprod = p1dx * p2_p1x + p1dy * p2_p1y;
        dotprod *= 2.0 / p2_p1sq;
        p2dx = dotprod * p2_p1x - p1dx;
        p2dy = dotprod * p2_p1y - p1dy;
    }
    plx = oneThird * p1dx + p1->x;
    ply = oneThird * p1dy + p1->y;
    prx = p2->x - oneThird * p2dx;
    pry = p2->y - oneThird * p2dy;
    DrawCurve(p1->x, p1->y, plx, ply, prx, pry, p2->x, p2->y, outData, outExt,
              color);
    // Connect last point and first point if curve is closed
    if (this->Closed)
    {
        // Currently p2 is last point, p3 is null, and p1, p0 consecutively
        // are before p2.  Move p0, p1 forward by one point, and set p2, p3
        // to be the first and second points, respectively.
        p0 = p0->GetNext();
        p1 = p1->GetNext();
        p2 = this->firstPoint;
        p3 = p2->GetNext();
        // Draw the segment (curve connecting p1 and p2)
        p1dx = 0.5 * (p2->x - p0->x);
        p1dy = 0.5 * (p2->y - p0->y);
        p2dx = 0.5 * (p3->x - p1->x);
        p2dy = 0.5 * (p3->y - p1->y);
        plx = oneThird * p1dx + p1->x;
        ply = oneThird * p1dy + p1->y;
        prx = p2->x - oneThird * p2dx;
        pry = p2->y - oneThird * p2dy;
        DrawCurve(p1->x, p1->y, plx, ply, prx, pry, p2->x, p2->y,
                  outData, outExt, color);
    }
}

//----------------------------------------------------------------------------
// Description:
// this is cool
void vtkImageDrawROI::ExecuteData(vtkDataObject *out)
{

  // let superclass allocate data
  this->vtkImageInPlaceFilter::ExecuteData(out);

  if ( this->GetInput()->GetDataObjectType() != VTK_IMAGE_DATA )
  { vtkWarningMacro ("was sent non-image data data object");
    return;
  }

  vtkImageData *inData = (vtkImageData *) this->GetInput();
  vtkImageData *outData = this->GetOutput();
  int *outExt = outData->GetWholeExtent();

  int x1, *inExt;
  
    // ensure 3 component data
    x1 = inData->GetNumberOfScalarComponents();
    if (!(x1 == 3 || x1 == 4))
    {
        vtkErrorMacro("Input has "<<x1<<" components instead of 3 or 4.");
        return;
    }

    // Ensure input is unsigned char
    x1 = inData->GetScalarType();
    if (x1 != VTK_UNSIGNED_CHAR)
    {
        vtkErrorMacro("Input is type "<<x1<<" instead of unsigned char.");
        return;
    }

    // Ensure intput is 2D
    inExt = this->GetInput()->GetWholeExtent();
    if (inExt[5] != inExt[4]) {
        vtkErrorMacro("Input must be 2D.");
        return;
    }
  
    // Draw and connect points
    if (!(this->HideROI))
    {
        if (!this->HideSpline)
        {   this->DrawSpline(outData, outExt);
        }
        switch (this->GetShape())
        {
        case ROI_SHAPE_POLYGON:
            DrawLines(outData, outExt);
            DrawPoints(outData, outExt);
            break;
        case ROI_SHAPE_LINES:
            DrawLines(outData, outExt);
            DrawPoints(outData, outExt);
            break;
        case ROI_SHAPE_POINTS:
            DrawPoints(outData, outExt);
            break;
        //>> AT 01/17/01 01/19/01
        case ROI_SHAPE_CROSSES:
          DrawCrosses(outData, outExt);
          break;
        case ROI_SHAPE_BOXES:
          DrawBoxes(outData, outExt);
          break;
        //<< AT 01/17/01 01/19/01
        }
    }

    // Draw Select Box
    if (this->drawSelectBox)
    {
        DrawSelectBox(outData, outExt);
    }
}

void vtkImageDrawROI::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkImageInPlaceFilter::PrintSelf(os,indent);
    this->Points->PrintSelf(os, indent);
        os << indent << "DrawSelectBox: " << this->drawSelectBox;
        os << indent << "sbox x = " << this->sbox.x;
        os << indent << "sbox y = " << this->sbox.y;
        os << indent << "sbox1 x = " << this->sbox1.x;
        os << indent << "sbox1 y = " << this->sbox1.y;
        os << indent << "sbox2 x = " << this->sbox2.x;
        os << indent << "sbox2 y = " << this->sbox2.y;
        os << indent << "NumPoints: " << this->NumPoints;
        os << indent << "NumSelectedPoints: " << this->NumSelectedPoints;
        os << indent << "pointRadius: " << this->PointRadius;
    os << indent << "HideROI: " << this->HideROI;
    os << indent << "HideSpline: " << this->HideSpline;
        os << indent << "Shape: " << this->Shape;
        os << indent << "PointColor[0]: " << this->PointColor[0];
        os << indent << "PointColor[1]: " << this->PointColor[1];
        os << indent << "pointColor[2]: " << this->PointColor[2];
        os << indent << "SelectedPointColor[0]: " << this->SelectedPointColor[0];
        os << indent << "SelectedPointColor[1]: " << this->SelectedPointColor[1];
        os << indent << "SelectedPointColor[2]: " << this->SelectedPointColor[2];
        os << indent << "LineColor[0]: " << this->LineColor[0];
        os << indent << "LineColor[1]: " << this->LineColor[1];
        os << indent << "LineColor[2]: " << this->LineColor[2];
}
