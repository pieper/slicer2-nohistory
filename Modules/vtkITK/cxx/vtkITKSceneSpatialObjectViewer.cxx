/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKSceneSpatialObjectViewer.cxx,v $
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: vtkITKSceneSpatialObjectViewer.cxx,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:57:47 $
  Version:   $Revision: 1.3 $

  Copyright (c) 2002 Insight Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef _vtkITKSceneSpatialObjectViewer_txx
#define _vtkITKSceneSpatialObjectViewer_txx
#include "vtkITKSceneSpatialObjectViewer.h"

#include "itkSpatialObjectReader.h"
#include <vtkSphereSource.h>
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkAssembly.h>

void vtkITKSceneSpatialObjectViewer::AddActors()
  {
  typedef itk::SpatialObjectReader<3> ReaderType;
  ReaderType::Pointer reader = ReaderType::New();
  reader->SetFileName(m_FileName);

  try
    {
    reader->Update();
    }
 catch( itk::ExceptionObject &e )
    {
    std::cout << "Exeception " << e << std::endl;
    }
 
  typedef itk::GroupSpatialObject<3> GroupType;
  GroupType::Pointer group = reader->GetGroup();

  typedef itk::SceneSpatialObject<3> SceneType;
  SceneType::Pointer m_Scene = SceneType::New();
  m_Scene->AddSpatialObject(group);

  group->ComputeBoundingBox();
  itk::Vector<double,3> offset;
  offset[0] = -2*(group->GetBoundingBox()->GetCenter()[0]);
  offset[1] = -2*(group->GetBoundingBox()->GetCenter()[1]);
  offset[2] = -2*(group->GetBoundingBox()->GetCenter()[2]);

  sov::VTKRenderer3D::Pointer m_SovVTKRenderer = sov::VTKRenderer3D::New();
  m_SovVTKRenderer->SetScene(m_Scene);
  m_SovVTKRenderer->Update();

  typedef itk::SpatialObject<3> SpatialObjectType;
  SpatialObjectType::ChildrenListType* children = group->GetChildren(999999);
  SpatialObjectType::ChildrenListType::iterator it = children->begin();

  while(it != children->end())
    {
    m_SovVTKRenderer->AssociateWithRenderMethod(*it,"DTITubeTensorVTKRenderMethod3D"); // Associate the object with a particular render method    
    it++;
    }

  delete children;

  vtkActorCollection* actors = m_SovVTKRenderer->GetVTKRenderer()->GetActors();
  actors->InitTraversal();

  vtkActor* actor = actors->GetNextActor();
  actor = actors->GetNextActor();
  vtkAssembly* assembly = vtkAssembly::New();
  while(actor)
    {
    assembly->AddPart(actor);
    actor = actors->GetNextActor();
    if(actor)
      {
      actor = actors->GetNextActor();
      }
    }
  
  // Center the object
  offset[0] = -(assembly->GetBounds()[0]+assembly->GetBounds()[1])/2.0;
  offset[1] = -(assembly->GetBounds()[2]+assembly->GetBounds()[3])/2.0;
  offset[2] = -(assembly->GetBounds()[4]+assembly->GetBounds()[5])/2.0;
  assembly->SetPosition(offset[0],offset[1],offset[2]);

  m_Renderer->AddActor(assembly);

 }


#endif
