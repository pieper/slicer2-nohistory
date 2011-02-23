/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: NewStoppingCondition.cxx,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#include "vtkMatrix4x4.h"
#include "NewStoppingCondition.h"

namespace itk 
{

NewStoppingCondition::NewStoppingCondition() 
{
  last        = vtkMatrix4x4::New();
  current     = vtkMatrix4x4::New();
  change_mat  = vtkMatrix4x4::New();
  m_Transform = TransformType::New();
  last->Identity();
  current->Identity();
  abort           = 0;
  m_UpdateIter    = 100;
  CallbackData    = NULL;
  m_CurrentIter   = 0;
  m_CurrentLevel  = -1;
}

/* ====================================================================== */

void NewStoppingCondition::Reset()
{
  m_CurrentIter = 0;
  m_CurrentLevel++;
}

/* ====================================================================== */

NewStoppingCondition::~NewStoppingCondition() 
{
  last->Delete();
  current->Delete();
};

/* ====================================================================== */


void NewStoppingCondition::Execute(itk::Object * object, 
                   const itk::EventObject & event)
  {
    OptimizerPointer optimizer = 
                      dynamic_cast< OptimizerPointer >( object );

    if( typeid( event ) != typeid( itk::IterationEvent ) )
      {
      return;
      }
    if (optimizer->GetCurrentIteration() == 0)
      {
        this->Reset();
      }

    this->m_CurrentIter = optimizer->GetCurrentIteration();
    if(m_CurrentIter % m_UpdateIter == 0)
      {
      if (CallbackData != NULL)
       {
         this->abort = this->Callback(CallbackData,
                      this->m_CurrentLevel,
                      this->m_CurrentIter);
       }
      }
    if (this->abort)
      {
      optimizer->StopOptimization();
      return;
      }

    // The current matrix becomes the old one
    last->DeepCopy(current);

    // 
    m_Transform->SetParameters(optimizer->GetCurrentPosition());
    const TransformType::MatrixType ResMat   =m_Transform->GetRotationMatrix();
    const TransformType::OffsetType ResOffset=m_Transform->GetOffset();

    // Copy the Rotation Matrix
    for(int i=0;i<3;i++)
      for(int j=0;j<3;j++)
    current->Element[i][j] = ResMat[i][j];

    // Copy the Offset
    for(int s=0;s<3;s++)
      current->Element[s][3] = ResOffset[s];

    // Fill in the rest
    current->Element[3][0] = 0;
    current->Element[3][1] = 0;
    current->Element[3][2] = 0;
    current->Element[3][3] = 1;

    // Find the change between the last two steps
    change_mat->DeepCopy(last);
    change_mat->Invert();
    change_mat->Multiply4x4(change_mat,current,change_mat);

    // Find the metric
    double distancemetric = 0;
    for(int ii=0;ii<4;ii++)
      for(int jj=0;jj<4;jj++)
    {
      if (ii != jj)
        distancemetric += (change_mat->GetElement(ii,jj)*
                   change_mat->GetElement(ii,jj));
      else
        distancemetric += ((change_mat->GetElement(ii,jj)-1)*
                   (change_mat->GetElement(ii,jj)-1));

    }
    distancemetric = sqrt(distancemetric);

    itkDebugMacro( << optimizer->GetCurrentIteration() << " = ");
    itkDebugMacro( << optimizer->GetValue() << " : ");
    itkDebugMacro( << distancemetric << " : ");
    itkDebugMacro( << optimizer->GetCurrentPosition() << std::endl);
}


} /* end namespace itk */
