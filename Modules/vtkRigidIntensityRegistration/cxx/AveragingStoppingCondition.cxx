/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: AveragingStoppingCondition.cxx,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#include "AveragingStoppingCondition.h"
#include "vtkSystemIncludes.h"

#define BIG_NEGATIVE_NUMBER VTK_DOUBLE_MIN

/* ====================================================================== */

AveragingStoppingCondition::AveragingStoppingCondition()
{
  NumberOfIterSinceMax = 0;
  Max_Value   = BIG_NEGATIVE_NUMBER;
  Average_Value = 0.0;
  NumSampleAverage = 10;            // average over 10 samples;
  MaxAllowedItersOfShrinking = 10;  // How many iters until stop?
}

/* ====================================================================== */

double AveragingStoppingCondition::GetAverageValue() const
{
  return (Average_Value/(double)NumSampleAverage);
}

/* ====================================================================== */

void AveragingStoppingCondition::UpdateAverageValue(const double &newvalue,
                                           const double &oldvalue)
{
  Average_Value+= newvalue-oldvalue;
}

/* ====================================================================== */

int AveragingStoppingCondition::CheckStopping(const double &value)
{
  if (value > Max_Value)    // A new maximum?
    {
      Max_Value  = value;
      NumberOfIterSinceMax = 0;
    }
  else
    {
      if (queue.size() >= NumSampleAverage)
        {
          double old_average = this->GetAverageValue();
          if (old_average < value)   // Maybe the average is going up?
            {
              NumberOfIterSinceMax = 0;  
            }
          else   // Neither the average nor the max is going up
            {
              if (NumberOfIterSinceMax >= MaxAllowedItersOfShrinking)
                return 0;
            }
        }
    }

  // Update the average
  if (queue.size() >= NumSampleAverage)
    this->UpdateAverageValue(value,queue.front());
  else
    this->UpdateAverageValue(value,0.0);
  // Update the list
  queue.pop();
  queue.push(value);
  return 1;
}
