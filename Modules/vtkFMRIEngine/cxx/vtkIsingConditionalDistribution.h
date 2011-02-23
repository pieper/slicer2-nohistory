/*=auto=========================================================================

(c) Copyright 2005 Massachusetts Institute of Technology (MIT) All Rights Reserved.

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
/*==============================================================================
(c) Copyright 2004 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
==============================================================================*/
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               File: vtkIsingConditionalDistribution.h                      //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes conditional distribution of activation volume input  //
//                depending on density estimate, given a certain class        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#ifndef __vtkIsingConditionalDistribution_h
#define __vtkIsingConditionalDistribution_h

#include "vtkFMRIEngineConfigure.h"
#include "vtkMultipleInputsImageFilter.h"
#include "vtkParzenDensityEstimation.h"
#include "vtkImageData.h"
#include "vtkSetGet.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkPointData.h"
#include "cmath"
#include "algorithm"
#include "cfloat"
using std::random_shuffle;

class VTK_FMRIENGINE_EXPORT vtkIsingConditionalDistribution : public vtkMultipleInputsImageFilter
{
public:
  static vtkIsingConditionalDistribution *New();
  vtkTypeMacro(vtkIsingConditionalDistribution, vtkMultipleInputsImageFilter);

  vtkSetMacro(x, int);
  vtkSetMacro(y, int);
  vtkSetMacro(z, int);
  vtkSetMacro(nType, int);
  vtkSetMacro(densityEstimate, int);
  vtkSetMacro(numSearchSteps, int);
  vtkSetMacro(numCrossValFolds, int);
  vtkSetMacro(maxTraining, unsigned long int);
  
private:
  int x;                           // x dimension of activation volume 
  int y;                           // y dimension of activation volume 
  int z;                           // z dimension of activation volume 
  int nType;                       // number of classes = number of activation states * number of segmentation labels  
  int densityEstimate;             // indicator of density estimate (0 GAU,1 MG2,2 PAR)
  int numSearchSteps;               // number of search steps    
  int numCrossValFolds;               // number of cross validation folds 
  unsigned long int maxTraining;                 // limit for size of training sample
  unsigned long int entryNumber;   // position in training sample
  int posEntryNumber;              // position in training sample
  int negEntryNumber;              // position in training sample
  float negStd;                    // standard deviation
  float posStd;                    // standard deviation
  float std;                       // standard deviation
  float epsilon;                   // smallest number > 0
  float expectedValue;             // expected value / mean
  float sum;                       // sum needed for calculation of standard deviation
  unsigned long int size;          // size of the image inputs
  int dims[3];                     // array of dimensions
  float *trainingData;             // training data array
  float *posTrainingData;          // pos training data array
  float *negTrainingData;          // neg training data array
  vtkFloatArray *parzenArray;      // array for parzen density estimation
  float pi;                        // pi value
  float var;                       // variance
protected:
  vtkIsingConditionalDistribution();
  ~vtkIsingConditionalDistribution();
  void SimpleExecute(vtkImageData *input, vtkImageData *output);
  void ExecuteInformation(vtkImageData *input, vtkImageData *output);
};

#endif
