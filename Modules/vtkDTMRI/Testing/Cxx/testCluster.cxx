//
// testITKCluster.cxx: Test code for itkSpectralClustering class.
// 
// Creates ideal sample input and runs clustering.
// Produces 3 text files:
//   inputClusters.txt   (input cluster indices)
//   inputMatrix.txt   (input similarity matrix)
//   embed.txt           (embedding vectors)
//   outputClusters.txt  (output cluster indices)
// Also outputs the normalized weight matrix as an image.
//
// (There is one bug, I can't find the image output on windows.
// Apparently it is not written to the directory where I run the file.)
//

#include <fstream>
#include <iostream>
#include "itkSpectralClustering.h"

int main(int argc, char* argv[])
{

  if(argc == 0)
    {
      std::cout << "Usage: testCluster <infile> <outfile> <# Clusters>" << std::endl;
      return 0;
    }

  // create input test data
  // -----------------------
  // number of things to cluster
  int numberOfItemsToCluster = 21;

  typedef itk::SpectralClustering::AffinityMatrixType AffinityMatrixType;
  AffinityMatrixType affinityMatrix;
  affinityMatrix.SetSize( numberOfItemsToCluster, numberOfItemsToCluster );


  // now make a simulated perfect input list (matrix), block diagonal
  // within-cluster similarity = 1 and all other entries = 0;

  int numberOfClusters = 3;
  int numberOfEigenvectors = 2;
  int clusterSize = numberOfItemsToCluster/numberOfClusters;
  int clusterIdx = 1;
  std::ofstream fileInputClusters;
  fileInputClusters.open("inputClusters.txt");
  std::ofstream fileInputMatrix;
  fileInputMatrix.open("inputMatrix.txt");

  for (int row = 0; row < numberOfItemsToCluster; row++)
    {
      if (row == clusterIdx*clusterSize)
        clusterIdx++;

      // output cluster indices to disk
      fileInputClusters << clusterIdx << std::endl;


      for (int col = 0; col < numberOfItemsToCluster; col++)
        {
          affinityMatrix(row,col) = 0;
          if (col < clusterIdx*clusterSize && col >= (clusterIdx-1)*clusterSize)
            {
              affinityMatrix(row,col) = 1;
            }

          affinityMatrix(row,col) = affinityMatrix(row,col) + 0.1;

          // output matrix values to disk
          fileInputMatrix << affinityMatrix(row,col) << " ";
        }

      // output matrix values to disk (newline at end of row)
      fileInputMatrix << std::endl;

    }
  fileInputClusters.close();
  fileInputMatrix.close();



  // Now create the cluster-er and set its input
  // -----------------------
  itk::SpectralClustering::Pointer spectralCluster = itk::SpectralClustering::New();
  spectralCluster->DebugOn();

  spectralCluster->SetInput( affinityMatrix );
  spectralCluster->SetNumberOfClusters(numberOfClusters);
  spectralCluster->SetNumberOfEigenvectors(numberOfEigenvectors);

  // For debug/test, this outputs the embedding vectors in a file (embed.txt)
  spectralCluster->SaveEmbeddingVectorsOn();
  spectralCluster->SaveEigenvectorsOn();

  spectralCluster->SetEmbeddingNormalizationToNone();


  // Run it
  // -----------------------
  spectralCluster->Update();


  // Now print/save the input and output
  // -----------------------
  spectralCluster->Print( std::cout );
  std::cout << spectralCluster->GetInput()->Get() << std::endl;
  std::cout << spectralCluster->GetOutputClusters() << std::endl;
  itk::SpectralClustering::OutputType output = spectralCluster->GetOutputClusters();

  std::ofstream fileOutputClusters;
  fileOutputClusters.open("outputClusters.txt");

  for (int row = 0; row < numberOfItemsToCluster; row++)
    {
      std::cout <<"index = " << row << "   class label = " << output[row] << std::endl;
      fileOutputClusters << output[row] << std::endl;
    }
  fileOutputClusters.close();

  return 0;
}
