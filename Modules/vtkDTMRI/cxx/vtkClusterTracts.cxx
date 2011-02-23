/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkClusterTracts.cxx,v $
  Date:      $Date: 2006/03/06 21:07:29 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#include "vtkClusterTracts.h"

// for vtk objects we use here
#include "vtkObjectFactory.h"
#include "vtkCollection.h"

// classes for tract clustering
#include "vtkTractShapeFeatures.h"

// itk object for exception handling
#include "itkExceptionObject.h"


vtkCxxRevisionMacro(vtkClusterTracts, "$Revision: 1.10 $");
vtkStandardNewMacro(vtkClusterTracts);

vtkCxxSetObjectMacro(vtkClusterTracts, InputStreamlines, vtkCollection);

vtkClusterTracts::vtkClusterTracts()
{
  this->ClusteringAlgorithm = itk::SpectralClustering::New();
  this->TractAffinityCalculator = vtkTractShapeFeatures::New();

  this->InputStreamlines = NULL;
  this->OutputClusterLabels = NULL;
}

vtkClusterTracts::~vtkClusterTracts()
{
  //this->ClusteringAlgorithm->Delete();
  this->TractAffinityCalculator->Delete();
  if (this->InputStreamlines)
    this->InputStreamlines->Delete();
  if (this->OutputClusterLabels)
    this->OutputClusterLabels->Delete();
}


void vtkClusterTracts::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);

  this->ClusteringAlgorithm->Print( std::cout );
  this->TractAffinityCalculator->PrintSelf(os,indent);
  if (this->InputStreamlines)
    this->InputStreamlines->PrintSelf(os,indent);
  if (this->OutputClusterLabels)
    this->OutputClusterLabels->PrintSelf(os,indent);
}

void vtkClusterTracts::ComputeClusters()
{

  vtkDebugMacro("Updating...");

  // Error checking:
  // test we have a streamline collection.
  if (this->InputStreamlines == NULL)
    {
      vtkErrorMacro("The InputStreamlines collection must be set first.");
      return;      
    }

  // Error checking:
  // Make sure we have at least twice as many streamlines as the number of
  // eigenvectors we are using (really we need at least one more than
  // this number to manage to calculate the eigenvectors, but double
  // is more reasonable).
  if (this->InputStreamlines->GetNumberOfItems() <  2*(this->ClusteringAlgorithm->GetNumberOfEigenvectors()))
    {
      vtkErrorMacro("At least " << 
                    2*this->ClusteringAlgorithm->GetNumberOfEigenvectors()  
                    << " tract paths are needed for clustering");
      return;      

    }    

  // Make sure the clustering algorithm thinks it has been modified.
  // We want it to execute every time since the k-means initialization
  // is random. So there should be a new result every time clustering is run.
  this->ClusteringAlgorithm->Modified();

  // Set the parameters from the user
  this->ClusteringAlgorithm->SetNumberOfClusters(this->NumberOfClusters);
  this->ClusteringAlgorithm->SetNumberOfEigenvectors(this->NumberOfEigenvectors);


  // Set up the pipelines and run them
  this->TractAffinityCalculator->SetInputStreamlines(this->InputStreamlines);

  vtkDebugMacro("Computing affinity matrix");
  try {
    this->TractAffinityCalculator->ComputeFeatures();
  }
  catch (itk::ExceptionObject &e) {
    vtkErrorMacro("Error in vtkTractShapeFeatures->ComputeFeatures: " << e);
    return;
  }
  catch (...) {
    vtkErrorMacro("Error in vtkTractShapeFeatures:ComputeFeatures");
    return;
  }

  cout << "affinity matrix rows: " << this->TractAffinityCalculator->GetOutputSimilarityMatrix()->Rows() << std::endl;

  cout << "affinity matrix cols: " << this->TractAffinityCalculator->GetOutputSimilarityMatrix()->Cols() << std::endl;

  this->ClusteringAlgorithm->SetInput(*(this->TractAffinityCalculator->GetOutputSimilarityMatrix()));

  vtkDebugMacro("Computing clusters");
  try {
    this->ClusteringAlgorithm->Update();
  }
  catch (itk::ExceptionObject &e) {
    vtkErrorMacro("Error in itkSpectralClustering->ComputeClusters: " << e);
    return;
  }
  catch (...) {
    vtkErrorMacro("Error in itkSpectralClustering:ComputeClusters");
    return;
  }


  // copy the cluster labels into our vtk format (hide itk objects
  // within this class)

  itk::AffinityClustering::OutputType output = this->ClusteringAlgorithm->GetOutputClusters();

  if (this->OutputClusterLabels)
    this->OutputClusterLabels->Delete();
  this->OutputClusterLabels = vtkUnsignedIntArray::New();
  
  this->OutputClusterLabels->SetNumberOfValues(this->InputStreamlines->GetNumberOfItems());

  std::cout << "output size: " << output.Size() << std::endl;

  for (int row = 0; row < this->InputStreamlines->GetNumberOfItems(); row++)
    {
      this->OutputClusterLabels->SetValue(row,output[row]);
      std::cout <<"index = " << row << "   class label = " << output[row] << std::endl;
    }

}
