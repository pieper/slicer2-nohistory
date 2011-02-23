/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: AveragingStoppingCondition.h,v $
  Date:      $Date: 2006/01/06 17:58:02 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

#include <queue>
// .NAME StoppingCondition - Decides when to stop MI iteration
// .SECTION Description
//
// The MIRegistration is a sampled version, and therefore a noisy
// measure of registration. StoppingCondition examines the last
// few agreement values, looks at the average, and tries to decide
// if the average is going up or not. If the average does not go
// up for enough iterations, then it is time to stop the iteration.
//
// .SECTION Thanks
// Thanks to Samson Timoner who created this class.

class AveragingStoppingCondition {
 public:
  // Description:
  // Constructor/Destructor
  AveragingStoppingCondition();
  ~AveragingStoppingCondition();
  
  // Description:
  // returns 1 if decides to stop iteration, else 0
  // continue if a new max value
  // continue if value is greater than average of 
  // last NumSampleAverage elements 
  // Stop if no new max in last NumSampleAverage elements
  int CheckStopping(const double &value);

 private:

  // Description:
  // Update Average Value by removing effect of oldvalue
  // and getting the newvalue
  void UpdateAverageValue(const double &newvalue,
                          const double &oldvalue);


  // Description:
  // Get the average value of the past 10 elements
  double GetAverageValue() const;

  typedef std::queue<double> QueueType;
  QueueType queue;
  int NumberOfIterSinceMax;
  double Max_Value;
  double Average_Value;
  unsigned int NumSampleAverage; // The number of samples over which to average
  int MaxAllowedItersOfShrinking; // The number of iters allowed with no max
};

