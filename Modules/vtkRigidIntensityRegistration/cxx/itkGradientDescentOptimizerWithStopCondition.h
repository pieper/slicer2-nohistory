/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkGradientDescentOptimizerWithStopCondition.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: itkGradientDescentOptimizerWithStopCondition.h,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

  Copyright (c) 2002 Insight Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef __itkGradientDescentOptimizerWithStopCondition_h
#define __itkGradientDescentOptimizerWithStopCondition_h

// This file (and the corresponding cxx file)
// modified from GradientDescentOptimizer by Samson Timoner
// It is modified to include a Stopping Condition.
// The changes made are:
// 1) Search and replace GradientDescentOptimizer -> 
//                               GradientDescentOptimizerWithStopCondition
// 2) ITK_EXPORT -> VTK_RIGIDINTENSITYREGISTRATION_EXPORT
// 3) addition of: #include "vtkRigidIntensityRegistrationConfigure.h"
// 4) cxx file: #include "StoppingCondition.h"

#include "vtkRigidIntensityRegistrationConfigure.h"
#include "itkSingleValuedNonLinearOptimizer.h"

//BTX

namespace itk
{
  
/** \class GradientDescentOptimizerWithStopCondition
 * \brief Implement a gradient descent optimizer
 *
 * GradientDescentOptimizerWithStopCondition implements a simple gradient descent optimizer.
 * At each iteration the current position is updated according to
 *
 * \f[ 
 *        p_{n+1} = p_n 
 *                + \mbox{learningRate} 
                  \, \frac{\partial f(p_n) }{\partial p_n} 
 * \f]
 *
 * The learning rate is a fixed scalar defined via SetLearningRate().
 * The optimizer steps through a user defined number of iterations;
 * no convergence checking is done.
 *
 * Additionally, user can scale each component of the df / dp
 * but setting a scaling vector using method SetScale().
 *
 * \sa RegularStepGradientDescentOptimizerWithStopCondition
 * 
 * \ingroup Numerics Optimizers
 */  
class VTK_RIGIDINTENSITYREGISTRATION_EXPORT GradientDescentOptimizerWithStopCondition : 
        public SingleValuedNonLinearOptimizer
{
public:
  /** Standard class typedefs. */
  typedef GradientDescentOptimizerWithStopCondition     Self;
  typedef SingleValuedNonLinearOptimizer    Superclass;
  typedef SmartPointer<Self>                Pointer;
  typedef SmartPointer<const Self>          ConstPointer;
  
  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro( GradientDescentOptimizerWithStopCondition, SingleValuedNonLinearOptimizer );


  /** Codes of stopping conditions */
  typedef enum {
    MaximumNumberOfIterations,
    MetricError
  } StopConditionType;

  /** Methods to configure the cost function. */
  itkGetMacro( Maximize, bool );
  itkSetMacro( Maximize, bool );
  itkBooleanMacro( Maximize );
  bool GetMinimize( ) const
    { return !m_Maximize; }
  void SetMinimize(bool v)
    { this->SetMaximize(!v); }
  void MinimizeOn()
    { this->MaximizeOff(); }
  void MinimizeOff()
    { this->MaximizeOn(); }
  
  /** Advance one step following the gradient direction. */
  virtual void AdvanceOneStep( void );

  /** Start optimization. */
  void    StartOptimization( void );

  /** Resume previously stopped optimization with current parameters
   * \sa StopOptimization. */
  void    ResumeOptimization( void );

  /** Stop optimization.
   * \sa ResumeOptimization */
  void    StopOptimization( void );

  /** Set the learning rate. */
  itkSetMacro( LearningRate, double );

  /** Get the learning rate. */
  itkGetConstMacro( LearningRate, double);

  /** Set the number of iterations. */
  itkSetMacro( NumberOfIterations, unsigned long );

  /** Get the number of iterations. */
  itkGetConstMacro( NumberOfIterations, unsigned long );

  /** Get the current iteration number. */
  itkGetConstMacro( CurrentIteration, unsigned int );

  /** Get the current value. */
  itkGetConstMacro( Value, double );

  /** Get Stop condition. */
  itkGetConstMacro( StopCondition, StopConditionType );


protected:
  GradientDescentOptimizerWithStopCondition();
  virtual ~GradientDescentOptimizerWithStopCondition() {};
  void PrintSelf(std::ostream& os, Indent indent) const;


  // made protected so subclass can access
  DerivativeType                m_Gradient; 
  bool                          m_Maximize;
  double                        m_LearningRate;

private:
  GradientDescentOptimizerWithStopCondition(const Self&); //purposely not implemented
  void operator=(const Self&); //purposely not implemented
  
  bool                          m_Stop;
  double                        m_Value;
  StopConditionType             m_StopCondition;
  unsigned long                 m_NumberOfIterations;
  unsigned long                 m_CurrentIteration;



};

} // end namespace itk

// ETX

#endif



