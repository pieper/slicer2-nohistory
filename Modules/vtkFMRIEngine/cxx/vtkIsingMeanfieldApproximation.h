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
//               File: vtkIsingMeanfieldApproximation.h                       //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes for each voxel the posterior class probability       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#ifndef __vtkIsingMeanfieldApproximation_h
#define __vtkIsingMeanfieldApproximation_h

#include "vtkFMRIEngineConfigure.h"
#include "vtkMultipleInputsImageFilter.h"
#include "vtkImageData.h"
#include "vtkSetGet.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkPointData.h"
#include "cmath"

class VTK_FMRIENGINE_EXPORT vtkIsingMeanfieldApproximation : public vtkMultipleInputsImageFilter
{
public:
  static vtkIsingMeanfieldApproximation *New(); 
  vtkTypeMacro(vtkIsingMeanfieldApproximation, vtkMultipleInputsImageFilter);
  
  vtkSetMacro(x, int);
  vtkSetMacro(y, int);
  vtkSetMacro(z, int);
  vtkSetMacro(nType, int);
  vtkSetMacro(segInput, int);
  vtkSetMacro(iterations, int);
  vtkSetMacro(numActivationStates, int);
  
  void SetsegLabel(vtkIntArray *segLabelTcl) {this->segLabel = segLabelTcl;};
  void SetprobGivenSegM(vtkFloatArray *probGivenSegMTcl) {this->probGivenSegM = probGivenSegMTcl;}; 
  void SettransitionMatrix(vtkIntArray *transitionMatrixTcl) {this->transitionMatrix = transitionMatrixTcl;};
  void SetactivationFrequence(vtkFloatArray *activationFrequenceTcl) {this->activationFrequence = activationFrequenceTcl;};
  
private:
  int x;                                // x dimensions of input volume 
  int y;                                // y dimensions of input volume 
  int z;                                // z dimensions of input volume 
  int nType;                            // number of classes = number of activation states * number of segmentation labels  
  int nonactive;                        // value for label map representation
  int posactive;                        // value for label map representation
  int negactive;                        // value for label map representation
  int segInput;                         // number of anatomical labels
  float max;                            // maximum of posterior probability
  int posMax;                           // class of maximum of posterior probability
  int numActivationStates;              // number of activation states
  vtkFloatArray *activationFrequence;   // class frequence   
  vtkFloatArray *logTransitionMatrix;   // log transition matrix  
  vtkFloatArray *probGivenSegM;         // prob given SegM matrix [segInput][nType]
  vtkIntArray *transitionMatrix;    // transition matrix
  vtkIntArray *segLabel;                // list of segmentation labels
  short int *labelValue;                // contains a value of the anatomical label map
  int sum;                              // help variable for summation
  int index1;                    // index der transition matrix
  int index2;                           // index der transition matrix
  float logHelp;                        // help variable for log calculation
  vtkIntArray *segMArray;               // anatomical label map input
  int iterations;            // iterations of meanfield algorithm 
  float eValue;                         // e value in the meanfield algorithm
  float *helpArray;                     // array to buffer calculations of the meanfield iteration
  float sumHelpArray;                // sum of help array
  int numIterations;                    // number of meanfield algorithm iterations
  int dims[3];                          // array of dimensions
  unsigned long int size;               // size of the image input   
  float help;                           // help variable
protected:
  vtkIsingMeanfieldApproximation();
  ~vtkIsingMeanfieldApproximation();
  void SimpleExecute(vtkImageData *input, vtkImageData *output);
  void ExecuteInformation(vtkImageData *input, vtkImageData *output);
};

#endif
