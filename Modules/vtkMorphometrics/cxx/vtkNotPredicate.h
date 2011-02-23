/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkNotPredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:58 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_not_predicate_h
#define __vtk_not_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Convenience Class for structuring predicates.
class VTK_MORPHOMETRICS_EXPORT vtkNotPredicate : public vtkPredicate
{
 public:
  static vtkNotPredicate* New();
  void Delete();
  vtkTypeMacro(vtkNotPredicate,vtkPredicate);
  void PrintSelf();
  
  vtkSetObjectMacro(Operand,vtkPredicate);

  // overriding in order to reflect updates in Operand
  unsigned long int GetMTime();

  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkNotPredicate();
  ~vtkNotPredicate();

 private:
  vtkNotPredicate(vtkNotPredicate&);
  void operator=(const vtkNotPredicate);
  vtkPredicate* Operand;
};

#endif
