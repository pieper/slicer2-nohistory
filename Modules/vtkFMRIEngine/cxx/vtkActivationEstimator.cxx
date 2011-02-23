/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkActivationEstimator.cxx,v $
  Date:      $Date: 2006/01/06 17:57:35 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/

#include "vtkActivationEstimator.h"
#include "vtkObjectFactory.h"


vtkActivationEstimator::vtkActivationEstimator()
{
    this->Detector = NULL; 
}


vtkActivationEstimator::~vtkActivationEstimator()
{

}


void vtkActivationEstimator::SetDetector(vtkActivationDetector *detector)
{
    this->Detector = detector;
}

