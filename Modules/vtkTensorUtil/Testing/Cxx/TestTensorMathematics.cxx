#include "vtkTensorMathematics.h"
#include "vtkPointLoad.h"
#include "vtkAppendPolyData.h"
#include "vtkPolyDataMapper.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkImageData.h"
#include "vtkImageViewer.h"
#include "vtkImageViewer2.h"
#include "vtkImageShiftScale.h"
#include "vtkPNGReader.h"
#include "vtkPNGWriter.h"
#include "vtkStructuredPointsReader.h"
#include "vtkStructuredPoints.h"
#include "vtkActor2D.h"

int TestTensorMathematics(int, char *[])
{
  vtkPointLoad *ptLoad = vtkPointLoad::New();
  ptLoad->SetLoadValue (100.0);
  ptLoad->SetSampleDimensions (50, 50, 30);
  ptLoad->ComputeEffectiveStressOn();
  ptLoad->SetModelBounds (-20, 20, -20, 20, -10, 10);

  vtkImageData *input = ptLoad->GetOutput();
  int column = 1;
  int row = 1;

  double s[2] = { 0.0187995, 0.00939977 };
  double deltaX = 1.0/6.0;
  double deltaY = 1.0/4.0;


  vtkRenderWindow *imgWin = vtkRenderWindow::New();
  for( int i = VTK_TENS_TRACE; i<= VTK_TENS_MAX_EIGENVALUE_PROJZ; i++)
    {
    vtkTensorMathematics *t = vtkTensorMathematics::New();
    t->SetOperation( i );
    t->SetInput1( input );
    t->SetInput2( input );
    //t->Update();

    vtkImageMapper *mapper = vtkImageMapper::New();
    mapper->SetInput( t->GetOutput() );
    mapper->SetColorWindow( s[0] );
    mapper->SetColorLevel ( (s[1]-s[0])/2 );

    vtkActor2D *actor2d = vtkActor2D::New();
    actor2d->SetMapper( mapper );
    vtkRenderer *imager = vtkRenderer::New();
    imager->AddActor2D( actor2d );
    imgWin->AddRenderer( imager );

    imager->SetViewport( (column - 1) * deltaX, (row - 1) * deltaY,
      column * deltaX, row * deltaY );
    ++column;
    if ( column > 6 )
      {
      column = 1;
      ++row; 
      }

    t->Delete();
    actor2d->Delete();
    imager->Delete();
    mapper->Delete();
    }

  vtkRenderWindowInteractor *iren = vtkRenderWindowInteractor::New();
  iren->SetRenderWindow(imgWin);
  imgWin->SetSize (600,300);

  iren->Initialize();
  iren->Start();

  iren->Delete();
  imgWin->Delete();
  ptLoad->Delete();

  return 0;
}

