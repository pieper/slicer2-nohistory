/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkQuaternionRigidTransformGradientDescentOptimizerModified.cxx,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    $RCSfile: itkQuaternionRigidTransformGradientDescentOptimizerModified.cxx,v $
  Language:  C++
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

  Copyright (c) 2002 Insight Consortium. All rights reserved.
  See ITKCopyright.txt or http://www.itk.org/HTML/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef _itkQuaternionRigidTransformGradientDescentOptimizerModified_txx
#define _itkQuaternionRigidTransformGradientDescentOptimizerModified_txx

#include "itkQuaternionRigidTransformGradientDescentOptimizerModified.h"
#include "vnl/vnl_quaternion.h"
#include "itkEventObject.h"

namespace itk
{

/**
 * Constructor
 */
QuaternionRigidTransformGradientDescentOptimizerModified
::QuaternionRigidTransformGradientDescentOptimizerModified()
{
}


void
QuaternionRigidTransformGradientDescentOptimizerModified
::PrintSelf(std::ostream& os, Indent indent) const
{
  Superclass::PrintSelf(os,indent);
}


/**
 * Advance one Step following the gradient direction
 */
void
QuaternionRigidTransformGradientDescentOptimizerModified
::AdvanceOneStep( void )
{ 

  double direction;
  if( m_Maximize ) 
  {
    direction = 1.0;
  }
  else 
  {
    direction = -1.0;
  }


  ScalesType scales = this->GetScales();

  const unsigned int spaceDimension = 
                        m_CostFunction->GetNumberOfParameters();

  DerivativeType transformedGradient( spaceDimension);
  for ( unsigned int i=0; i< spaceDimension; i++)
    {
    transformedGradient[i] = m_Gradient[i] / scales[i];
    }

  ParametersType currentPosition = this->GetCurrentPosition();

  // compute new quaternion value
  vnl_quaternion<double> newQuaternion;
  for ( unsigned int j=0; j < 4; j++ )
    {
    newQuaternion[j] = currentPosition[j] + direction * m_LearningRate *
      transformedGradient[j];
    }

  newQuaternion.normalize();

  ParametersType newPosition( spaceDimension );
  // update quaternion component of currentPosition
  for ( unsigned int j=0; j < 4; j++ )
    {
    newPosition[j] = newQuaternion[j];
    }
  
  // update the translation component
  for (unsigned int j=4; j< spaceDimension; j++)
  {
    newPosition[j] = currentPosition[j] + 
      direction * m_LearningRate * transformedGradient[j];
  }

  this->SetCurrentPosition( newPosition );

  this->InvokeEvent( IterationEvent() );

}



} // end namespace itk

#endif
