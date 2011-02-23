#include "vtkCone.h"
#include "vtkSphere.h"
#include "vtkMarchingContourFilter.h"
#include "vtkImageData.h"
#include "vtkQuadric.h"
#include "vtkSampleFunction.h"
#include "vtkBSplineInterpolateImageFunction.h"
#include "vtkExtractPolyDataGeometry.h"
#include "vtkPolyDataMapper.h"
#include "vtkActor.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"

int TestBSplineInterpolateImageFunction(int argc, char *argv[])
{
  vtkSphere *sphere = vtkSphere::New();

  vtkSampleFunction *sampleSphere = vtkSampleFunction::New();
  sampleSphere->SetSampleDimensions(20,20,20);
  sampleSphere->SetImplicitFunction (sphere);
  sampleSphere->ComputeNormalsOff();
  sampleSphere->Update(); // need update to please vtkBSplineInterpolateImageFunction
  // ImageData of a sphere (20,20,20)

#if 0
  vtkSphere *func = vtkSphere::New(); // DEBUG
#else
  vtkBSplineInterpolateImageFunction *func = vtkBSplineInterpolateImageFunction::New();
  func->SetInput( sampleSphere->GetOutput() );
#endif

  // iso-surface to create geometry
  vtkSampleFunction *sample = vtkSampleFunction::New(); 
  sample->SetSampleDimensions(20,20,20);
  sample->SetImplicitFunction (func);
  sample->ComputeNormalsOff();

  vtkMarchingContourFilter *contour = vtkMarchingContourFilter::New();
  contour->SetInput(sample->GetOutput());
  contour->SetValue (0, 0.0);

  vtkPolyDataMapper *sphereMapper = vtkPolyDataMapper::New();
  sphereMapper->SetInput(contour->GetOutput());
  sphereMapper->GlobalImmediateModeRenderingOn();

  vtkActor *sphereActor = vtkActor::New();
  sphereActor->SetMapper (sphereMapper);

  vtkRenderer *ren1 = vtkRenderer::New();
  vtkRenderWindow *renWin = vtkRenderWindow::New();
  renWin->AddRenderer (ren1);
  vtkRenderWindowInteractor *iren = vtkRenderWindowInteractor::New();
  iren->SetRenderWindow (renWin);

  ren1->AddActor (sphereActor);

  renWin->Render();
  iren->Initialize();
  //iren->Start();

  return 0;
}
