/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSuperquadricTensorGlyph.cxx,v $
  Date:      $Date: 2006/05/26 20:04:17 $
  Version:   $Revision: 1.14 $

=========================================================================auto=*/
#include "vtkSuperquadricTensorGlyph.h"

#include "vtkObjectFactory.h"
#include "vtkTransform.h"
#include "vtkMath.h"
#include "vtkTensor.h"
#include "vtkFloatArray.h"
#include "vtkPolyData.h"
#include "vtkPointData.h"
#include "vtkCellArray.h"
#include "vtkImageData.h"
#include "vtkSuperquadricSource2.h"
#include "vtkTensorMathematics.h"
#include "vtkInteractiveTensorGlyph.h"

#include <time.h>

vtkCxxSetObjectMacro(vtkSuperquadricTensorGlyph,ScalarMask,vtkImageData);
vtkCxxSetObjectMacro(vtkSuperquadricTensorGlyph,VolumePositionMatrix,vtkMatrix4x4);
vtkCxxSetObjectMacro(vtkSuperquadricTensorGlyph,TensorRotationMatrix,vtkMatrix4x4);

//------------------------------------------------------------------------------
vtkSuperquadricTensorGlyph* vtkSuperquadricTensorGlyph::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSuperquadricTensorGlyph");
  if(ret)
    {
    return (vtkSuperquadricTensorGlyph*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSuperquadricTensorGlyph;
}




//------------------------------------------------------------------------------
// Construct object with defaults from superclass: these are
// scaling on and scale factor 1.0. Eigenvalues are 
// extracted, glyphs are colored with input scalar data, and logarithmic
// scaling is turned off.
vtkSuperquadricTensorGlyph::vtkSuperquadricTensorGlyph()
{
  // Instead of coloring glyphs by passing through input
  // scalars, color according to features we are computing.
  this->ScalarMeasure = 0; // Need to initialed var before callling ColorGlyphsWithLinearMeasure
  this->ColorGlyphsWithLinearMeasure();

  this->VolumePositionMatrix = NULL;
  this->TensorRotationMatrix = NULL;

  this->MaskGlyphsWithScalars = 0;
  this->ScalarMask = NULL;
  this->Resolution = 1;
  
  this->Gamma =1;
  this->ThetaResolution=5;
  this->PhiResolution=5;
  
}

vtkSuperquadricTensorGlyph::~vtkSuperquadricTensorGlyph()
{

}

void vtkSuperquadricTensorGlyph::ColorGlyphsWithLinearMeasure() {
  this->ColorGlyphsWith(VTK_LINEAR_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithSphericalMeasure() {
  this->ColorGlyphsWith(VTK_SPHERICAL_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithPlanarMeasure() {
  this->ColorGlyphsWith(VTK_PLANAR_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithMaxEigenvalue() {
  this->ColorGlyphsWith(VTK_MAX_EIGENVAL_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithMiddleEigenvalue() {
  this->ColorGlyphsWith(VTK_MIDDLE_EIGENVAL_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithMinEigenvalue() {
  this->ColorGlyphsWith(VTK_MIN_EIGENVAL_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithMaxMinusMidEigenvalue() {
  this->ColorGlyphsWith(VTK_EIGENVAL_DIFFERENCE_MAX_MID_MEASURE);
}

void vtkSuperquadricTensorGlyph::ColorGlyphsWithDirection() {
  this->ColorGlyphsWith(VTK_DIRECTION_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithRelativeAnisotropy() {
  this->ColorGlyphsWith(VTK_RELATIVE_ANISOTROPY_MEASURE);
}
void vtkSuperquadricTensorGlyph::ColorGlyphsWithFractionalAnisotropy() {
  this->ColorGlyphsWith(VTK_FRACTIONAL_ANISOTROPY_MEASURE);
}

void vtkSuperquadricTensorGlyph::ColorGlyphsWith(int measure) {
  if (this->ScalarMeasure != measure) 
    {
      this->ColorGlyphs = 0;
      this->ColorGlyphsWithAnisotropy = 1;
      this->ScalarMeasure = measure;
      this->Modified();
    }
}

// Lauren we need to check that the scalarmask has the same
// extent!

void vtkSuperquadricTensorGlyph::Execute()
{
  vtkDataArray *inTensors;
  vtkFloatingPointType tensor[3][3];
  vtkDataArray *inScalars;
  int numPts, numSourcePts, numSourceCells;
  int inPtId, i, j;
  vtkPoints *sourcePts;
  vtkDataArray *sourceNormals;
  vtkCellArray *sourceCells, *cells;  
  vtkPoints *newPts;
  vtkFloatArray *newScalars=NULL;
  vtkFloatArray *newNormals=NULL;
  vtkFloatingPointType *x, s;
  vtkFloatingPointType x2[3];
  vtkTransform *trans = vtkTransform::New();
  vtkTransform *rotate= vtkTransform::New();
  vtkMatrix4x4 *matrix = vtkMatrix4x4::New();
  vtkCell *cell;
  vtkIdList *cellPts;
  int npts;
  vtkIdType *pts;
  int cellId;
  int ptOffset=0;
  vtkFloatingPointType *m[3], w[3], *v[3];
  vtkFloatingPointType m0[3], m1[3], m2[3];
  vtkFloatingPointType v0[3], v1[3], v2[3];
  vtkFloatingPointType xv[3], yv[3], zv[3];
  vtkFloatingPointType maxScale;
  vtkPointData *pd, *outPD;
#if (VTK_MAJOR_VERSION >= 5)
  vtkDataSet *input = this->GetPolyDataInput(0);
#else
  vtkDataSet *input = this->GetInput();
#endif
  vtkPolyData *output = this->GetOutput();

  if (this->GetSource() == NULL)
    {
    vtkDebugMacro("No source.");
    return;
    }
  

  vtkDataArray *inMask;
  int doMasking;
  // time
  clock_t tStart = 0;
  tStart = clock();


  // set up working matrices
  m[0] = m0; m[1] = m1; m[2] = m2; 
  v[0] = v0; v[1] = v1; v[2] = v2; 

  vtkDebugMacro(<<"Generating tensor glyphs");

  pd = input->GetPointData();
  outPD = output->GetPointData();
  inTensors = pd->GetTensors();
  inScalars = pd->GetScalars();
  numPts = input->GetNumberOfPoints();
  inMask = NULL;
  if (this->ScalarMask)
    {
    inMask = this->ScalarMask->GetPointData()->GetScalars();
    }

  if ( !inTensors || numPts < 1 )
    {
    vtkErrorMacro(<<"No data to glyph!");
    return;
    }
  //
  // Allocate storage for output PolyData
  //
  //cout<<"Before instanciation of sq"<<endl;
  vtkSuperquadricSource2 *sq = vtkSuperquadricSource2::New();
  sq->SetThetaResolution(this->ThetaResolution);
  sq->SetPhiResolution(this->PhiResolution);
  sq->Update();
  
  //cout<<"After updating sq"<<endl;
  
  pts = new vtkIdType[sq->GetOutput()->GetMaxCellSize()];

  
  sourcePts = sq->GetOutput()->GetPoints();
  numSourcePts = sourcePts->GetNumberOfPoints();
  numSourceCells = sq->GetOutput()->GetNumberOfCells();


  //cout<<"Allocating datasets"<<endl;
  //cout<<"Num points: "<<numPts<<"  Num Source Pts: "<<numSourcePts<<endl;
  newPts = vtkPoints::New();
  newPts->Allocate(numPts*numSourcePts);

  //cout<<"Allocating cells"<<endl;
  // Setting up for calls to PolyData::InsertNextCell()
  if ( (sourceCells=sq->GetOutput()->GetVerts())->GetNumberOfCells() > 0 )
    {
      cells = vtkCellArray::New();
      cells->Allocate(numPts*sourceCells->GetSize());
      output->SetVerts(cells);
      cells->Delete();
    }
  if ( (sourceCells=sq->GetOutput()->GetLines())->GetNumberOfCells() > 0 )
    {
      cells = vtkCellArray::New();
      cells->Allocate(numPts*sourceCells->GetSize());
      output->SetLines(cells);
      cells->Delete();
    }
  if ( (sourceCells=sq->GetOutput()->GetPolys())->GetNumberOfCells() > 0 )
    {
      cells = vtkCellArray::New();
      cells->Allocate(numPts*sourceCells->GetSize());
      output->SetPolys(cells);
      cells->Delete();
    }
  if ( (sourceCells=sq->GetOutput()->GetStrips())->GetNumberOfCells() > 0 )
    {
      //cout<<"Allocating Strips"<<endl;
      cells = vtkCellArray::New();
      cells->Allocate(numPts*sourceCells->GetSize());
      output->SetStrips(cells);
      cells->Delete();
    }

  
  // copy point data through or create it here
  //cout<<"Graba point data"<<endl;
  pd = sq->GetOutput()->GetPointData();

  // always output scalars
  //cout<<"Allocating scalars"<<endl;
  
  newScalars = vtkFloatArray::New();
  newScalars->Allocate(numPts*numSourcePts);
  
  if ( (sourceNormals = pd->GetNormals()) )
    {
      newNormals = vtkFloatArray::New();
      // vtk4.0, copied from tensor glyph filter
      newNormals->SetNumberOfComponents(3);
      newNormals->Allocate(3*numPts*numSourcePts);
      //newNormals->Allocate(numPts*numSourcePts);
    }

  // Figure out whether we are using a mask (if the user has
  // asked us to mask and also has set the mask input).
  doMasking = 0;
  //if (inMask && this->MaskGlyphsWithScalars)
  //doMasking = 1;
  if (this->MaskGlyphsWithScalars)
    {
      if (inMask)
    {
      doMasking = 1;
    }
      else 
    {
      vtkErrorMacro("User has not set input mask, but has requested MaskGlyphsWithScalars");
    }
    }

  // figure out if we are transforming output point locations
  vtkTransform *userVolumeTransform = vtkTransform::New();
  if (this->VolumePositionMatrix)
    {
      userVolumeTransform->SetMatrix(this->VolumePositionMatrix);
      userVolumeTransform->PreMultiply();
    }

  //
  // Traverse all Input points, transforming glyph at Source points
  //
  trans->PreMultiply();

  cout << "glyph time before pt traversal: " << clock() - tStart << endl;
  cout <<"Starting iterations: "<<endl;
  
  for (inPtId=0; inPtId < numPts; inPtId=inPtId+this->Resolution)
    {

    if ( ! (inPtId % 10000) ) 
      {
      this->UpdateProgress ((vtkFloatingPointType)inPtId/numPts);
      if (this->GetAbortExecute())
        {
        break;
        }
      }

    //ptIncr = inPtId * numSourcePts;

    //tensor = inTensors->GetTuple(inPtId);
    inTensors->GetTuple(inPtId,(vtkFloatingPointType *)tensor);

    trans->Identity();

    // threshold: if trace is <= 0, don't do expensive computations
    // This used to be: tensor ->GetComponent(0,0) + 
    // tensor->GetComponent(1,1) + tensor->GetComponent(2,2);
    vtkFloatingPointType trace = tensor[0][0] + tensor[1][1] + tensor[2][2];


    // only display this glyph if either:
    // a) we are masking and the mask is 1 at this location.
    // b) the trace is positive and we are not masking (default).
    // (If the trace is 0 we don't need to go through the code just to
    // display nothing at the end, since we expect that our data has
    // non-negative eigenvalues.)
    if ((doMasking && inMask->GetTuple1(inPtId)) || (!this->MaskGlyphsWithScalars && trace > 0)) 
      {
      //Compute eigendecomposition

      if ( this->ExtractEigenvalues ) // extract appropriate eigenfunctions
        {
        for (j=0; j<3; j++)
          {
          for (i=0; i<3; i++)
            {
            // transpose
            //m[i][j] = tensor[i+3*j];
            m[i][j] = tensor[j][i];
            }
          }
        //vtkMath::Jacobi(m, w, v);
        vtkTensorMathematics::TeemEigenSolver(m,w,v);
        //copy eigenvectors
        xv[0] = v[0][0]; xv[1] = v[1][0]; xv[2] = v[2][0];
        yv[0] = v[0][1]; yv[1] = v[1][1]; yv[2] = v[2][1];
        zv[0] = v[0][2]; zv[1] = v[1][2]; zv[2] = v[2][2];
        }
      else //use tensor columns as eigenvectors
        {
        for (i=0; i<3; i++)
          {
          //xv[i] = tensor[i];
          //yv[i] = tensor[i+3];
          //zv[i] = tensor[i+6];
          xv[i] = tensor[0][i];
          yv[i] = tensor[1][i];
          zv[i] = tensor[2][i];
          }

          w[0] = vtkMath::Normalize(xv);
          w[1] = vtkMath::Normalize(yv);
          w[2] = vtkMath::Normalize(zv);
        }
    
    
      double cl = vtkTensorMathematics::LinearMeasure(w);
      double cp = vtkTensorMathematics::PlanarMeasure(w);
      double alpha;
      double beta;

      //cout<<"Computing alpha and beta"<<endl;
      if(cp<cl) {
        alpha = pow((1-cp),this->Gamma);
        beta = pow((1-cl),this->Gamma);
        sq->SetAxisOfSymmetry(0);
      } else {
        alpha = pow((1-cl),this->Gamma);     
        beta= pow((1-cp),this->Gamma);
        sq->SetAxisOfSymmetry(2);
      }      
      //cout<<"Alpha: "<<alpha<<"  Beta: "<<beta<<endl;
      sq->SetPhiRoundness(beta);
      sq->SetThetaRoundness(alpha);

      //cout<<"Updating sq for point :"<<inPtId<<endl;
      sq->Update();
      //cout<<"Update done"<<endl;

      sourcePts = sq->GetOutput()->GetPoints();

      // copy topology
      //cout<<"Copy cell topology"<<endl;
      for (cellId=0; cellId < numSourceCells; cellId++)
        {
        cell = sq->GetOutput()->GetCell(cellId);
        cellPts = cell->GetPointIds();
        npts = cellPts->GetNumberOfIds();
        for (i=0; i < npts; i++)
          {
          //pts[i] = cellPts->GetId(i) + ptIncr;
          pts[i] = cellPts->GetId(i) + ptOffset;
          }
        output->InsertNextCell(cell->GetCellType(),npts,pts);
        }

      //cout<<"Cell topology done"<<endl;

      // translate Source to Input point
      x = input->GetPoint(inPtId);
      // If we have a user-specified matrix determining the points

      if (this->VolumePositionMatrix)
        {
        userVolumeTransform->TransformPoint(x,x2);
        // point x to x2 now
        x = x2;
        }  
      trans->Translate(x[0], x[1], x[2]);


      // output scalars before modifying the value of 
      // the eigenvalues (scaling, etc)
      if ( inScalars && this->ColorGlyphs ) 
        {
        // Copy point data from source
        s = inScalars->GetTuple1(inPtId);
        }
      else 
        {
        vtkTensorMathematics::FixNegativeEigenvalues(w);

        switch (this->ScalarMeasure) 
          {
        case VTK_LINEAR_MEASURE:
          s = vtkTensorMathematics::LinearMeasure(w);
          break;
        case VTK_PLANAR_MEASURE:
          s = vtkTensorMathematics::PlanarMeasure(w);
          break;
        case VTK_SPHERICAL_MEASURE:
          s = vtkTensorMathematics::SphericalMeasure(w);
          break;
        case VTK_MAX_EIGENVAL_MEASURE:
          s = w[0];
          break;
        case VTK_MIDDLE_EIGENVAL_MEASURE:
          s = w[1];
          break;
        case VTK_MIN_EIGENVAL_MEASURE:
          s = w[2]; 
          break;
        case VTK_EIGENVAL_DIFFERENCE_MAX_MID_MEASURE:
          s = w[0] - w[2]; 
          break;
        case VTK_DIRECTION_MEASURE:
          // vary color only with x and y, since unit vector
          // these two determine z component.
          // use max evector for direction
          //s = fabs(xv[0])/(fabs(yv[0]) + eps);
          double v_maj[3];
          v_maj[0]=v[0][0];
          v_maj[1]=v[1][0];
          v_maj[2]=v[2][0];
          if (this->TensorRotationMatrix)
            {
              rotate->SetMatrix(this->TensorRotationMatrix);
              rotate->TransformPoint(v_maj,v_maj);
            }

          vtkInteractiveTensorGlyph::RGBToIndex(fabs(v_maj[0]),fabs(v_maj[1]),fabs(v_maj[2]),s);

          break;
        case VTK_RELATIVE_ANISOTROPY_MEASURE:
          s = vtkTensorMathematics::RelativeAnisotropy(w);
          break;
        case VTK_FRACTIONAL_ANISOTROPY_MEASURE:
          s = vtkTensorMathematics::FractionalAnisotropy(w);
          break;
        default:
          s = 0;
          break;
          } 
        }          

      for (i=0; i < numSourcePts; i++) 
        {
        //newScalars->InsertScalar(ptIncr+i, s);
        newScalars->InsertNextTuple1(s);
        }        

      // compute scale factors
      w[0] *= this->ScaleFactor;
      w[1] *= this->ScaleFactor;
      w[2] *= this->ScaleFactor;

      if ( this->ClampScaling )
        {
        for (maxScale=0.0, i=0; i<3; i++)
          {
          if ( maxScale < fabs(w[i]) )
            {
            maxScale = fabs(w[i]);
            }
          }
        if ( maxScale > this->MaxScaleFactor )
          {
          maxScale = this->MaxScaleFactor / maxScale;
          for (i=0; i<3; i++)
            {
            w[i] *= maxScale; //preserve overall shape of glyph
            }
          }
        }

      // If we have a user-specified matrix rotating the tensor
      if (this->TensorRotationMatrix)
        {
        trans->Concatenate(this->TensorRotationMatrix);
        }


      // normalized eigenvectors rotate object
      // odonnell: test -y for display 
      int yFlipFlag = 1;
      matrix->Element[0][0] = xv[0];
      matrix->Element[0][1] = yFlipFlag*yv[0];
      matrix->Element[0][2] = zv[0];
      matrix->Element[1][0] = xv[1];
      matrix->Element[1][1] = yFlipFlag*yv[1];
      matrix->Element[1][2] = zv[1];
      matrix->Element[2][0] = xv[2];
      matrix->Element[2][1] = yFlipFlag*yv[2];
      matrix->Element[2][2] = zv[2];
      trans->Concatenate(matrix);

      // make sure scale is okay (non-zero) and scale data
      for (maxScale=0.0, i=0; i<3; i++)
        {
        if ( w[i] > maxScale )
          {
          maxScale = w[i];
          }
        }
      if ( maxScale == 0.0 )
        {
        maxScale = 1.0;
        }
      for (i=0; i<3; i++)
        {
        if ( w[i] == 0.0 )
          {
          w[i] = maxScale * 1.0e-06;
          }
        }
      trans->Scale(w[0], w[1], w[2]);

      // multiply points (and normals if available) by resulting matrix
      // this also appends them to the output "new" data
      //cout<<"transforming glyph points into general set"<<endl;
      trans->TransformPoints(sourcePts,newPts);
      //cout<<"transformation done"<<endl;
      sourceNormals=pd->GetNormals();
      if ( newNormals )
        {
          trans->TransformNormals(sourceNormals,newNormals);
        }

      ptOffset += numSourcePts;

      }  // end if mask is 1 OR trace is ok

    } // end for loop.




  vtkDebugMacro(<<"Generated " << numPts <<" tensor glyphs");
  //
  // Update output and release memory
  //
  delete [] pts;

  output->SetPoints(newPts);
  newPts->Delete();

  if ( newScalars )
    {
      outPD->SetScalars(newScalars);
      newScalars->Delete();
    }

  if ( newNormals )
    {
      outPD->SetNormals(newNormals);
      newNormals->Delete();
    }

  // reclaim extra memory we allocated
  output->Squeeze();

  sq->Delete();

  rotate->Delete();
  userVolumeTransform->Delete();
  trans->Delete();
  matrix->Delete();

  cout << "glyph time: " << clock() - tStart << endl;
}

//----------------------------------------------------------------------------
void vtkSuperquadricTensorGlyph::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  //  os << indent << "ColorGlyphsWithAnisotropy: " << this->ColorGlyphsWithAnisotropy << "\n";
}

//----------------------------------------------------------------------------
// Account for the MTime of objects we use
//
unsigned long int vtkSuperquadricTensorGlyph::GetMTime()
{
  unsigned long mTime = this->vtkObject::GetMTime();
  unsigned long time;

  if ( this->ScalarMask != NULL )
    {
    time = this->ScalarMask->GetMTime();
    mTime = ( time > mTime ? time : mTime );
    }

  if ( this->VolumePositionMatrix != NULL )
    {
    time = this->VolumePositionMatrix->GetMTime();
    mTime = ( time > mTime ? time : mTime );
    }

  if ( this->TensorRotationMatrix != NULL )
    {
    time = this->TensorRotationMatrix->GetMTime();
    mTime = ( time > mTime ? time : mTime );
    }

  return mTime;
}
