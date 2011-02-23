/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkNeuroendoscopy.cxx,v $
  Date:      $Date: 2007/06/21 15:12:32 $
  Version:   $Revision: 1.1 $

=========================================================================auto=*/
#ifndef _vtkNeuroendoscopy_cxx
#define _vtkNeuroendoscopy_cxx

#include "vtkObjectFactory.h"
#include "vtkNeuroendoscopy.h"
vtkStandardNewMacro(vtkNeuroendoscopy);



//char * vtkEndoscopyNEWVersion::GetEndoscopyNEWVersion()
//{
 //   return "TEST";
//}
double vtkNeuroendoscopy::p2t(double p, long dof)
{
    // p value passed in is double sided probability
    return (2 / 2);
}


double vtkNeuroendoscopy::t2p(double t, long dof)
{
    double p = 2;

    // double sided tail probability for t-distribution
    p *= 2;

    return p;
}

//void vtkNeuroendoscopy::connectToOpentracker() {

//}
//this function calclulates coordinates of the
//double vtkNeuroendoscopy::calcProjectorFocusPoint(double x, double y, double z) {

//}
#endif
