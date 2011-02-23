/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkSaveTracts.cxx,v $
  Date:      $Date: 2007/03/13 21:47:07 $
  Version:   $Revision: 1.13 $

=========================================================================auto=*/
#include "vtkSaveTracts.h"

#include "vtkAppendPolyData.h"
#include "vtkPolyDataWriter.h"
#include "vtkTransformPolyDataFilter.h"
#include "vtkMrmlModelNode.h"

#include "vtkPolyData.h"
#include "vtkTubeFilter2.h"
#include "vtkProbeFilter.h"
#include "vtkPointData.h"
#include "vtkMath.h"

#include "vtkActor.h"
#include "vtkProperty.h"

#include "vtkFloatArray.h"
#include "vtkIntArray.h"

#include <sstream>
#include <map>

#include "vtkHyperStreamline.h"

//#include "vtkImageWriter.h"

//------------------------------------------------------------------------------
vtkSaveTracts* vtkSaveTracts::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkSaveTracts");
  if(ret)
    {
      return (vtkSaveTracts*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkSaveTracts;
}

//----------------------------------------------------------------------------
vtkSaveTracts::vtkSaveTracts()
{
  // Initialize these to identity, so if the user doesn't set them it's okay.
  this->WorldToTensorScaledIJK = vtkTransform::New();
  this->TensorRotationMatrix = vtkMatrix4x4::New();

  // collections
  this->Streamlines = NULL;
  this->TubeFilters = NULL;

  //Display controller: we need this to access the color
  this->Display = NULL;

  // optional input data
  this->InputTensorField = NULL;
  
  // settings
  this->SaveForAnalysis = 0;
  
  // default to world coordinates
  this->OutputCoordinateSystem = 1;

  // default to values that will cause no centering
  // i.e. unless these are set, CenteredScaledIJK
  // is the same as scaledIJK.
  this->ExtentForCenteredScaledIJK[0] = 0;
  this->ExtentForCenteredScaledIJK[1] = 0;
  this->ExtentForCenteredScaledIJK[2] = 0;
  this->ExtentForCenteredScaledIJK[3] = 0;
  this->ExtentForCenteredScaledIJK[4] = 0;
  this->ExtentForCenteredScaledIJK[5] = 0;

  this->ScalingForCenteredScaledIJK[0] = 1;
  this->ScalingForCenteredScaledIJK[1] = 1;
  this->ScalingForCenteredScaledIJK[2] = 1;
}

//----------------------------------------------------------------------------
vtkSaveTracts::~vtkSaveTracts()
{
  this->WorldToTensorScaledIJK->Delete();
  this->TensorRotationMatrix->Delete();

}


void vtkSaveTracts::SaveStreamlinesAsPolyData(char *filename,                                                                char *name)
{
  this->SaveStreamlinesAsPolyData(filename, name, NULL);
}


// NOTE: Limit currently is 1000 models (1000 different input colors is max).
//----------------------------------------------------------------------------
void vtkSaveTracts::SaveStreamlinesAsPolyData(char *filename,
                                              char *name,
                                              vtkMrmlTree *colorTree)
{

  vtkCollection *currStreamlines;
  vtkCollection *currTubeFilters;
  vtkHyperStreamline *currStreamline;
  vtkTubeFilter2 *currTubeFilter;
  vtkCollection *collectionOfModels;
  vtkAppendPolyData *currAppender;
  vtkPolyDataWriter *writer;
  vtkTransformPolyDataFilter *currTransformer;
  vtkTransform *currTransform;
  unsigned char *R, *G, *B;
  int arraySize=1000;
//  int lastColor, newColor;
  int currColor, idx, found;
  vtkFloatingPointType rgb_vtk_float[3];
  unsigned char rgb[3];
  std::stringstream fileNameStr;
  vtkMrmlTree *tree;
  vtkMrmlModelNode *currNode;
  vtkMrmlColorNode *currColorNode;
  std::stringstream colorNameStr;
  vtkMrmlTree *colorTreeTwo;
  vtkTransformPolyDataFilter *currBackTransform;

  // Test that we have required input
  if (this->Streamlines == 0) 
    {
      vtkErrorMacro("You need to set the Streamlines before saving tracts.");
      return;
    }
  if (this->TubeFilters == 0) 
    {
      vtkErrorMacro("You need to set the TubeFilters before saving tracts.");
      return;
    }

  if (this->Display == 0) 
    {
      vtkErrorMacro("You need to set the Display controller before saving tracts.");
      return;
    }



  // If saving for analysis need to have tensors to save
  if (this->SaveForAnalysis) 
    {
      if (this->InputTensorField == 0) 
        {      
          vtkErrorMacro("You need to set the InputTensorField when using SaveForAnalysis.");
          return;
        }
    }


  // init things with the first streamline.
  collectionOfModels = vtkCollection::New();

  vtkDebugMacro( << "Create colorTable that maps colors to group index and fiber index");
  std::map<std::vector<unsigned char>,vtkIntArray *> colorTable;
  std::map<std::vector<unsigned char>,vtkIntArray *>::iterator iter;
  std::vector<unsigned char> rgbvec(3);
  vtkIntArray *indexArray;

  for (int k=0; k<this->Streamlines->GetNumberOfItems(); k++)
    {
    currStreamlines = (vtkCollection *) this->Streamlines->GetItemAsObject(k);  
    for (int j=0; j< currStreamlines->GetNumberOfItems(); j++)
      {  
       currStreamline =(vtkHyperStreamline *) (currStreamlines->GetItemAsObject(j));
       this->Display->GetStreamlineRGBInGroup(currStreamline,k,rgb);
       rgbvec[0]=rgb[0];
       rgbvec[1]=rgb[1];
       rgbvec[2]=rgb[2];
       iter= colorTable.find(rgbvec);
       if (iter == colorTable.end()) 
         {
          //Create new entry in the table
          indexArray = vtkIntArray::New();
          indexArray->SetNumberOfComponents(2);
          colorTable[rgbvec] = indexArray;
          //Add data to array: group index, indexInGroup
          indexArray->InsertNextTuple2(k,j);  
         }
       else 
         {
          indexArray = static_cast<vtkIntArray *> ((*iter).second);
          indexArray->InsertNextTuple2(k,j);
         }
      }
    }

  // Get number of colors and initialize R,G,B arrays
  int numColors=0;
  for (iter = colorTable.begin(); iter != colorTable.end();iter++)
    numColors++;

  R = new unsigned char [numColors];
  G = new unsigned char [numColors];
  B = new unsigned char [numColors];

  vtkDebugMacro( << "Traverse STREAMLINES" );
  // loop throug each color in the color table
  int groupIndex,indexInGroup;
  currColor = 0;
  for (iter = colorTable.begin(); iter != colorTable.end();iter++) 
    {
     //rgbvec = static_cast<std::vector<unsigned char>> (iter->first);
     rgbvec = iter->first;
     indexArray = static_cast<vtkIntArray *> (iter->second);
     //this is a new color, we must create a new model to save.
     // add an appender to the collection of models.
     currAppender = vtkAppendPolyData::New();
     collectionOfModels->AddItem((vtkObject *)currAppender);
     // save this color's info in the array
     R[currColor]=rgbvec[0];
     G[currColor]=rgbvec[1];
     B[currColor]=rgbvec[2];
     currColor++;
     for (int k = 0; k<indexArray->GetNumberOfTuples(); k++)
       {
       groupIndex= (int) indexArray->GetComponent(k,0);
       indexInGroup= (int) indexArray->GetComponent(k,1);
       currStreamlines = (vtkCollection *) this->Streamlines->GetItemAsObject(groupIndex);
       currStreamline = (vtkHyperStreamline *) (currStreamlines->GetItemAsObject(indexInGroup));
       currTubeFilters = (vtkCollection *) this->TubeFilters->GetItemAsObject(groupIndex);
       currTubeFilter = (vtkTubeFilter2 *) (currTubeFilters->GetItemAsObject(indexInGroup));
       // Append this streamline to the chosen model using the appender
       if (this->SaveForAnalysis) {
         currAppender->AddInput(currStreamline->GetOutput());
         } 
       else {
         currAppender->AddInput(currTubeFilter->GetOutput());  
         }      
       }
     }
  
  // traverse appender collection (collectionOfModels) and write each to disk
  vtkDebugMacro( << "Traverse APPENDERS");
  writer = vtkPolyDataWriter::New();
  tree = vtkMrmlTree::New();
  // object to hold any new colors we encounter (not on input color tree)
  colorTreeTwo = vtkMrmlTree::New();

  collectionOfModels->InitTraversal();
  currAppender = (vtkAppendPolyData *) 
    collectionOfModels->GetNextItemAsObject();
  idx=0;

  // Create transformation matrix for writing paths.
  currTransform=vtkTransform::New();
  switch (this->OutputCoordinateSystem) 
    {
    case 1:
      // World (RAS plus any applied slicer matrices) coords
      // This was used to place actors in scene.
      // (scaled IJK to world)
      currTransform->SetMatrix(this->WorldToTensorScaledIJK->GetMatrix());
      currTransform->Inverse();        
      break;
    case 2:
      // Scaled IJK coordinate system
      // Do nothing, leaving the currTransform as the identity matrix
      break;
    case 3:
      // CenteredScaledIJK
      // Here we need to translate so the origin is in the center
      // of the original tensor volume's cube.
      float translation[3];
      translation[0] = this->ExtentForCenteredScaledIJK[1]
        - this->ExtentForCenteredScaledIJK[0];
      translation[1] = this->ExtentForCenteredScaledIJK[3]
        - this->ExtentForCenteredScaledIJK[2];
      translation[2] = this->ExtentForCenteredScaledIJK[5]
        - this->ExtentForCenteredScaledIJK[4];
      translation[0] = translation[0]*this->ScalingForCenteredScaledIJK[0]*.5;
      translation[1] = translation[1]*this->ScalingForCenteredScaledIJK[1]*.5;
      translation[2] = translation[2]*this->ScalingForCenteredScaledIJK[2]*.5;
      currTransform->Translate(-translation[0],-translation[1],
                               -translation[2]);
      break;
    }
  vtkPolyData *writerInput;
  currBackTransform = vtkTransformPolyDataFilter::New();  
  while(currAppender)
    {
      vtkDebugMacro( << idx );
      //Transform tubes back from World to ScaledIjk
      //Now tubes live in World space.
      
      if (!this->SaveForAnalysis) {       
         currBackTransform->SetInput(currAppender->GetOutput());
         currBackTransform->SetTransform(this->WorldToTensorScaledIJK);
         currBackTransform->Update();
             writerInput = currBackTransform->GetOutput();
       } else {
         writerInput = currAppender->GetOutput();
       }

      if (this->SaveForAnalysis) {
        // First find the tensors that correspond to each point on the paths.
        // Note the paths are still in the scaled IJK coordinate system
        // so the probing makes sense.
        vtkProbeFilter *probe = vtkProbeFilter::New();
        probe->SetSource(this->InputTensorField);
        probe->SetInput(writerInput);
        vtkDebugMacro("Probing tensors");
        probe->Update();


        // Next transform models so that they are written in the coordinate
        // system in which they are displayed. (world coordinates, RAS + transforms)
        currTransformer = vtkTransformPolyDataFilter::New();
        currTransformer->SetTransform(currTransform);
        currTransformer->SetInput(probe->GetPolyDataOutput());
        vtkDebugMacro("Transforming PolyData");
        currTransformer->Update();
        
        // Here we rotate the tensors into the same (world) coordinate system.
        // -------------------------------------------------
        vtkDebugMacro("Rotating tensors");
        int numPts = probe->GetPolyDataOutput()->GetNumberOfPoints();
        vtkFloatArray *newTensors = vtkFloatArray::New();
        newTensors->SetNumberOfComponents(9);
        newTensors->Allocate(9*numPts);
        
        vtkDebugMacro("Rotating tensors: init");
        double (*matrix)[4] = this->TensorRotationMatrix->Element;
        double tensor[9];
        double tensor3x3[3][3];
        double temp3x3[3][3];
        double matrix3x3[3][3];
        double matrixTranspose3x3[3][3];
        for (int row = 0; row < 3; row++)
          {
            for (int col = 0; col < 3; col++)
              {
                matrix3x3[row][col] = matrix[row][col];
                matrixTranspose3x3[row][col] = matrix[col][row];
              }
          }
        
        vtkDebugMacro("Rotating tensors: get tensors from probe");        
        vtkDataArray *oldTensors = probe->GetOutput()->GetPointData()->GetTensors();
        
        vtkDebugMacro("Rotating tensors: rotate");
        for (vtkIdType i = 0; i < numPts; i++)
          {
            oldTensors->GetTuple(i,tensor);
            int idx = 0;
            for (int row = 0; row < 3; row++)
              {
                for (int col = 0; col < 3; col++)
                  {
                    tensor3x3[row][col] = tensor[idx];
                    idx++;
                  }
              }          
            // rotate by our matrix
            // R T R'
            vtkMath::Multiply3x3(matrix3x3,tensor3x3,temp3x3);
            vtkMath::Multiply3x3(temp3x3,matrixTranspose3x3,tensor3x3);
            
            idx =0;
            for (int row = 0; row < 3; row++)
              {
                for (int col = 0; col < 3; col++)
                  {
                    tensor[idx] = tensor3x3[row][col];
                    idx++;
                  }
              }  
            newTensors->InsertNextTuple(tensor);
          }
        
        vtkDebugMacro("Rotating tensors: add to new pd");
        vtkPolyData *data = vtkPolyData::New();
        data->SetLines(currTransformer->GetOutput()->GetLines());
        data->SetPoints(currTransformer->GetOutput()->GetPoints());
        data->GetPointData()->SetTensors(newTensors);
        vtkDebugMacro("Done rotating tensors");
        // End of tensor rotation code.
        // -------------------------------------------------
        
        writer->SetInput(data);
        probe->Delete();

        // Write as ASCII for easier reading into matlab
        writer->SetFileTypeToASCII();

      }
      else {
        // Else we are saving just the output tube
        // Next transform models so that they are written in the coordinate
        // system in which they are displayed. (world coordinates, RAS + transforms)
        currTransformer = vtkTransformPolyDataFilter::New();
        currTransformer->SetTransform(currTransform);
        currTransformer->SetInput(writerInput);
        currTransformer->Update();

        writer->SetInput(currTransformer->GetOutput());

        // Write as binary
        writer->SetFileTypeToBinary();

      }


      // Check for scalars
      int ScalarVisibility = 0;
      double range[2];
      if (writer->GetInput()->GetPointData()->GetScalars()) {
        ScalarVisibility = 1;
        writer->GetInput()->GetPointData()->GetScalars()->GetRange(range);
      }

      // clear the buffer (set to empty string)
      fileNameStr.str("");
      fileNameStr << filename << '_' << idx << ".vtk";
      writer->SetFileName(fileNameStr.str().c_str());
      writer->Write();
      currTransformer->Delete();

      // Delete it (but it survives until the collection it's on is deleted).
      currAppender->Delete();

      // Also write a MRML file: add to MRML tree
      currNode=vtkMrmlModelNode::New();
      currNode->SetFullFileName(fileNameStr.str().c_str());
      currNode->SetFileName(fileNameStr.str().c_str());
      // use the name argument to name the model (name label in slicer GUI)
      fileNameStr.str("");
      fileNameStr << name << '_' << idx;
      currNode->SetName(fileNameStr.str().c_str());
      currNode->SetDescription("Model of a DTMRI tract");


      if (ScalarVisibility) {
        currNode->ScalarVisibilityOn();
        currNode->SetScalarRange(range);
      }
      currNode->ClippingOn();


      // Find the name of the color if it's on the input color tree.
      found = 0;
      if (colorTree)
        {
          colorTree->InitTraversal();
          currColorNode = (vtkMrmlColorNode *) colorTree->GetNextItemAsObject();
          while (currColorNode)
            {
              currColorNode->GetDiffuseColor(rgb_vtk_float);
              if (rgb_vtk_float[0]==R[idx] &&
                  rgb_vtk_float[1]==G[idx] &&
                  rgb_vtk_float[2]==B[idx])              
                {
                  found = 1;
                  currNode->SetColor(currColorNode->GetName());
                  break;
                }
              currColorNode = (vtkMrmlColorNode *) 
                colorTree->GetNextItemAsObject();
            }
        }

      // If we didn't find the color on the input color tree, 
      // make a node for it then put it onto the new color tree.
      if (found == 0) 
        {
          currColorNode = vtkMrmlColorNode::New();
          rgb_vtk_float[0] = ((float) R[idx])/255.0;
          rgb_vtk_float[1] = ((float) G[idx])/255.0;
          rgb_vtk_float[2] = ((float) B[idx])/255.0;
          currColorNode->SetDiffuseColor(rgb_vtk_float);
          colorNameStr.str("");
          colorNameStr << "class_" << idx ;
          currColorNode->SetName(colorNameStr.str().c_str());
          currNode->SetColor(currColorNode->GetName());
          // add it to the MRML tree with new colors
          colorTreeTwo->AddItem(currColorNode);
          // call Delete to decrement the reference count
          // so that when we delete the tree the nodes delete too.
          currColorNode->Delete();
        }

      // add it to the MRML file
      tree->AddItem(currNode);

      currAppender = (vtkAppendPolyData *) 
        collectionOfModels->GetNextItemAsObject();
      idx++;
    } 

  // If we had color inputs put them at the end of the MRML file
  if (colorTree)
    {
      colorTree->InitTraversal();
      currColorNode = (vtkMrmlColorNode *) colorTree->GetNextItemAsObject();      
      while (currColorNode)
        {
          tree->AddItem(currColorNode);
          currColorNode = (vtkMrmlColorNode *) 
            colorTree->GetNextItemAsObject();
        }
    }
  // Also add any new colors we found
  colorTreeTwo->InitTraversal();
  currColorNode = (vtkMrmlColorNode *) colorTreeTwo->GetNextItemAsObject();      
  while (currColorNode)
    {
      tree->AddItem(currColorNode);
      currColorNode = (vtkMrmlColorNode *) 
        colorTreeTwo->GetNextItemAsObject();
    }
  
  // Write the MRML filef_
  fileNameStr.str("");
  fileNameStr << filename << ".xml";
  tree->Write((char *)fileNameStr.str().c_str());

  vtkDebugMacro( << "DELETING objects");

  // Delete all objects we created
  currBackTransform->Delete();
  collectionOfModels->Delete();
  writer->Delete();
  tree->Delete();
  colorTreeTwo->Delete();
  currTransform->Delete();

  // Delete R,G,B arrays
  delete [] R;
  delete [] G;
  delete [] B;

  // Delete vtkIntArrays in color table
  for (iter = colorTable.begin(); iter != colorTable.end();iter++) {
    indexArray = static_cast<vtkIntArray *> (iter->second);
    indexArray->Delete();
  }

  vtkDebugMacro( << "Done.");
}







