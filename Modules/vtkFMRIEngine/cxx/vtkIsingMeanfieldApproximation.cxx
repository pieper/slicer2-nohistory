/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIsingMeanfieldApproximation.cxx,v $
  Date:      $Date: 2007/03/15 19:43:23 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               File: vtkIsingMeanfieldApproximation.cxx                     //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes for each voxel the posterior class probability       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#include "vtkObjectFactory.h"
#include "vtkIsingMeanfieldApproximation.h"
#include "vtkCommand.h"

vtkStandardNewMacro(vtkIsingMeanfieldApproximation);

vtkIsingMeanfieldApproximation::vtkIsingMeanfieldApproximation()
{
  this->nonactive = 0;
  this->posactive = 301;
  this->negactive = 300;
  this->logTransitionMatrix = vtkFloatArray::New();
}

vtkIsingMeanfieldApproximation::~vtkIsingMeanfieldApproximation()
{
  this->logTransitionMatrix->Delete();
}

void vtkIsingMeanfieldApproximation::SimpleExecute(vtkImageData *input, vtkImageData *output)
{
  dims[0] = x;
  dims[1] = y;
  dims[2] = z;
  size = x*y*z;
  int numberOfInputs;
#if (VTK_MAJOR_VERSION >= 5)
  numberOfInputs = this->GetNumberOfInputConnections(0);
#else  
  numberOfInputs = this->NumberOfInputs;
#endif
  
  // in case of anatomical label map input
  if (numberOfInputs == 3){
    segMArray = vtkIntArray::New();
    for (unsigned long int idx=0; idx<size; idx++){
      segMArray->InsertNextValue(0);
    }
    register int i, j, k;     
    for (k=0; k<z; k++)
      for (j=0; j<y; j++)
        for (i=0; i<x; i++){
          labelValue = (short int *) (GetInput(2)->GetScalarPointer(i,j,k));
          segMArray->SetValue((k*x*y)+(j*x)+i,(int)(*labelValue));
        }
    for (int j=0; j<segInput; j++){
      for (unsigned long int i=0; i<size; i++)
        if (segMArray->GetValue(i) == segLabel->GetValue(j))
          segMArray->SetValue(i,j);
    }
  }
  else {
    segMArray = vtkIntArray::New();
    for (unsigned long int i=0; i<size; i++) 
      segMArray->InsertNextValue(0);
  }
  
  vtkIntArray *classArray = (vtkIntArray *)this->GetInput(0)->GetPointData()->GetScalars();
        
  sum = 0;
  for (int i=0; i<(nType*nType); i++)
    sum += (transitionMatrix->GetValue(i));
        
  if (sum == 0){      
    // construction of a matrix indicating the transition strength between classes      
    register int i, j, k;
    for (i=0; i<x; i++){
      for (j=0; j<y; j++){
        for (k=0; k<z; k++){
          if (i != 0){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue((k*x*y)+(j*x)+i-1);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));
          }
          if (i != x-1){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue((k*x*y)+(j*x)+i+1);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));
          }
          if (j != 0){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue((k*x*y)+((j-1)*x)+i);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));
          }
          if (j != y-1){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue((k*x*y)+((j+1)*x)+i);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));       
          }
          if (k != 0){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue(((k-1)*x*y)+(j*x)+i);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));
          }
         if (k != z-1){
            index1 = classArray->GetValue((k*x*y)+(j*x)+i);
            index2 = classArray->GetValue(((k+1)*x*y)+(j*x)+i);
            transitionMatrix->SetValue((index1*nType)+index2, (transitionMatrix->GetValue((index1*nType)+index2)+1));
          }
        }
      }
    }
        
    // neighborhoods were counted double
    for (int i=0; i<nType; i++)
      if (transitionMatrix->GetValue((i*nType)+i) != 0)
        transitionMatrix->SetValue((i*nType)+i, (transitionMatrix->GetValue((i*nType)+i))/2);
  }  
  
  // in case of existing 0 values in transition matrix, increase all by 1 to prevent log range error   
  for (int i=0; i<(nType*nType); i++)
    if (transitionMatrix->GetValue(i) == 0){
      for (int j=0; j<(nType*nType); j++)             
        transitionMatrix->SetValue(j, (transitionMatrix->GetValue(j))+1);     
      break;
    }
  
  // construction of log transition matrix
  logTransitionMatrix->SetNumberOfValues(nType*nType);
  for (int i=0; i<nType; i++){
    for (int j=0; j<nType; j++){
      logHelp = (float) log((transitionMatrix->GetValue((i*nType)+j))/sqrt(((activationFrequence->GetValue(i))*size)*((activationFrequence->GetValue(j))*size)));                  
      logTransitionMatrix->SetValue((i*nType)+j, logHelp);
    }
  }
  
  vtkFloatArray *probGivenClassArray = (vtkFloatArray *)this->GetInput(1)->GetPointData()->GetScalars();
  vtkFloatArray *outputArray = vtkFloatArray::New();
  vtkIntArray *finalOutput = vtkIntArray::New();
  
  output->SetDimensions(dims);
  output->SetScalarType(VTK_INT);
  output->SetSpacing(1.0,1.0,1.0);
  output->SetOrigin(0.0,0.0,0.0);
  output->AllocateScalars();

  helpArray = new float[nType];

  // initialization of class probability output volume
  for (int ndx=0; ndx<nType; ndx++)
    {
    for (unsigned long int idx=0; idx<size; idx++)
      {
      outputArray->InsertNextValue((1.0/nType));
      }
    }
  
  // meanfield iteration     
  register int i, j, k, n;     
  for (n=0; n<iterations; n++){
    for (k=0; k<z; k++){
      for (j=0; j<y; j++) {
        for (i=0; i<x; i++){
          sumHelpArray = 0.0;
          for (int l=0; l<nType; l++){
            eValue = 0.0;          
            if (i != 0){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+(k*x*y)+(j*x)+i-1))*(logTransitionMatrix->GetValue((l*nType)+s))); 
            }    
            if (i != x-1){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+(k*x*y)+(j*x)+i+1))*(logTransitionMatrix->GetValue((l*nType)+s)));                             
            }           
            if (j != 0){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+(k*x*y)+((j-1)*x)+i))*(logTransitionMatrix->GetValue((l*nType)+s))); 
            }           
            if (j != y-1){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+(k*x*y)+((j+1)*x)+i))*(logTransitionMatrix->GetValue((l*nType)+s)));
            }        
            if (k != 0){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+((k-1)*x*y)+(j*x)+i))*(logTransitionMatrix->GetValue((l*nType)+s))); 
            }    
            if (k != z-1){
              for (int s=0; s<nType; s++)
                eValue += ((outputArray->GetValue((s*size)+((k+1)*x*y)+(j*x)+i))*(logTransitionMatrix->GetValue((l*nType)+s))); 
            }        
                        
            helpArray[l] = (activationFrequence->GetValue(l)) * (probGivenSegM->GetValue((segMArray->GetValue((k*x*y)+(j*x)+i))*nType+l)) * (probGivenClassArray->GetValue((l*size)+(k*x*y)+(j*x)+i)) * exp(eValue);                    
            sumHelpArray += helpArray[l];
          }
          for (int l=0; l<nType; l++){
            outputArray->SetValue((l*size)+(k*x*y)+(j*x)+i, helpArray[l]/sumHelpArray);
          }
        }
      }
    }
    UpdateProgress(n * (1.0/iterations));   
  }
  
  // creation of activation label map
  for (unsigned long int i=0; i<size; i++){
    max = 0.0;
    posMax = 0;
    for (int n=0; n<nType; n++){
      if ((outputArray->GetValue((n*size)+i)) > max){
        max = (outputArray->GetValue((n*size)+i)); 
        posMax = n;
      }
    }   
    if (numActivationStates == 2){
      if (posMax < (nType/2))
        finalOutput->InsertNextValue(nonactive);
      else
        finalOutput->InsertNextValue(posactive);
    }
    else{
      if (posMax < (nType/3))
        finalOutput->InsertNextValue(nonactive);
      else
        if ((posMax >= (nType/3)) && (posMax < 2*(nType/3)))
          finalOutput->InsertNextValue(posactive);
        else
          finalOutput->InsertNextValue(negactive);
    }
  }     

  output->GetPointData()->SetScalars(finalOutput);
  
#if (VTK_MAJOR_VERSION >= 5)
  numberOfInputs = this->GetNumberOfInputConnections(0);
#else  
  numberOfInputs = this->NumberOfInputs;
#endif
  if (numberOfInputs != 3)
  {
    segMArray->Delete();
  }
  delete [] helpArray;
  outputArray->Delete(); 
  finalOutput->Delete();     
}



// If the output image of a filter has different properties from the input image
// we need to explicitly define the ExecuteInformation() method
void vtkIsingMeanfieldApproximation::ExecuteInformation(vtkImageData *input, vtkImageData *output)
{
  output->SetDimensions(dims);
  output->SetScalarType(VTK_INT);
  output->SetSpacing(1.0,1.0,1.0);
  output->SetOrigin(0.0,0.0,0.0);
  output->AllocateScalars();
}
