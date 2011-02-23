/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkClusterTracts.h,v $
  Date:      $Date: 2006/01/06 17:57:24 $
  Version:   $Revision: 1.6 $

=========================================================================auto=*/
// .NAME vtkClusterTracts - Cluster paths obtained through tractography.

// .SECTION Description
// Wrapper around the classes vtkTractShapeFeatures and itkSpectralClustering
// Outputs class labels from clustering input tract paths.

// .SECTION See Also
// vtkTractShapeFeatures itkSpectralClustering 

#ifndef __vtkClusterTracts_h
#define __vtkClusterTracts_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "itkSpectralClustering.h"
#include "vtkTractShapeFeatures.h"
#include "vtkUnsignedIntArray.h"

// Forward declarations to avoid including header files here.
// Goes along with use of new vtkCxxSetObjectMacro
class vtkCollection;


class VTK_DTMRI_EXPORT vtkClusterTracts : public vtkObject
{
 public:
  // Description
  // Construct
  static vtkClusterTracts *New();

  vtkTypeRevisionMacro(vtkClusterTracts,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  //BTX
  typedef vtkUnsignedIntArray OutputType;
  //ETX

  // Description
  // User interface parameter to itk clustering class:
  // Number of output clusters
  vtkSetMacro(NumberOfClusters,unsigned int);
  vtkGetMacro(NumberOfClusters,unsigned int);

  // Description
  // User interface parameter to itk clustering class:
  // Number of eigenvectors to use in embedding
  vtkSetMacro(NumberOfEigenvectors,unsigned int);
  vtkGetMacro(NumberOfEigenvectors,unsigned int);

  // Description
  // User interface parameter to itk clustering class:
  // Type of normalization of embedding vectors
  int GetEmbeddingNormalization()
    {
      return this->ClusteringAlgorithm->GetEmbeddingNormalization();
    }

  // Description
  // User interface parameter to itk clustering class:
  // Type of normalization of embedding vectors:
  // Normalized cuts normalization of embedding vectors
  void SetEmbeddingNormalizationToRowSum()
    {
      this->ClusteringAlgorithm->SetEmbeddingNormalizationToRowSum();
    };

  // Description
  // User interface parameter to itk clustering class:
  // Type of normalization of embedding vectors:
  // Spectral clustering normalization of embedding vectors
  void SetEmbeddingNormalizationToLengthOne()
    {
      this->ClusteringAlgorithm->SetEmbeddingNormalizationToLengthOne();
    };

  // Description
  // User interface parameter to itk clustering class:
  // Type of normalization of embedding vectors:
  // No normalization of embedding vectors 
  void SetEmbeddingNormalizationToNone()
    {
      this->ClusteringAlgorithm->SetEmbeddingNormalizationToNone();
    };

  // Description
  // Set/Get input to this class: a collection of vtkHyperStreamlinePoints
  virtual void SetInputStreamlines(vtkCollection*);
  vtkGetObjectMacro(InputStreamlines, vtkCollection);


  // Description
  // For direct access to the tract affinity matrix calculation class,
  // to set parameters from the user interface.
  vtkGetObjectMacro(TractAffinityCalculator, vtkTractShapeFeatures);

  // Description
  // Compute the output. Call this before requesting the output.
  void ComputeClusters();


  // Description
  // This gives a list in which each input tract is assigned a class.
  // If there is an error in computation or ComputeClusters has not been
  // called, this will return a NULL pointer.
  vtkGetObjectMacro(OutputClusterLabels,vtkUnsignedIntArray);
  vtkUnsignedIntArray *GetOutput()
    {
      return(this->GetOutputClusterLabels());
    }

 protected:
  vtkClusterTracts();
  ~vtkClusterTracts();

  vtkCollection *InputStreamlines;

  //BTX
  // It is important to use the special pointer or the
  // object will delete itself.
  itk::SpectralClustering::Pointer ClusteringAlgorithm;
  //ETX

  vtkTractShapeFeatures *TractAffinityCalculator;

  vtkUnsignedIntArray *OutputClusterLabels;

  unsigned int NumberOfClusters;
  unsigned int NumberOfEigenvectors;
  int          EmbeddingNormalization;

 private:
  vtkClusterTracts(const vtkClusterTracts&); // Not implemented.
  void operator=(const vtkClusterTracts&); // Not implemented.
};

#endif

