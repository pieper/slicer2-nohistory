/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkCDF.h,v $
  Date:      $Date: 2006/01/06 17:57:36 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/

// .NAME CDF - Cumulative distribution functions.
// .SECTION Description
// Wrapping for part of itk::Statistics::TDistribution functions


#ifndef __vtkCDF_h
#define __vtkCDF_h

#include "vtkObject.h"
#include <vtkFMRIEngineConfigure.h>


class VTK_FMRIENGINE_EXPORT vtkCDF : public vtkObject 
{
public:

    static vtkCDF *New();
    vtkTypeMacro(vtkCDF, vtkObject);

    // p - p value
    // dof - degrees of freedom 
    // The function returns t statistic.
    double p2t(double p, long dof);

    // Description:
    // Converts t statistic to p value
    // t - t statistic 
    // dof - degrees of freedom 
    // The function returns p value.
    double t2p(double t, long dof);
};


#endif

