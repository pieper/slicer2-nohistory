/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIbrowserIO.h,v $
  Date:      $Date: 2006/01/06 17:57:50 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkIbrowserIO - Some IO functions 
// .SECTION Description
// Some simple functions for like reading three
// byte ints, common in FreeSurfer file types.

#ifndef __vtkIbrowserIO_h
#define __vtkIbrowserIO_h

#include <stdio.h>

class  vtkIbrowserIO {
 public:

  static vtkIbrowserIO *New () { return NULL; }

  static int ReadShort (FILE* iFile, short& oShort);
  static int ReadInt (FILE* iFile, int& oInt);
  static int ReadInt3 (FILE* iFile, int& oInt);
  static int ReadInt2 (FILE* iFile, int& oInt);
  static int ReadFloat (FILE* iFile, float& oFloat);

 protected:
  vtkIbrowserIO ( ) { }
  ~vtkIbrowserIO ( ) { }

};

#endif
