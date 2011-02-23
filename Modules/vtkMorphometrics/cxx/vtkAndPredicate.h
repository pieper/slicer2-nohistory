/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAndPredicate.h,v $
  Date:      $Date: 2006/01/06 17:57:57 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#ifndef __vtk_and_predicate_h
#define __vtk_and_predicate_h
#include <vtkMorphometricsConfigure.h>
#include "vtkPredicate.h"
#include <vtkSetGet.h>
//---------------------------------------------------------
// Author: Axel Krauth
//
// Convenience Class for structuring multiple predicates.
// Set as left operand the predicate which is either faster 
// or yields more often false.

class VTK_MORPHOMETRICS_EXPORT vtkAndPredicate : public vtkPredicate
{
 public:
  static vtkAndPredicate* New();
  void Delete();
  vtkTypeMacro(vtkAndPredicate,vtkPredicate);
  void PrintSelf();
  
  vtkSetObjectMacro(LeftOperand,vtkPredicate);
  vtkSetObjectMacro(RightOperand,vtkPredicate);

  //override in order to reflect changes in LeftOperand or RightOperand
  unsigned long int GetMTime();

  virtual bool P(vtkFloatingPointType* x);
  virtual void InitP();

 protected:
  vtkAndPredicate();
  ~vtkAndPredicate();

 private:
  vtkAndPredicate(vtkAndPredicate&);
  void operator=(const vtkAndPredicate);
  vtkPredicate* LeftOperand;
  vtkPredicate* RightOperand;
};

#endif
