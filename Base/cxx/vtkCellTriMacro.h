/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkCellTriMacro.h,v $
  Date:      $Date: 2006/01/06 17:56:37 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
//
//BTX - begin tcl exclude
#define CELLTRIANGLES(CELLPTIDS, TYPE, IDX, PTID0, PTID1, PTID2) \
    { switch( TYPE ) \
      { \
      case VTK_TRIANGLE: \
      case VTK_POLYGON: \
      case VTK_QUAD: \
        PTID0 = CELLPTIDS[0]; \
        PTID1 = CELLPTIDS[(IDX)+1]; \
        PTID2 = CELLPTIDS[(IDX)+2]; \
        break; \
      case VTK_TRIANGLE_STRIP: \
        PTID0 = CELLPTIDS[IDX]; \
        PTID1 = CELLPTIDS[(IDX)+1+((IDX)&1)]; \
        PTID2 = CELLPTIDS[(IDX)+2-((IDX)&1)]; \
        break; \
      default: \
        PTID0 = PTID1 = PTID2 = -1; \
      } }
//ETX - end tcl exclude
//
