/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIntervalConfig.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/

#ifndef __vtkIntervalConfig_h
#define __vtkIntervalConfig_h
// Types of vtkIntervals
#define IMAGEINTERVAL         0
#define DATAINTERVAL          1
#define EVENTINTERVAL         2
#define GEOMINTERVAL          3
#define NOTEINTERVAL           4

// Kinds of interpolation
#define LINEAR                      0
#define BSPLINE                    1

// Kinds of deriving you can do
#define COPY                         0

enum intervalType { IMAGE, DATA, EVENT, GEOMETRY, NOTE };
enum mybool { False, True };
#endif
