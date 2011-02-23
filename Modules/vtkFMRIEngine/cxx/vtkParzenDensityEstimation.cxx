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
//               File: vtkParzenDensityEstimation.cxx                         //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes probability density of activation volume input using //
//                Parzen window density estimate obtained by training data    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#include "vtkObjectFactory.h"
#include "vtkParzenDensityEstimation.h"
#include "vtkCommand.h"

vtkStandardNewMacro(vtkParzenDensityEstimation);

vtkParzenDensityEstimation::vtkParzenDensityEstimation()
{
  this->pi = (float) 3.14159265358979323846; 
}

vtkParzenDensityEstimation::~vtkParzenDensityEstimation()
{
}

void vtkParzenDensityEstimation::SimpleExecute(vtkImageData *input, vtkImageData *output)
{ 
  this->GetInput(0)->GetDimensions(dims);
  x = dims[0];                 
  y = dims[1];
  z = dims[2];
  size = x*y*z;
  
  vtkFloatArray *inputArray = (vtkFloatArray *)this->GetInput(0)->GetPointData()->GetScalars();
  vtkFloatArray *outputArray = vtkFloatArray::New();
  
  // Parzen window width
  h = new float[numSearchSteps];                             
  // average log-likelihood of training and validation
  avLoglikeVal = new float[numSearchSteps];                                          

  output->SetDimensions(dims);
  output->SetScalarType(VTK_FLOAT);
  output->SetSpacing(1.0,1.0,1.0);
  output->SetOrigin(0.0,0.0,0.0);
  output->AllocateScalars();    

  // calculation of range of Parzen window
  for (int i=0; i<numTraining; i++){
    if (i == 0){
      max = trainingUse->GetValue(0);
      min = trainingUse->GetValue(0); 
    }                            
    else{
      if ((trainingUse->GetValue(i)) > max)
        max = trainingUse->GetValue(i);
      if ((trainingUse->GetValue(i)) < min)
        min = trainingUse->GetValue(i);
    }
  }
  rangeParzenWindow = (max-min);
  nC = numTraining/numCrossValFolds;
  delta = (rangeParzenWindow/(float)20)/(numSearchSteps-1.0);

  // creation of training set and test set
  for (int i=0; i<numSearchSteps; i++){
    h[i] = (rangeParzenWindow/20)+(delta*i); 
    sumLoglikeVal = 0.0;
    for (int k=0; k<numCrossValFolds; k++){
      // test set
      vdData = vtkFloatArray::New();
      // training set              
      trData = vtkFloatArray::New();             
      if (k == numCrossValFolds-1){
        k = -1;
      }
      switch (k) {
        case 0:  
          numVdData = nC;
          numTrData = numTraining-nC;
          for (int j=0; j<numVdData; j++) 
            vdData->InsertNextValue(trainingUse->GetValue(j));  
          for (int j=0; j<numTrData; j++) 
            trData->InsertNextValue(trainingUse->GetValue(nC+j));        
          break;
        case -1:
          numVdData = (numTraining-((numCrossValFolds-1)*nC));
          numTrData = ((numCrossValFolds-1)*nC);
          for (int j=0; j<numVdData; j++)  
            vdData->InsertNextValue(trainingUse->GetValue((numCrossValFolds-1)*nC+j));
          for (int j=0; j<numTrData; j++)
            trData->InsertNextValue(trainingUse->GetValue(j)); 
          k = numCrossValFolds;  
          break;
        default:
          numVdData = k*nC-((k-1)*nC);
          numTrData = ((k-1)*nC)+numTraining-(k*nC);
          for (int j=0; j<numVdData; j++){
            vdData->InsertNextValue(trainingUse->GetValue((k-1)*nC+j));  
          } 
          for (int j=0; j<(k-1)*nC; j++){
            trData->InsertNextValue(trainingUse->GetValue(j));   
          }  
          for (int j=0; j<numTraining-(k*nC); j++){
            trData->InsertNextValue(trainingUse->GetValue((k*nC)+j)); 
          } 
          break;
      }    
         
      pX = vtkFloatArray::New();                  
      for (int n=0; n<numVdData; n++){
        pX->InsertNextValue(0.0);
      }
  
      // calculation of average log-likelihood of training and test 
      //      register int j, n;
      for (int j=0; j<numTrData; j++){  
        for (int n=0; n<numVdData; n++){ 
          power = pow((float)((trData->GetValue(j))-(vdData->GetValue(n))),2);      
          pX->SetValue(n, (pX->GetValue(n)) + 1/(numTrData*pow(2.0*pi,0.5)*h[i])*exp(-0.5*power/pow(h[i],2)));          
        }  
      }        
      sumPX = 0.0;
      for (int n=0; n<numVdData; n++)
        sumPX += log(pX->GetValue(n));     
      sumLoglikeVal += (sumPX/numVdData);
      vdData->Delete();
      trData->Delete();
      pX->Delete();
    }
    avLoglikeVal[i] = (sumLoglikeVal/numCrossValFolds);
    UpdateProgress((i+1) * (1.0/numSearchSteps));
  }
 
  // calculation of the position of maximum of average log-likelihood of training and test
  for (int i=0; i<numSearchSteps; i++){
    if (i == 0){
      max = avLoglikeVal[0];
      posMax = 0;
    }
    else {
      if (avLoglikeVal[i] > max){
        max = avLoglikeVal[i];
        posMax = i;
      }
    }
  }
  delete [] avLoglikeVal;
  hBest = h[posMax];
  delete [] h;
  
  // calculation of size of training set and test set
  numVdData = size;
  numTrData = numTraining; 
  
  // initialization of probability density
  for (unsigned long int n=0; n<size; n++)
    outputArray->InsertNextValue(0.0);
     
  // calculation of probability density     
  for (unsigned long int j=0; j<(unsigned long int)numTrData; j++){
    for (unsigned long int n=0; n<size; n++){    
      power = pow((float)((trainingUse->GetValue(j))-(inputArray->GetValue(n))),2);
      outputArray->SetValue(n, (outputArray->GetValue(n)) + 1/(numTrData*pow(2.0*pi,0.5)*hBest)*exp(-0.5*power/pow((float)hBest,2)));           
    }
    UpdateProgress((j+1) * (1.0/numTrData));
  } 
  
  output->GetPointData()->SetScalars(outputArray);
  outputArray->Delete();     
}
