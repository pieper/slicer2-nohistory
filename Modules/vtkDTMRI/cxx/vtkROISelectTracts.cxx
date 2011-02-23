/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkROISelectTracts.cxx,v $
  Date:      $Date: 2006/08/24 18:30:48 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/

#include "vtkROISelectTracts.h"
#include "vtkStreamlineConvolve.h"
#include "vtkPruneStreamline.h"
#include "vtkCellArray.h"
#include "vtkProperty.h"

#include "vtkHyperStreamlineDTMRI.h"


//------------------------------------------------------------------------------
vtkROISelectTracts* vtkROISelectTracts::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkROISelectTracts");
  if(ret)
    {
      return (vtkROISelectTracts*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkROISelectTracts;
}

//----------------------------------------------------------------------------
vtkROISelectTracts::vtkROISelectTracts()
{
  // matrices
  // Initialize these to identity, so if the user doesn't set them it's okay.
  this->ROIWldToIjk = vtkTransform::New();
  this->StreamlineWldToScaledIjk = vtkTransform::New();
  
  // The user may need to set these, depending on class usage
  this->InputROI = NULL;
  this->InputROI2 = NULL;
  this->InputROIValue = -1;
  this->InputANDROIValues = NULL;
  this->InputNOTROIValues = NULL;
  this->StreamlineController = NULL;

  this->PassThreshold = 1;
  
  this->ConvolutionKernel = NULL;

  // collections
  this->Streamlines = NULL;
  this->ColorStreamlines = vtkDoubleArray::New();
  this->ColorStreamlines->SetNumberOfComponents(4);

  // for fibers selecting fibers that pass through a ROI
  this->StreamlinesAsPolyLines = vtkPolyData::New();
  this->StreamlineIdPassTest = vtkIntArray::New();

}

//----------------------------------------------------------------------------
vtkROISelectTracts::~vtkROISelectTracts()
{
  // matrices
  this->ROIWldToIjk->Delete();
  this->StreamlineWldToScaledIjk->Delete();
  // volumes
  if (this->InputROI) this->InputROI->Delete();
  if (this->InputROI2) this->InputROI2->Delete();
  
  this->ColorStreamlines->Delete();

}

void vtkROISelectTracts::ConvertStreamlinesToPolyLines()
{

  int numStreamlines;
  vtkPoints *newPoints = vtkPoints::New();
  vtkCellArray *newLines = vtkCellArray::New(); 
  vtkPoints *strPoints;
  vtkHyperStreamline *currStreamline = NULL;
  int npts = 0;
  
  if (this->Streamlines == 0) 
    {
      vtkErrorMacro("You must set the Streamlines before using this class.");
      return;
    }

  numStreamlines = this->Streamlines->GetNumberOfItems();
  
  this->Streamlines->InitTraversal();
  for(int i=0 ; i<numStreamlines; i++)
    {
      currStreamline= dynamic_cast<vtkHyperStreamline *> (this->Streamlines->GetNextItemAsObject());
    
      //strPoints = currStreamline->GetHyperStreamline0();
      strPoints = currStreamline->GetOutput()->GetCell(0)->GetPoints();
      npts += strPoints->GetNumberOfPoints();
      //strPoints = currStreamline->GetHyperStreamline1();
      strPoints = currStreamline->GetOutput()->GetCell(1)->GetPoints();
      npts += strPoints->GetNumberOfPoints();
    }
  
  
  newPoints->SetNumberOfPoints(npts);
  
  int strIdx=0;
  this->Streamlines->InitTraversal();
  for(int i=0 ; i<numStreamlines; i++)
    {
      currStreamline= dynamic_cast<vtkHyperStreamlineDTMRI *> (this->Streamlines->GetNextItemAsObject());
    
      //strPoints = currStreamline->GetHyperStreamline0();
      strPoints = currStreamline->GetOutput()->GetCell(0)->GetPoints();
      newLines->InsertNextCell(strPoints->GetNumberOfPoints());
      for(int j=0; j<strPoints->GetNumberOfPoints();j++)
        {
          newPoints->SetPoint(strIdx,strPoints->GetPoint(j));
          newLines->InsertCellPoint(strIdx);
          strIdx++;
        }
      
      //strPoints = currStreamline->GetHyperStreamline1();
      strPoints = currStreamline->GetOutput()->GetCell(1)->GetPoints();
      newLines->InsertNextCell(strPoints->GetNumberOfPoints());
      for(int j=0; j<strPoints->GetNumberOfPoints();j++)
        {
          newPoints->SetPoint(strIdx,strPoints->GetPoint(j));
          newLines->InsertCellPoint(strIdx);
          strIdx++;
        }
    }

  this->StreamlinesAsPolyLines->SetPoints(newPoints);
  this->StreamlinesAsPolyLines->SetLines(newLines);
  newPoints->Delete();
  newLines->Delete();
}
    
void vtkROISelectTracts::FindStreamlinesThatPassThroughROI()
{

  if (this->Streamlines == 0) 
    {
      vtkErrorMacro("You must set the Streamlines before using this class.");
      return;
    }
  if (this->ConvolutionKernel == NULL)
    {
    vtkErrorMacro("You must set a convolution kernel.");
    return;
    }
  

  this->ConvertStreamlinesToPolyLines();
 
  vtkStreamlineConvolve *conv = vtkStreamlineConvolve::New();
  vtkPruneStreamline *finder = vtkPruneStreamline::New();
 
  //Create minipipeline
  conv->SetStreamlines(this->StreamlinesAsPolyLines);
  conv->SetInput(this->InputROI);
  
  //Set transformation to go from ScaleIjk of the streamlines
  //to ijk of the ROI
  vtkTransform *trans = vtkTransform::New();
  trans->Concatenate(this->StreamlineWldToScaledIjk);
  trans->Inverse();
  trans->PostMultiply();
  trans->Concatenate(this->ROIWldToIjk);
  conv->SetTransform(trans);
  
  // new conv
  //conv->SetKernelSize(9);
  //conv->SetSigma(1.5,1.5,1);
  
   
  int val = this->ConvolutionKernel->GetNumberOfTuples();
  if (val == 27)
    {
    conv->SetKernel3x3x3(this->ConvolutionKernel);
    }
  else if(val == (5*5*5))
    {
    conv->SetKernel5x5x5(this->ConvolutionKernel);
    }
  else if(val == (7*7*7))
    {
    conv->SetKernel7x7x7(this->ConvolutionKernel);
    }  
   else {
     vtkErrorMacro("Kernel dimensions does not fit.");
    } 

  conv->Update();
 
  finder->SetInput(conv->GetOutput());
  finder->SetANDROIValues(this->InputANDROIValues);
  finder->SetNOTROIValues(this->InputNOTROIValues);
  finder->SetThreshold(this->PassThreshold);
 
  //Update minipipeline
  finder->Update();
 
  //Get streamline info and set visibility off.
  this->StreamlineIdPassTest->DeepCopy(finder->GetStreamlineIdPassTest());
 
 
  //Delete minipipeline
  trans->Delete();
  conv->Delete();
  finder->Delete();
 
}


void vtkROISelectTracts::HighlightStreamlinesPassTest()
{
  vtkIdType strId;

  if (this->StreamlineController == 0) 
    {
      vtkErrorMacro("You must set a Streamlines Controller before using this class.");
      return;
    }

  int numStr = this->StreamlineIdPassTest->GetNumberOfTuples();
  //cout<<"Number of Streamlines that pass test: "<<numStr<<endl;
    
  if (numStr == 0)
    return;
  
  //Save color of actors. If coloractor is filled restore the value of
  // the actors. If not, fill coloractor with new values 
  unsigned char RGBA[4];
  double color[4];
  vtkHyperStreamline *currStreamline;
  if (this->ColorStreamlines->GetNumberOfTuples()==this->Streamlines->GetNumberOfItems())
    {
    for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->ColorStreamlines->GetTuple(i,color);
      RGBA[0]= (unsigned char) color[0];
      RGBA[1]= (unsigned char) color[1];
      RGBA[2]= (unsigned char) color[2];
      RGBA[3]= (unsigned char) color[3];
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,RGBA);
     }
    }
   else if (this->ColorStreamlines->GetNumberOfTuples()>0) {
     //User might delete/add some fibers.
     //Set all the actors to the same color as a hack
     this->ColorStreamlines->GetTuple(0,color);
     for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,(unsigned char) color[0], (unsigned char) color[1], (unsigned char) color[2], (unsigned char) color[3]);
     }
    }        
    else {
     // Store colors
     this->ColorStreamlines->Reset();
     this->ColorStreamlines->SetNumberOfComponents(4);
     this->ColorStreamlines->SetNumberOfTuples(this->Streamlines->GetNumberOfItems());
     for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->StreamlineController->GetDisplayTracts()->GetStreamlineRGBA(currStreamline,RGBA);
      color[0] = (double) RGBA[0];
      color[1] = (double) RGBA[1];
      color[2] = (double) RGBA[2];
      color[3] = (double) RGBA[3];
      this->ColorStreamlines->SetComponent(i,0,color[0]);
      this->ColorStreamlines->SetComponent(i,1,color[1]);
      this->ColorStreamlines->SetComponent(i,2,color[2]);
      this->ColorStreamlines->SetComponent(i,3,color[3]);
     }
    }

  int idx=0;
  // set red color
  RGBA[0]=255;
  RGBA[1]=0;
  RGBA[2]=0;
  RGBA[3]=255;

  for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
    strId = this->StreamlineIdPassTest->GetValue(idx);
    if(strId!=i) {
      //this->DeleteStreamline(i);
      //Changes Opacity
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      //this->StreamlineController->GetDisplayTracts()->SetStreamlineOpacity(currStreamline,(unsigned char) 50);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,0,0,255,150);
    }
    else {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,255,0,0,255);
      //cout<<"Streamline Id: "<<strId<<endl;
      idx++;
    }  
     
  }
}

void vtkROISelectTracts::ResetStreamlinesPassTest()
{
 
 //Restore actors colors
  double color[4];
  vtkHyperStreamline *currStreamline;
  if (this->ColorStreamlines->GetNumberOfTuples()==this->Streamlines->GetNumberOfItems())
    {
    for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->ColorStreamlines->GetTuple(i,color);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,(unsigned char) color[0], (unsigned char) color[1], (unsigned char) color[2], (unsigned char) color[3]);
     }
    }
   else if (this->ColorStreamlines->GetNumberOfTuples()>0) {
     //User might delete/add some fibers.
     //Set all the actors to the same color as a hack
     this->ColorStreamlines->GetTuple(0,color);
     for (int i=0;i<this->Streamlines->GetNumberOfItems();i++) {
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,(unsigned char) color[0], (unsigned char) color[1], (unsigned char) color[2], (unsigned char) color[3]);
     } 
   }
 
  //Reset color actors
  this->ColorStreamlines->Reset();
 
 //Reset streamline Id pass test
  this->StreamlineIdPassTest->Reset();
}

void vtkROISelectTracts::DeleteStreamlinesNotPassTest()
{
 
  vtkIdType strId;

  if (this->Streamlines == 0) 
    {
      vtkErrorMacro("You must set the Streamlines before using this class.");
      return;
    }

  int numStr = this->StreamlineIdPassTest->GetNumberOfTuples();
  //cout<<"Number of Streamlines that pass test: "<<numStr<<endl;
  
  //nothing to delete.
  if (numStr == 0)
    return;

  // The collection is a FILO list (First in - Last out).
  // We run the list backwards
  vtkHyperStreamline *currStreamline;
  double color[4];

  int idx=numStr-1;
  for (int i=this->Streamlines->GetNumberOfItems()-1;i>=0;i--) {
    strId = this->StreamlineIdPassTest->GetValue(idx);
    if(strId!=i) {
      this->StreamlineController->DeleteStreamline(i);
    }
    else {
      //cout<<"Streamline Id: "<<strId<<endl;
      //Restore original color
      currStreamline = (vtkHyperStreamline *) this->Streamlines->GetItemAsObject(i);
      this->ColorStreamlines->GetTuple(i,color);
      this->StreamlineController->GetDisplayTracts()->SetStreamlineRGBA(currStreamline,(unsigned char) color[0], (unsigned char) color[1], (unsigned char) color[2], (unsigned char) color[3]);
      idx--;
    }
  }

  //Reset list of Streamlines Ids that pass the test
  this->StreamlineIdPassTest->Reset(); 
  this->ColorStreamlines->Reset(); 

}
