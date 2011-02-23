/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkGradientDescentOptimizerWithStopCondition.cxx,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: itkGradientDescentOptimizerWithStopCondition.cxx,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.5 $
  Copyright (c) 2002 Insight Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef _itkGradientDescentOptimizerWithStopCondition_txx
#define _itkGradientDescentOptimizerWithStopCondition_txx

#include "itkGradientDescentOptimizerWithStopCondition.h"
#include "itkCommand.h"
#include "itkEventObject.h"
#include "itkExceptionObject.h"

#ifdef _WIN32
#include <iostream>
#else
#include <iostream.h>
#endif

namespace itk
{

/**
 * Constructor
 */
GradientDescentOptimizerWithStopCondition
::GradientDescentOptimizerWithStopCondition()
{
   itkDebugMacro("Constructor");

   m_LearningRate = 1.0;
   m_NumberOfIterations = 100;
   m_CurrentIteration = 0;
   m_Maximize = false;
}



void
GradientDescentOptimizerWithStopCondition
::PrintSelf(std::ostream& os, Indent indent) const
{
  Superclass::PrintSelf(os,indent);

  os << indent << "LearningRate: "
     << m_LearningRate << std::endl;
  os << indent << "NunberOfIterations: "
     << m_NumberOfIterations << std::endl;
  os << indent << "Maximize: "
     << m_Maximize << std::endl;
  os << indent << "CurrentIteration: "
     << m_CurrentIteration;
  os << indent << "Value: "
     << m_Value;
  if (m_CostFunction)
    {
    os << indent << "CostFunction: "
       << m_CostFunction;
    }
  os << indent << "StopCondition: "
     << m_StopCondition;
  os << std::endl;

}


/**
 * Start the optimization
 */
void
GradientDescentOptimizerWithStopCondition
::StartOptimization( void )
{

  itkDebugMacro("StartOptimization");
   
  m_CurrentIteration   = 0;

  this->SetCurrentPosition( this->GetInitialPosition() );
  this->ResumeOptimization();

}



/**
 * Resume the optimization
 */
void
GradientDescentOptimizerWithStopCondition
::ResumeOptimization( void )
{
  
  itkDebugMacro("ResumeOptimization");

  m_Stop = false;

  InvokeEvent( StartEvent() );
  while( !m_Stop ) 
  {

    try
      {
      m_CostFunction->GetValueAndDerivative( 
        this->GetCurrentPosition(), m_Value, m_Gradient );
      }
    catch( ExceptionObject& err )
      {
       // An exception has occurred. 
       // Terminate immediately.
       m_StopCondition = MetricError;
       StopOptimization();

       // Pass exception to caller
       throw err;
      }

    itkDebugMacro( << "iter " << m_CurrentIteration 
              << " metric value: " << m_Value 
              << " grad " << m_Gradient << std::endl);

    if( m_Stop )
    {
      break;
    }
  
    AdvanceOneStep();

    m_CurrentIteration++;

    if( m_CurrentIteration >= m_NumberOfIterations )
    {
       m_StopCondition = MaximumNumberOfIterations;
       StopOptimization();
       break;
    }
    
  }
    

}


/**
 * Stop optimization
 */
void
GradientDescentOptimizerWithStopCondition
::StopOptimization( void )
{

  itkDebugMacro("StopOptimization");

  m_Stop = true;
  InvokeEvent( EndEvent() );
}





/**
 * Advance one Step following the gradient direction
 */
void
GradientDescentOptimizerWithStopCondition
::AdvanceOneStep( void )
{ 

  itkDebugMacro("AdvanceOneStep");

  double direction;
  if( this->m_Maximize ) 
  {
    direction = 1.0;
  }
  else 
  {
    direction = -1.0;
  }

  const unsigned int spaceDimension = 
                        m_CostFunction->GetNumberOfParameters();

  const ParametersType & currentPosition = this->GetCurrentPosition();

  ScalesType scales = this->GetScales();

  DerivativeType transformedGradient( spaceDimension ); 

  for(unsigned int j = 0; j < spaceDimension; j++)
    {
    transformedGradient[j] = m_Gradient[j] / scales[j];
    }

  ParametersType newPosition( spaceDimension );
  for(unsigned int j = 0; j < spaceDimension; j++)
    {
    newPosition[j] = currentPosition[j] + 
      direction * m_LearningRate * transformedGradient[j];
    }

  this->SetCurrentPosition( newPosition );

  this->InvokeEvent( IterationEvent() );

}



} // end namespace itk

#endif
