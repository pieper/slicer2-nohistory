/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIbrowserIO.cxx,v $
  Date:      $Date: 2006/01/06 17:57:49 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkIbrowserIO.h"
#include "vtkByteSwap.h"

int vtkIbrowserIO::ReadShort (FILE* iFile, short& oShort) {

  short s = 0;
  int result ;

  // Read an short. Swap if we need to. Return the value.
  result = fread (&s, sizeof(short), 1, iFile);
  vtkByteSwap::Swap2BE (&s);
  oShort = s;

  return result;
}

int vtkIbrowserIO::ReadInt (FILE* iFile, int& oInt) {

  int i = 0;
  int result ;

  // Read an int. Swap if we need to. Return the value.
  result = fread (&i, sizeof(int), 1, iFile);
  vtkByteSwap::Swap4BE (&i);
  oInt = i;

  return result;
}

int vtkIbrowserIO::ReadInt3 (FILE* iFile, int& oInt) {

  int i = 0;
  int result ;

  // Read three bytes. Swap if we need to. Stuff into a full sized int
  // and return.
  result = fread (&i, 3, 1, iFile);
  vtkByteSwap::Swap4BE (&i);
  oInt = ((i>>8) & 0xffffff);

  return result;
}

int vtkIbrowserIO::ReadInt2 (FILE* iFile, int& oInt) {

  int i = 0;
  int result ;

  // Read two bytes. Swap if we need to. Return the value
  result = fread (&i, 2, 1, iFile);
  vtkByteSwap::Swap4BE (&i);
  oInt = i;
  
  return result;
}

int vtkIbrowserIO::ReadFloat (FILE* iFile, float& oFloat) {

  float f = 0;
  int result ;

  // Read a float. Swap if we need to. Return the value
  result = fread (&f, 4, 1, iFile);
  vtkByteSwap::Swap4BE (&f);
  oFloat = f;
  
  return result;
}



