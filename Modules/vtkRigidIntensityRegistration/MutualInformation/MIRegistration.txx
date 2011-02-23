/*=auto=========================================================================
(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=========================================================================auto=*/
#ifndef __MIRegistration_txx
#define __MIRegistration_txx

#include "MIRegistration.h"

#include "itkCommand.h"

#include "vtkMatrix4x4.h"
#include "NewStoppingCondition.h"

namespace itk
{

template <typename TFixedImage, typename TMovingImage>
MIRegistration<TFixedImage,TMovingImage>::MIRegistration()
{
  // Default parameters
  m_MovingImageStandardDeviation = 0.4;
  m_FixedImageStandardDeviation = 0.4;
  m_NumberOfSpatialSamples = 50;

}

//----------------------------------------------------------------------

// Clean Up: Remove the observer
template <typename TFixedImage, typename TMovingImage>
MIRegistration<TFixedImage,TMovingImage>::~MIRegistration()
{
}


//----------------------------------------------------------------------------

template < typename TFixedImage, typename TMovingImage  >
void MIRegistration<TFixedImage,TMovingImage>
::PrintSelf(std::ostream& os, Indent indent) const
{
  Superclass::PrintSelf(os, indent);

  os << indent << "MovingImageStandardDeviation: " 
        << m_MovingImageStandardDeviation   << endl;
  os << indent << "FixedImageStandardDeviation: " 
        <<   m_FixedImageStandardDeviation  << endl; 
  os << indent << "NumberOfSpatialSamples: " 
        <<   m_NumberOfSpatialSamples       << endl;
}

//----------------------------------------------------------------------

// Set the Metric Paramateres
template <typename TFixedImage, typename TMovingImage>
void MIRegistration<TFixedImage,TMovingImage>::SetMetricParam()
{
  //
  // Setup the metric
  //
  this->m_Metric->SetMovingImageStandardDeviation(m_MovingImageStandardDeviation);
  this->m_Metric->SetFixedImageStandardDeviation(m_FixedImageStandardDeviation);
  this->m_Metric->SetNumberOfSpatialSamples(m_NumberOfSpatialSamples);
  this->m_Optimizer->MaximizeOn();
}


} // namespace itk


#endif /* __MIRegistration_txx */

