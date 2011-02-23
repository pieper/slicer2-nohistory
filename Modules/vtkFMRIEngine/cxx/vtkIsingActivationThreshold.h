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
//               File: vtkIsingActivationThreshold.h                          //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes dimensions of activation volume input                //
//              creates segmentation label index depending on segmentation    //
//                volume input                                                //
//              computes number of activation states depending on             //
//                activation volume input                                     //
//              computes number of classes (number of segmentation label x    //
//                activation states)                                          //
//              computes activation labels depending on activation volume     //
//                input and threshold                                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#ifndef __vtkIsingActivationThreshold_h
#define __vtkIsingActivationThreshold_h

#include "vtkFMRIEngineConfigure.h"
#include "vtkMultipleInputsImageFilter.h"
#include "vtkImageData.h"
#include "vtkSetGet.h"
#include "vtkFloatArray.h"
#include "vtkIntArray.h"
#include "vtkPointData.h"

class VTK_FMRIENGINE_EXPORT vtkIsingActivationThreshold : public vtkMultipleInputsImageFilter
{
public:
  static vtkIsingActivationThreshold *New();
  vtkTypeMacro(vtkIsingActivationThreshold, vtkMultipleInputsImageFilter);
  
  vtkSetMacro(threshold, float);
  vtkSetMacro(thresholdID, int);
  
  vtkGetMacro(x, int);
  vtkGetMacro(y, int);
  vtkGetMacro(z, int);
  vtkGetMacro(numActivationStates, int);
  vtkGetMacro(nType, int);
  vtkGetMacro(segInput, int);
  vtkIntArray *GetsegLabel() {return this->segLabel;};
  
private:
  float threshold;           // threshold for the activation volume
  float threshold2;          // threshold for the activation volume
  int segInput;              // size of segLabel if segM input, 1 otherwise
  int x;                     // x dimension of activation volume 
  int y;                     // y dimension of activation volume 
  int z;                     // z dimension of activation volume 
  int x2;                    // x dimension of segmentation volume
  int y2;                    // y dimension of segmentation volume
  int z2;                    // z dimension of segmentation volume
  int nonactive;             // values for activation label map
  int posactive;             // values for activation label map
  int negactive;             // values for activation label map
  int position;              // used for sorting 
  int thresholdID;           // for 2 different thresholding options
  short int *labelValue;     // contains a value of the anatomical label map
  vtkIntArray *segLabel;     // list of segmentation labels
  int numActivationStates;   // number of activation states
  int nType;                 // number of classes = number of activation states * number of segmentation labels                
  unsigned long int size;    // size of the image inputs
  bool insert;               // help variable for inserting in segLabel
  int dims[3];               // array of dimensions
  int enumerator;            // help variable for inserting in segLabel   
protected:
  vtkIsingActivationThreshold();
  ~vtkIsingActivationThreshold();
  void SimpleExecute(vtkImageData *input, vtkImageData *output);
  void ExecuteInformation(vtkImageData *input, vtkImageData *output);
};

#endif
