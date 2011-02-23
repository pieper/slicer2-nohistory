#include "vtkSuperquadricSource.h"
#include "vtkSuperquadricSource2.h"
#include "vtkPolyDataMapper.h"
#include "vtkActor.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkCamera.h"

int TestSuperquadricSource2(int, char *[])
{
  //vtkSuperquadricSource *squad = vtkSuperquadricSource::New();
  //squad->SetPhiResolution(20);
  //squad->SetThetaResolution(25);
  //squad->SetPhiRoundness (1.5);
  //squad->SetThickness (0.43);
  //squad->SetThetaRoundness (0.7);
  //squad->ToroidalOn();

  vtkSuperquadricSource2 *squad2 = vtkSuperquadricSource2::New();
  squad2->SetPhiResolution(20);
  squad2->SetThetaResolution (25);
  squad2->SetPhiRoundness (1.5);
  squad2->SetThickness (0.43);
  squad2->SetThetaRoundness (0.7);
  squad2->ToroidalOn();

  vtkPolyDataMapper *mapper = vtkPolyDataMapper::New ();
  //mapper->SetInput (squad->GetOutput());
  mapper->SetInput (squad2->GetOutput());

  vtkActor *actor = vtkActor::New ();
  actor->SetMapper (mapper);
  
  // Create the rendering related stuff.
  vtkRenderer *ren = vtkRenderer::New ();
  vtkRenderWindow *renWin = vtkRenderWindow::New ();
  renWin->AddRenderer (ren);
  
  vtkRenderWindowInteractor *iren = vtkRenderWindowInteractor::New ();
  iren->SetRenderWindow (renWin);
  
  // specify properties
  ren->AddActor (actor );
  ren->ResetCamera();
  ren->GetActiveCamera()->Zoom (1.5);
  ren->GetActiveCamera()->Elevation (40);
  ren->GetActiveCamera()->Azimuth (-20);
  renWin->Render();

  // render the image
  //iren->Initialize();
  //iren->Start();
  
  squad2->Delete();
  actor->Delete();
  ren->Delete();
  renWin->Delete();
  mapper->Delete();
  iren->Delete();

  return 0;
}

