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
//               File: vtkParzenDensityEstimation.h                           //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes probability density of activation volume input using //
//                Parzen window density estimate obtained by training data    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#ifndef __vtkParzenDensityEstimation_h
#define __vtkParzenDensityEstimation_h

#include "vtkFMRIEngineConfigure.h"
#include "vtkMultipleInputsImageFilter.h"
#include "vtkImageData.h"
#include "vtkSetGet.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkPointData.h"
#include "cmath"

class VTK_FMRIENGINE_EXPORT vtkParzenDensityEstimation : public vtkMultipleInputsImageFilter
{
public:
  static vtkParzenDensityEstimation *New();
  vtkTypeMacro(vtkParzenDensityEstimation, vtkMultipleInputsImageFilter);  

  vtkSetMacro(numSearchSteps, int);
  vtkSetMacro(numCrossValFolds, int);
  vtkSetMacro(numTraining, int); 
  
  void SettrainingUse(vtkFloatArray *trainingUseC) {this->trainingUse = trainingUseC;}
    
private:
  int x;                        // x dimension of volume input 
  int y;                        // y dimension of volume input 
  int z;                        // z dimension of volume input 
  int posMax;                   // position of maximum of average log-likelihood of training and validation
  int nC;                       // size of volume input/number of cross validation folds  
  int numVdData;                // number of entries in test set
  int numTrData;                // number of entries in training set 
  int numSearchSteps;            // number of search steps    
  int numCrossValFolds;            // number of cross validation folds 
  int numTraining;              // size of training sample
  unsigned long int size;       // size of the image inputs
  int dims[3];                  // array of dimensions
  vtkFloatArray *trainingUse;   // training data
  float pi;            // pi
  float *h;                     // Parzen window width
  float *avLoglikeVal;          // average log-likelihood of training and validation
  float max;                    // maximum of training data, maximum of average log-likelihood of training and validation
  float min;                    // minimum of training data, maximum of average log-likelihood of training and validation
  float rangeParzenWindow;      // range of Parzen Window
  float delta;                  // delta
  float sumPX;                  // sum of log of probability densities
  float sumLoglikeVal;          // sum of log of probability densities/number of entries in test set;
  float hBest;                  // parameter of Parzen window density estimator
  float power;                  // help variable for power calculation
  vtkFloatArray *vdData;        // test data array
  vtkFloatArray *trData;        // training data array
  vtkFloatArray *pX;            // array of log of probability densities
protected:
  vtkParzenDensityEstimation();
  ~vtkParzenDensityEstimation();
  void SimpleExecute(vtkImageData *input, vtkImageData *output);
};

#endif
