/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: NewStoppingCondition.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME NewStoppingCondition - StoppingCondition for MI Registration
// .SECTION Description
// Stopping condition for MutualInformationRegistration algorithm

#include "RigidRegistrationBase.h"

#ifndef __NewStoppingCondition_h
#define __NewStoppingCondition_h

#include "vtkRigidIntensityRegistrationConfigure.h"
#include "itkMutualInformationImageToImageMetric.h"

namespace itk
{

class VTK_RIGIDINTENSITYREGISTRATION_EXPORT NewStoppingCondition : public itk::Command 
{
public:
  /** Standard class typedefs. */
  typedef NewStoppingCondition      Self;
  typedef Command                   Superclass;
  typedef SmartPointer<Self>        Pointer;
  typedef SmartPointer<const Self>  ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro( Self );

  /** Run-time type information (and related methods). */
  itkTypeMacro(NewStoppingCondition, Object);

public:
  //
  // The type definitions
  //

   typedef RigidRegistrationBase< Image<float,3>,Image<float,3>, MutualInformationImageToImageMetric<Image<float,3>,Image<float,3> > > RegistratorType;

  typedef RegistratorType::TransformType               TransformType;
  typedef RegistratorType::OptimizerType  OptimizerType;
  typedef OptimizerType                          *OptimizerPointer;

  typedef RegistratorType::AffineTransformType   AffineTransformType;
  typedef AffineTransformType::Pointer AffineTransformPointer;

  /** Set the thing to abort **/
  void AbortProcess() { abort = 1;}

  /** Call an Update Function Every UpdateIter, default 100 */
  itkSetMacro(UpdateIter, int);
  itkGetMacro(UpdateIter, int);

 /** Update Function(object,num_level,num_iter) and object to be called */
 /** function returns 1 if process should abort                         */
  void SetCallbackFunction(void* object,
               int (*f)(void *,int,int))
  {
    CallbackData = object;
    Callback = f;
  }

  /** A new iteration is starting, so reset all convergence settings */
  void Reset();

  /** The iteration event has occured */
  void Execute(itk::Object * object, 
               const itk::EventObject & event);

  /** a const execute command, un-necessary */
  void Execute(const itk::Object *caller, const itk::EventObject & event)
  { Execute( (const itk::Object *)caller, event);  }
protected:
  vtkMatrix4x4 *last,*current,*change_mat;
  TransformType::Pointer             m_Transform;
  int abort;
  int m_UpdateIter;
  int (*Callback)(void *,int,int);
  void *CallbackData;
  int m_CurrentIter;
  int m_CurrentLevel;

protected:
  NewStoppingCondition();
  ~NewStoppingCondition();
};

} /* end namespace itk */
#endif /* __NewStoppingCondition__h */
