/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkIsingActivationTissue.cxx,v $
  Date:      $Date: 2007/03/15 19:43:23 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//               File: vtkIsingActivationTissue.cxx                           //
//               Date: 05/2006                                                //
//               Author: Carsten Richter                                      //
//                                                                            //
// Description: computes class label map depending on segmentation volume and //
//                activation volume input                                     //
//              computes class frequence                                      //
//                class = (non state * segmentation labels) +                 // 
//                        (pos state * segmentation labels) +                 // 
//                        (neg state * segmentation labels)                   // 
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#include "vtkObjectFactory.h"
#include "vtkIsingActivationTissue.h"

vtkStandardNewMacro(vtkIsingActivationTissue);

vtkIsingActivationTissue::vtkIsingActivationTissue()
{
  this->activationFrequence = vtkFloatArray::New();
}

vtkIsingActivationTissue::~vtkIsingActivationTissue()
{
  this->activationFrequence->Delete();
}

void vtkIsingActivationTissue::SimpleExecute(vtkImageData *input, vtkImageData *output)
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
  // initialization of activation Frequence
  for (int i=0; i<nType; i++){
    activationFrequence->InsertNextValue(0.0);
  }
  
  output->SetDimensions(dims);
  output->SetScalarType(VTK_INT);
  output->SetNumberOfScalarComponents(1);
  output->AllocateScalars();

  // in case of anatomical label map input
  if (numberOfInputs == 2){
    segMArray = vtkIntArray::New();
    for (unsigned long int i=0; i<size; i++){
      segMArray->InsertNextValue(0);
    }
    register int i, j, k;     
    for (k=0; k<z; k++){
      for (j=0; j<y; j++){
        for (i=0; i<x; i++){
          labelValue = (short int *) (GetInput(1)->GetScalarPointer(i,j,k));
          segMArray->SetValue((k*x*y)+(j*x)+i,(int)(*labelValue));
        }
      }
    }
    for (int j=0; j<segInput; j++){
      if ((segLabel->GetValue(j)) == greyValue){
        nGreyValue = j;
      }
      for (unsigned long int i=0; i<size; i++){
        if ((segMArray->GetValue(i)) == (segLabel->GetValue(j))){
          segMArray->SetValue(i,j);  
        }
      }
    }
  }
 
  vtkIntArray *activation = (vtkIntArray *)this->GetInput(0)->GetPointData()->GetScalars();
  vtkIntArray *outputArray = vtkIntArray::New();
  
  // calculation of class volume
  // class = (non state * segmentation labels) +                 
  //         (pos state * segmentation labels) +                 
  //         (neg state * segmentation labels)    
  nonpp = 0.0;
  pospp = 0.0;
  negpp = 0.0;     
  for (unsigned long int i=0; i<size; i++){
    if (numberOfInputs == 2){
      classIndex = ((activation->GetValue(i)) * segInput) + (segMArray->GetValue(i));
      outputArray->InsertNextValue(classIndex);
      if ((segMArray->GetValue(i)) == nGreyValue){
        if ((activation->GetValue(i)) == 0){
          nonpp += 1.0;
        }
        if ((activation->GetValue(i)) == 1){
          pospp += 1.0;
        }
        if ((activation->GetValue(i)) == 2){
          negpp += 1.0;
        }
      }
    }
    else {
      classIndex = activation->GetValue(i);
      outputArray->InsertNextValue(classIndex);
    }
    activationFrequence->SetValue(classIndex, activationFrequence->GetValue(classIndex) + 1);
  }      
  
  // calculation of activation probability of grey matter
  sumpp = nonpp+pospp+negpp;
  if (sumpp != 0.0){
    nonpp = nonpp/(1.0*(sumpp));
    pospp = pospp/(1.0*(sumpp));
    negpp = negpp/(1.0*(sumpp));
  }
  
  // calculation of class frequence
  for (int i=0; i<nType; i++){
    if (activationFrequence->GetValue(i) > 0.0)
      activationFrequence->SetValue(i, (activationFrequence->GetValue(i))/(float)size);  
    else
      activationFrequence->SetValue(i, 1.0/size);   
  }
  output->GetPointData()->SetScalars(outputArray);
  outputArray->Delete();      
}
