/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkTractShapeFeatures.h,v $
  Date:      $Date: 2006/02/10 03:44:49 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkTractShapeFeatures - Compute tract similarity matrix for clustering

// .SECTION Description
// Takes as input a collection of N tracts (vtkHyperStreamlineDTMRI objects). 
// Compares them, and outputs an NxN weight matrix for clustering.
// The same matrix is output also as an image for visualization.

// .SECTION See Also
// vtkClusterTracts vtkNormalizedCuts 

#ifndef __vtkTractShapeFeatures_h
#define __vtkTractShapeFeatures_h

#include "vtkDTMRIConfigure.h"
#include "vtkObject.h"
#include "itkListSample.h"
#include "itkVariableSizeMatrix.h"

// Forward declarations to avoid including header files here.
// Goes along with use of new vtkCxxSetObjectMacro
class vtkCollection;
class vtkImageData;
class vtkHyperStreamlineDTMRI;

class VTK_DTMRI_EXPORT vtkTractShapeFeatures : public vtkObject
{
 public:
  // Description
  // Construct
  static vtkTractShapeFeatures *New();

  vtkTypeRevisionMacro(vtkTractShapeFeatures,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);


  // Description
  // Compute the output
  void ComputeFeatures();

  // Description
  // Set/Get input to this class
  virtual void SetInputStreamlines(vtkCollection*);
  vtkGetObjectMacro(InputStreamlines, vtkCollection);

  // Description
  // Set sigma of gaussian kernel for tract comparison
  vtkSetMacro(Sigma,double);
  vtkGetMacro(Sigma,double);

  // Description
  // For Hausdorff variants only.  Use every Nth point on the tract path for 
  // comparison. 
  vtkSetClampMacro(HausdorffN,int,1,100);
  vtkGetMacro(HausdorffN,int);

  // Description
  // How to symmetrize distances (Hausdorff-based): mas, mean, min
  vtkSetMacro(SymmetrizeMethod,int);
  vtkGetMacro(SymmetrizeMethod,int);
  void SetSymmetrizeMethodToMean() {this->SetSymmetrizeMethod(1);}
  void SetSymmetrizeMethodToMin() {this->SetSymmetrizeMethod(2);}
  void SetSymmetrizeMethodToMax() {this->SetSymmetrizeMethod(3);}
  
  //BTX
  // (wrapping doesn't work here so exclude this with BTX)
  // Description
  // Use the matrix format provided by ITK for the output distance
  // and similarity matrices
  typedef double AffinityMatrixValueType;
  typedef itk::VariableSizeMatrix< AffinityMatrixValueType > OutputType;

  // Description
  // Returns the output distance matrix after computation
  OutputType * GetOutputDistanceMatrix() 
    {
      return &m_InterTractDistanceMatrix;
    };

  // Description
  // Returns the output similarity/weight matrix after computation
  OutputType * GetOutputSimilarityMatrix() 
    {
      return &m_InterTractSimilarityMatrix;
    };
  //ETX

  // Description
  // Get the images which contain the matrices above (for visualization)
  vtkImageData *GetInterTractDistanceMatrixImage();
  vtkImageData *GetInterTractSimilarityMatrixImage();

  void SetFeatureTypeToHausdorff()
    {
      this->SetFeatureType(HAUSDORFF);
    };
  void SetFeatureTypeToMeanClosestPoint()
    {
      this->SetFeatureType(MEAN_CLOSEST_POINT);
    };
  void SetFeatureTypeToMeanAndCovariance()
    {
      this->SetFeatureType(MEAN_AND_COVARIANCE);
    };
  void SetFeatureTypeToEndPoints()
    {
      this->SetFeatureType(ENDPOINTS);
    };
  vtkGetMacro(FeatureType,int);

  // Description
  // Make a vtk image to visualize contents of a vnl matrix
  vtkImageData * ConvertVNLMatrixToVTKImage(OutputType *matrix, vtkImageData *image);

 protected:
  vtkTractShapeFeatures();
  ~vtkTractShapeFeatures();

  vtkCollection *InputStreamlines;
  double Sigma;
  int HausdorffN;
  int SymmetrizeMethod;

  vtkImageData *InterTractDistanceMatrixImage;
  vtkImageData *InterTractSimilarityMatrixImage;

  void ComputeFeaturesMeanAndCovariance();
  void ComputeFeaturesHausdorff();
  void ComputeFeaturesEndPoints();
  
  //BTX
  enum ShapeFeatureType { MEAN_AND_COVARIANCE, HAUSDORFF, ENDPOINTS, MEAN_CLOSEST_POINT} ;
  //ETX
  int FeatureType;
  vtkSetMacro(FeatureType,int);


  //BTX
  // ITK typedefs
  // x,y,z points on tract paths are 3-vectors
  typedef itk::Vector< double, 3 > XYZVectorType;
  // list of all points on a tract path
  typedef itk::Statistics::ListSample< XYZVectorType > TractPointsListType;

  OutputType m_InterTractDistanceMatrix;
  OutputType m_InterTractSimilarityMatrix;

  void GetPointsFromHyperStreamlinePointsSubclass(TractPointsListType::Pointer sample, vtkHyperStreamlineDTMRI *currStreamline);
  //ETX

 private:
  vtkTractShapeFeatures(const vtkTractShapeFeatures&); // Not implemented.
  void operator=(const vtkTractShapeFeatures&); // Not implemented.
};

#endif

