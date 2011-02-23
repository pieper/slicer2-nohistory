/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkCDF.cxx,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/

#include "vtkObjectFactory.h"
#include "vtkCDF.h"
#include "itkTDistribution.h"


vtkStandardNewMacro(vtkCDF);


double vtkCDF::p2t(double p, long dof)
{
    // p value passed in is double sided probability
    return fabs(itk::Statistics::TDistribution::InverseCDF((p / 2), dof));
}


double vtkCDF::t2p(double t, long dof)
{
    double p = itk::Statistics::TDistribution::CDF(t, dof);

    // double sided tail probability for t-distribution
    p *= 2;

    return p; 
}

