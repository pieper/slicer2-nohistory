/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPruneStreamline.cxx,v $
  Date:      $Date: 2006/03/06 21:07:29 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/

#include "vtkPruneStreamline.h"

#include "vtkAbstractTransform.h"
#include "vtkCellData.h"
#include "vtkFloatArray.h"
#include "vtkLinearTransform.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"
#include "vtkPolyData.h"

#include "vtkDoubleArray.h"
#include "vtkCellArray.h"
#include "vtkDataArray.h"
#include "vtkMath.h"

#define VTK_MARGIN 0.1

vtkCxxRevisionMacro(vtkPruneStreamline, "$Revision: 1.7 $");

vtkStandardNewMacro(vtkPruneStreamline);

vtkPruneStreamline::vtkPruneStreamline()
{
  this->ANDROIValues = NULL;
  this->NOTROIValues = NULL;
  this->Threshold = 1;
  this->MaxResponse = NULL;
  this->StreamlineIdPassTest = vtkIntArray::New();
}

vtkPruneStreamline::~vtkPruneStreamline()
{
  this->SetANDROIValues(NULL);
  this->SetNOTROIValues(NULL);
  this->StreamlineIdPassTest->Delete();
}

void vtkPruneStreamline::Execute()
{
  vtkPoints *inPts;
  vtkPoints *newPts;
  vtkIdType numPts, numCells, numStreamlines, numANDROIs, numNOTROIs;
  vtkPolyData *input = this->GetInput();
  vtkPolyData *output = this->GetOutput();
  vtkPointData *pd=input->GetPointData(), *outPD=output->GetPointData();
  vtkCellData *cd=input->GetCellData(), *outCD=output->GetCellData();
  vtkCellArray *inLines;
  vtkDataArray *inScalars;

  vtkDebugMacro(<<"Executing pruning of streamlines");

  // Check input
  //
  if ( this->ANDROIValues == NULL && this->NOTROIValues)
    {
    vtkErrorMacro(<<"No ROIs defined!");
    return;
    }
    

  inPts = input->GetPoints();
  inLines = input->GetLines();

  if ( !inPts )
    {
    vtkErrorMacro(<<"No input data");
    return;
    }
  if ( !inLines )
    {
    vtkErrorMacro(<<"No Streamline data");
    return;
    }
  
  numCells = inLines->GetNumberOfCells();
  numPts = inPts->GetNumberOfPoints();
  inScalars = input->GetPointData()->GetScalars();
  
  if (this->ANDROIValues)
    numANDROIs = this->ANDROIValues->GetNumberOfTuples();
  else
    numANDROIs = 0;
  if (this->NOTROIValues)
    numNOTROIs = this->NOTROIValues->GetNumberOfTuples();
  else
    numNOTROIs = 0; 
    
  numStreamlines = numCells/2;
    
  vtkIdType npts;
  vtkIdType *ptId;
  
  
  vtkDoubleArray *DinScalars = vtkDoubleArray::New();
  DinScalars->SetNumberOfValues(numPts);
  double pp1[3];
  double pm1[3];
  double dt;
  double vp1;
  double vm1;
  
  this->UpdateProgress (.2);
  //For each streamline, compute Gradient
  inLines->InitTraversal();
  for(int i=0; i<numStreamlines; i++) {
  
    for(int cellId=0; cellId<2; cellId++) {
     //inLines->GetCell(i*2+cellId,npts,ptId);
     inLines->GetNextCell(npts,ptId);
     //cout<<"Num points in cell: "<<npts<<endl;
     
     //Compute Central Finite Difference
     for(int j=1;j<npts-1;j++) {
       vp1=inScalars->GetComponent(ptId[j+1],0);
       vm1=inScalars->GetComponent(ptId[j-1],0);

       inPts->GetPoint(ptId[j+1],pp1);
       inPts->GetPoint(ptId[j-1],pm1);
  
       dt =vtkMath::Distance2BetweenPoints(pp1,pm1);
       
       DinScalars->SetValue(ptId[j],(vp1-vm1)/dt);
       //cout<<"Ds: "<<(vp1-vm1)/dt<<endl;
     }
     // Last point equals to last value
     DinScalars->SetValue(ptId[npts-1],(vp1-vm1)/dt);
     // First point equals to first value
     DinScalars->SetValue(ptId[0],DinScalars->GetValue(ptId[1]));
    
    }
  }
 
 this->UpdateProgress (.4);  

  StreamlineIdPassTest->Initialize();
  StreamlineIdPassTest->Allocate(numStreamlines);
  int *streamlineANDTest = new int[numANDROIs]; 
  int *streamlineNOTTest = new int[numNOTROIs];
  
  
  //Data to store result  
  newPts = vtkPoints::New();
  newPts->Allocate(numPts);
  vtkCellArray *newLines = vtkCellArray::New();
  vtkIdType newptId = 0;
  short rval0;
  double val;
  int test;
  
  int *fiberResponse = new int[numANDROIs+numNOTROIs];
  this->MaxResponse = new int[numANDROIs+numNOTROIs];
  
  for (int rId = 0; rId < numANDROIs + numNOTROIs; rId++) 
      this->MaxResponse[rId] = 0; 
   

  //For each streamline, find the max response
  inLines->InitTraversal();
  for(int sId=0; sId<numStreamlines; sId++) {  
    
    for (int rId = 0; rId < numANDROIs + numNOTROIs; rId++) 
      fiberResponse[rId] = 0; 

    for(int cellId=0; cellId<2; cellId++) {
      inLines->GetNextCell(npts,ptId);
      
      for(int j=0;j<npts;j++) {
         val=inScalars->GetComponent(ptId[j],0);
         //cout<<"Value: "<<val<<endl;
         for(int rId=0;rId<numANDROIs;rId++) {
      
           rval0 = ANDROIValues->GetValue(rId);
           if(val>(rval0-VTK_MARGIN) && val<(rval0+VTK_MARGIN)) {
           //We got response for this ROI
           fiberResponse[rId]++;
           break;
           }
         }
      
      
         for(int rId=0;rId<numNOTROIs;rId++) {
      
           rval0 = NOTROIValues->GetValue(rId);
           if(val>(rval0-VTK_MARGIN) && val<(rval0+VTK_MARGIN)) {
              //We got response for this ROI
              fiberResponse[rId+numANDROIs]++;
              break;
           }
         }  
    
       } //end j loop throught cell points
    } //end cellId  
 
    
    for (int rId = 0; rId < numANDROIs + numNOTROIs; rId++) 
     {
      if (this->MaxResponse[rId] <= fiberResponse[rId]) {
       this->MaxResponse[rId] = fiberResponse[rId];
      } 
     }
      
 }//end loop through streamlines 

   //For each streamline see the responses that pass the test.
  inLines->InitTraversal();
  for(int sId=0; sId<numStreamlines; sId++) {
  
    //Set array to zero
    for (int i=0; i<numANDROIs;i++)
      streamlineANDTest[i] = 0;
 
    
    for (int i=0; i<numNOTROIs;i++)
      streamlineNOTTest[i] = 0;
    
    for(int cellId=0; cellId<2; cellId++) {
      inLines->GetNextCell(npts,ptId);
      
      for(int j=0;j<npts;j++) {
         val=inScalars->GetComponent(ptId[j],0);
         //cout<<"Value: "<<val<<endl;
         for(int rId=0;rId<numANDROIs;rId++) {
      
           rval0 = ANDROIValues->GetValue(rId);
           if(val>(rval0-VTK_MARGIN) && val<(rval0+VTK_MARGIN)) {
           //We got response for this ROI
           streamlineANDTest[rId] += 1; 
           break;
           }
         }
      
      
         for(int rId=0;rId<numNOTROIs;rId++) {
      
           rval0 = NOTROIValues->GetValue(rId);
           if(val>(rval0-VTK_MARGIN) && val<(rval0+VTK_MARGIN)) {
              //We got response for this ROI
              streamlineNOTTest[rId] += 1; 
              break;
           }
         }  
    
       } //end j loop throught cell points
    } //end cellId  
 
   test=this->TestForStreamline(streamlineANDTest,numANDROIs,streamlineNOTTest, numNOTROIs);
      
   //Copy cell info to output
   if(test ==1) {
     StreamlineIdPassTest->InsertNextValue(sId);
     for(int cellId=0; cellId<2; cellId++) {
       inLines->GetCell(sId*2+cellId,npts,ptId);
       newLines->InsertNextCell(npts);
       for(int j=0;j<npts;j++) {
         newptId=newPts->InsertNextPoint(inPts->GetPoint(ptId[j]));
     newLines->InsertCellPoint(newptId);
       }    
     }
   }  
 
 }// end loop thourgh streamlines.
 
 this->UpdateProgress (.9);
 
 delete streamlineANDTest;
 delete streamlineNOTTest;
 delete fiberResponse;
 delete this->MaxResponse;
 this->MaxResponse = NULL;
  
 StreamlineIdPassTest->Squeeze();
     
  // Define output    
  output->SetPoints(newPts);
  newPts->Delete();
  output->SetLines(newLines);
  newLines->Delete();
  output->Squeeze();        

  DinScalars->Delete();

}       
       
  
int vtkPruneStreamline::TestForStreamline(int* streamlineANDTest, int nptsAND, int *streamlineNOTTest, int nptsNOT)
{

  int i;
  int test;
  int th;
  
  test =0;
    
  test = 1;

  for(i=0;i<nptsAND;i++) {
    th = (int) ceil(this->Threshold*this->MaxResponse[i]);
    test = test && (streamlineANDTest[i]>th);    
  }
  
  for(i=0;i<nptsNOT;i++) {
    th = (int) ceil(this->Threshold*this->MaxResponse[i+nptsAND]);
    test = test && (streamlineNOTTest[i]<=th);    
  }
  
  return test;        
    
}  
  

unsigned long vtkPruneStreamline::GetMTime()
{
  unsigned long mTime=this->MTime.GetMTime();
  unsigned long transMTime;

  if ( this->ANDROIValues )
    {
    transMTime = this->ANDROIValues->GetMTime();
    mTime = ( transMTime > mTime ? transMTime : mTime );
    }
    
   if ( this->NOTROIValues )
    {
    transMTime = this->NOTROIValues->GetMTime();
    mTime = ( transMTime > mTime ? transMTime : mTime );
    }
       
    

  return mTime;
}

void vtkPruneStreamline::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  os << indent << "Array of AND ROI Values: " << this->ANDROIValues << "\n";  
  os << indent << "Array of NOT ROI Values: " << this->NOTROIValues << "\n";
}
