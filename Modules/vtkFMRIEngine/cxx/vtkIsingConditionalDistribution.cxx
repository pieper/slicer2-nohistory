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
//               File: vtkIsingConditionalDistribution.cxx                    //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes conditional distribution of activation volume input  //
//                depending on density estimate, given a certain class        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#include "vtkObjectFactory.h"
#include "vtkIsingConditionalDistribution.h"
#include "vtkCommand.h"

vtkStandardNewMacro(vtkIsingConditionalDistribution);

vtkIsingConditionalDistribution::vtkIsingConditionalDistribution()
{
  this->epsilon = (float) 0.1e-20;
  this->pi = (float) 3.14159265358979323846; 
}

vtkIsingConditionalDistribution::~vtkIsingConditionalDistribution()
{
}

void vtkIsingConditionalDistribution::SimpleExecute(vtkImageData *input, vtkImageData *output)
{
  dims[0] = x;
  dims[1] = y;
  dims[2] = z*nType;
  size = x*y*z;

  if (this->maxTraining > size)
    this->maxTraining = size;

  vtkIntArray *classArray = (vtkIntArray *)this->GetInput(0)->GetPointData()->GetScalars();
  vtkFloatArray *activation = (vtkFloatArray *)this->GetInput(1)->GetPointData()->GetScalars();
  vtkFloatArray *outputArray = vtkFloatArray::New();
  
  output->SetDimensions(dims);
  output->SetWholeExtent(0, x, 0, y, 0, z*nType);
  output->SetExtent(0, x, 0, y, 0, z*nType);
  output->SetScalarType(VTK_FLOAT);
  output->SetSpacing(1.0,1.0,1.0);
  output->SetOrigin(0.0,0.0,0.0);
  output->AllocateScalars();    

  // Parzen density estimation
  if (densityEstimate == 1) {    
    float *trainingDataPar;
    trainingDataPar = new float[size+1];
    
    for (int n=0; n<nType; n++){
      vtkFloatArray *trainingUseC = vtkFloatArray::New();  
      entryNumber = 0; 
      for (unsigned long int i=0; i<size; i++)
        if (classArray->GetValue(i) == n){
          trainingDataPar[entryNumber] = activation->GetValue(i);
          entryNumber++;
        }
      if (entryNumber <= this->maxTraining){
        for (unsigned long int i=0; i<entryNumber; i++)
          trainingUseC->InsertNextValue(trainingDataPar[i]);  
      }      
      else{
        random_shuffle(trainingDataPar, trainingDataPar+this->maxTraining);
        for (unsigned long int i=0; i<this->maxTraining; i++)
          trainingUseC->InsertNextValue(trainingDataPar[i]);
        entryNumber = this->maxTraining;
      }
      delete [] trainingDataPar;
      if (entryNumber != 0) {
        vtkParzenDensityEstimation *parzenDensity = vtkParzenDensityEstimation::New();
        parzenDensity->SetInput(this->GetInput(1));
        parzenDensity->SetnumSearchSteps(numSearchSteps);
        parzenDensity->SetnumCrossValFolds(numCrossValFolds);
        parzenDensity->SetnumTraining(entryNumber);
        parzenDensity->SettrainingUse(trainingUseC);
        parzenDensity->Update();
        parzenArray = (vtkFloatArray *)parzenDensity->GetOutput()->GetPointData()->GetScalars();
        for (unsigned long int i=0; i<size; i++){
          outputArray->InsertNextValue(parzenArray->GetValue(i));
        }
        parzenDensity->Delete();
      }
      else {
        for (unsigned long int i=0; i<size; i++)
          outputArray->InsertNextValue(activation->GetValue(i)); 
      }   
      trainingUseC->Delete();
      UpdateProgress((n+1) * (1.0/nType));
    }   
  }
  
  // Mix of two Gaussian density estimations
  if (densityEstimate == 0) {

    trainingData = new float[size];
    posTrainingData = new float[size];
    negTrainingData = new float[size];
    for (int n=0; n<nType; n++){
      entryNumber = 0; 
      posEntryNumber = 0;
      negEntryNumber = 0;
      for (unsigned long int i=0; i<size; i++){
        if (classArray->GetValue(i) == n){
          trainingData[entryNumber] = activation->GetValue(i);
          if (trainingData[entryNumber] >= 0.0){
            posTrainingData[posEntryNumber] = trainingData[entryNumber];
            posEntryNumber += 1;
          }
          else{
            negTrainingData[negEntryNumber] = trainingData[entryNumber];
            negEntryNumber += 1;
          }
          entryNumber += 1;  
        }
      }
      if (entryNumber == 0){
        for (unsigned long int i=0; i<size; i++){
          outputArray->InsertNextValue(epsilon); 
        }
      }
      else {
        if ((posEntryNumber == 0) || (negEntryNumber == 0)){
          expectedValue = 0.0;
          for (unsigned long int i=0; i<entryNumber; i++){
            expectedValue += trainingData[i];
          }
          expectedValue = expectedValue/entryNumber;
          sum = 0.0;
          for (unsigned long int i=0; i<entryNumber; i++){      
            sum += pow((trainingData[i]-expectedValue),2);
          }
          var = sum/entryNumber;
          if (var == 0.0){
            var = 0.01;
          }
          for (unsigned long int i=0; i<size; i++){      
            outputArray->InsertNextValue(1/sqrt(2*pi*var)*exp(-1/(2*var)*pow(activation->GetValue(i) - expectedValue,2)));
          }    
        }
        else{
          expectedValue = 0.0;
          for (unsigned long int i=0; i<posEntryNumber; i++){
            expectedValue += posTrainingData[i];
          }
          expectedValue = expectedValue/posEntryNumber;
          sum = 0.0;
          for (unsigned long int i=0; i<posEntryNumber; i++){      
            sum += pow((posTrainingData[i]-expectedValue),2);
          }
          var = sum/posEntryNumber;
          if (var == 0.0){
            var = 0.01;
          }
          for (unsigned long int i=0; i<size; i++){      
            outputArray->InsertNextValue((posEntryNumber/(float)entryNumber)*(1/sqrt(2*pi*var)*exp(-1/(2*var)*pow(activation->GetValue(i) - expectedValue,2))));
          }
          expectedValue = 0.0;
          for (unsigned long int i=0; i<negEntryNumber; i++){
            expectedValue += negTrainingData[i];
          }
          expectedValue = expectedValue/negEntryNumber;
          sum = 0.0;
          for (unsigned long int i=0; i<negEntryNumber; i++){      
            sum += pow((negTrainingData[i]-expectedValue),2);
          }
          var = sum/negEntryNumber;
          if (var == 0.0){
            var = 0.01;
          }
          for (unsigned long int i=0; i<size; i++){      
            outputArray->SetValue((n*size)+i, (outputArray->GetValue(i))+((negEntryNumber/(float)entryNumber)*(1/sqrt(2*pi*var)*exp(-1/(2*var)*pow(activation->GetValue(i) - expectedValue,2)))));
          }
        }
      }
      UpdateProgress((n+1) * (1.0/nType));
    }
    delete [] trainingData;
    delete [] posTrainingData;
    delete [] negTrainingData;
  }
  
  // Setting all 0 values to epsilon
  for (int n=0; n<nType; n++){
    for (unsigned long int i=0; i<size; i++){
      if (outputArray->GetValue(i) == 0.0){
        outputArray->SetValue(i, epsilon); 
      }
    }
  }                 
      
  output->GetPointData()->SetScalars(outputArray);      
  outputArray->Delete();
}

// If the output image of a filter has different properties from the input image
// we need to explicitly define the ExecuteInformation() method
void vtkIsingConditionalDistribution::ExecuteInformation(vtkImageData *input, vtkImageData *output)
{

  dims[0] = x;
  dims[1] = y;
  dims[2] = z*nType;
  output->SetDimensions(dims);
  output->SetWholeExtent(0, x, 0, y, 0, z*nType);
  output->SetExtent(0, x, 0, y, 0, z*nType);
  output->SetScalarType(VTK_FLOAT);
  output->SetSpacing(1.0,1.0,1.0);
  output->SetOrigin(0.0,0.0,0.0);
  output->AllocateScalars();      
}
