/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: TestTensorImplicitFunctionToFunctionSet.cxx,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

#include "vtkActor.h"
#include "vtkPointData.h"
#include "vtkProperty.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkStructuredGrid.h"
#include "vtkStructuredGridReader.h"
#include "vtkPolyDataMapper.h"
#include "vtkRungeKutta45.h"
#include "vtkAssignAttribute.h"
#include "vtkPolyData.h"
#include "vtkRibbonFilter.h"
#include "vtkStructuredGridOutlineFilter.h"
#include "vtkStreamTracer.h"
#include "vtkCamera.h"
#include "vtkXMLPolyDataWriter.h"

#include "vtkTensorImplicitFunctionToFunctionSet.h"
#include "vtkTesting.h"
#include "vtkRegressionTestImage.h"

int TestTensorImplicitFunctionToFunctionSet(int argc, char* argv[])
{
  // Standard rendering classes
  vtkRenderer *renderer = vtkRenderer::New();
  vtkRenderWindow *renWin = vtkRenderWindow::New();
  renWin->AddRenderer(renderer);
  vtkRenderWindowInteractor *iren = vtkRenderWindowInteractor::New();
  iren->SetRenderWindow(renWin);

  // Load the mesh geometry and data from a file
  vtkStructuredGridReader *reader = vtkStructuredGridReader::New();
  char *cfname = vtkTestUtilities::ExpandDataFileName(argc, argv, "Data/office.binary.vtk");
  reader->SetFileName( cfname );
  delete[] cfname;

  // Force reading
  //reader->Update();

  vtkStructuredGridOutlineFilter *outline = vtkStructuredGridOutlineFilter::New();
  outline->SetInput(reader->GetOutput());

  vtkPolyDataMapper *mapOutline=vtkPolyDataMapper::New();
  mapOutline->SetInput(outline->GetOutput());
  vtkActor *outlineActor=vtkActor::New();
  outlineActor->SetMapper(mapOutline);
  outlineActor->GetProperty()->SetColor(0,0,0);

  vtkRungeKutta45 *rk=vtkRungeKutta45::New();
  vtkTensorImplicitFunctionToFunctionSet *funcset = vtkTensorImplicitFunctionToFunctionSet::New();
  rk->SetFunctionSet( funcset );

  // Create source for streamtubes
  vtkStreamTracer *streamer=vtkStreamTracer::New();
  streamer->SetInput(reader->GetOutput());
  streamer->SetStartPosition(0.1,2.1,0.5);
  streamer->SetMaximumPropagation(0,500);
  streamer->SetMinimumIntegrationStep(1,0.1);
  streamer->SetMaximumIntegrationStep(1,1.0);
  streamer->SetInitialIntegrationStep(2,0.2);
  streamer->SetIntegrationDirection(0);
  streamer->SetIntegrator(rk);
  streamer->SetRotationScale(0.5);
  streamer->SetMaximumError(1.0E-8);

  vtkAssignAttribute *aa=vtkAssignAttribute::New();
  aa->SetInput(streamer->GetOutput());
  aa->Assign("Normals",vtkDataSetAttributes::NORMALS,
             vtkAssignAttribute::POINT_DATA);

  vtkRibbonFilter *rf1=vtkRibbonFilter::New();
  rf1->SetInput(aa->GetPolyDataOutput());
  rf1->SetWidth(0.1);
  rf1->VaryWidthOff();

  vtkPolyDataMapper *mapStream=vtkPolyDataMapper::New();
  mapStream->SetInput(rf1->GetOutput());
  mapStream->SetScalarRange(reader->GetOutput()->GetScalarRange());
  vtkActor *streamActor=vtkActor::New();
  streamActor->SetMapper(mapStream);

  renderer->AddActor(outlineActor);
  renderer->AddActor(streamActor);

  vtkCamera *cam=renderer->GetActiveCamera();
  cam->SetPosition(-2.35599,-3.35001,4.59236);
  cam->SetFocalPoint(2.255,2.255,1.28413);
  cam->SetViewUp(0.311311,0.279912,0.908149);
  cam->SetClippingRange(1.12294,16.6226);

  // Save the result of the filter in a file
  //vtkXMLPolyDataWriter *writer=vtkXMLPolyDataWriter::New();
  //writer->SetInput(streamer->GetOutput());
  //writer->SetFileName("streamed.vtu");
  //writer->SetDataModeToAscii();
  //writer->Write();
  //writer->Delete();

  // Standard testing code.
  renderer->SetBackground(0.4,0.4,0.5);
  renWin->SetSize(300,200);
  renWin->Render();
  //streamer->GetOutput()->Print(cout);
  int retVal = vtkRegressionTestImage( renWin );
  if ( retVal == vtkRegressionTester::DO_INTERACTOR)
    {
    iren->Start();
    }

  // Cleanup
  renderer->Delete();
  renWin->Delete();
  iren->Delete();
  //ds->Delete();

  outline->Delete();
  mapOutline->Delete();
  outlineActor->Delete();

  rk->Delete();
  streamer->Delete();
  aa->Delete();
  rf1->Delete();
  mapStream->Delete();
  streamActor->Delete();

  return !retVal;
}
