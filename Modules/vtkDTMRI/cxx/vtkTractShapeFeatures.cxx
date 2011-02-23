/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkTractShapeFeatures.cxx,v $
  Date:      $Date: 2007/03/13 21:47:08 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// for vtk objects we use here
#include "vtkHyperStreamlineDTMRI.h"
#include "vtkCollection.h"
#include "vtkObjectFactory.h"
#include "vtkPolyData.h"
#include "vtkPointData.h"
#include "vtkFloatArray.h"
#include "vtkCell.h"

#include "vtkTractShapeFeatures.h"


// ITK for tract feature computations
#include "itkListSample.h"
#include "itkCovarianceCalculator.h"
#include "itkVector.h"
#include "itkEuclideanDistance.h"
#include "itkSymmetricEigenAnalysis.h"

// for debug output of features
#include "vtkImageData.h"

vtkCxxRevisionMacro(vtkTractShapeFeatures, "$Revision: 1.18 $");
vtkStandardNewMacro(vtkTractShapeFeatures);

vtkCxxSetObjectMacro(vtkTractShapeFeatures, InputStreamlines, vtkCollection);


vtkTractShapeFeatures::vtkTractShapeFeatures()
{
  this->InputStreamlines = NULL;
  this->InterTractDistanceMatrixImage = NULL;
  this->InterTractSimilarityMatrixImage = NULL;

  this->Sigma = 100;

  this->FeatureType = MEAN_AND_COVARIANCE;

  this->HausdorffN = 10;

  this->SymmetrizeMethod = 1;
}

vtkTractShapeFeatures::~vtkTractShapeFeatures()
{
  if (this->InputStreamlines)
    this->InputStreamlines->Delete();

}

void vtkTractShapeFeatures::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
  os << indent << "Sigma: " << this->Sigma << "\n";

}

vtkImageData * vtkTractShapeFeatures::GetInterTractSimilarityMatrixImage()
{
  return (this->ConvertVNLMatrixToVTKImage(&m_InterTractSimilarityMatrix,this->InterTractSimilarityMatrixImage));
}

vtkImageData * vtkTractShapeFeatures::GetInterTractDistanceMatrixImage()
{
  return (this->ConvertVNLMatrixToVTKImage(&m_InterTractDistanceMatrix,this->InterTractDistanceMatrixImage));
}

vtkImageData * vtkTractShapeFeatures::ConvertVNLMatrixToVTKImage(OutputType *matrix, vtkImageData *image)
{
  // If the image hasn't been created, create it
  if (image == NULL)
    {
      image = vtkImageData::New();

      if (matrix != NULL)
        {
          int rows = matrix->Rows();
          int cols = matrix->Cols();
          image->SetDimensions(cols,rows,1);
          image->SetScalarTypeToDouble();
          image->AllocateScalars();
          double *imageArray = (double *) image->GetScalarPointer();
      
          for (int idx1 = rows-1; idx1 >= 0; idx1--)
            {
              for (int idx2 = 0; idx2 < cols; idx2++)
                {
                  *imageArray = (*matrix)[idx1][idx2];
                  imageArray++;
                }
            }
        }
    }

  return (image);

}

void vtkTractShapeFeatures::GetPointsFromHyperStreamlinePointsSubclass(TractPointsListType::Pointer sample, vtkHyperStreamlineDTMRI *currStreamline)
{
  XYZVectorType mv;
  vtkPoints *hs0;
  int ptidx, numPts;
  double point[3];

  // clear the contents of the list sample
  sample->Clear();

  // set the measurement vector size
  sample->SetMeasurementVectorSize(3);
  
  hs0 = currStreamline->GetOutput()->GetPoints();
  numPts=hs0->GetNumberOfPoints();
  for (ptidx = 0; ptidx < numPts; ptidx++)
    {
      hs0->GetPoint(ptidx,point);
      mv[0]=point[0];
      mv[1]=point[1];
      mv[2]=point[2];
      sample->PushBack( mv );
    }
}

void vtkTractShapeFeatures::ComputeFeatures()
{
  int N;

  // test we have a streamline collection as input
  if (this->InputStreamlines == NULL)
    {
      vtkErrorMacro("The InputStreamline collection must be set before using this class.");
      return;      
    }
  N = this->InputStreamlines->GetNumberOfItems();

  // Delete any old vtkImageDatas which contain old matrix info
  if (this->InterTractDistanceMatrixImage) 
    {
      this->InterTractDistanceMatrixImage->Delete();
    }
  if (this->InterTractSimilarityMatrixImage) 
    {
      this->InterTractSimilarityMatrixImage->Delete();
    }

  // Set up our output matrices.  Set size and init to 0.
  m_InterTractDistanceMatrix.SetSize(N,N);
  m_InterTractDistanceMatrix.Fill(0);

  m_InterTractSimilarityMatrix.SetSize(N,N);
  m_InterTractSimilarityMatrix.Fill(0);

  switch (this->FeatureType)
    {
    case MEAN_AND_COVARIANCE:
      {
        this->ComputeFeaturesMeanAndCovariance();
        break;
      }
    case HAUSDORFF:
      {
        this->ComputeFeaturesHausdorff();
        break;
      }
    case ENDPOINTS:
      {
        this->ComputeFeaturesEndPoints();
        break;
      }
    case MEAN_CLOSEST_POINT:
      {
        this->ComputeFeaturesHausdorff();
        break;
      }
      
    }
}

void vtkTractShapeFeatures::ComputeFeaturesHausdorff()
{
  vtkHyperStreamlineDTMRI *currStreamline1, *currStreamline2;
  XYZVectorType mv1, mv2;

  int numberOfStreamlines = this->InputStreamlines->GetNumberOfItems();

  // put each tract's points onto a list
  TractPointsListType::Pointer sample1 = TractPointsListType::New();
  TractPointsListType::Pointer sample2 = TractPointsListType::New();

  // get ready to traverse streamline collection.
  // test we have a streamline collection.
  if (this->InputStreamlines == NULL)
    {
      vtkErrorMacro("The InputStreamline collection must be set before using this class.");
      return;      
    }
  
  this->InputStreamlines->InitTraversal();
  // TO DO: make sure this is a vtkHyperStreamlinePoints object
  currStreamline1= (vtkHyperStreamlineDTMRI *)this->InputStreamlines->GetNextItemAsObject();
  
  // test we have streamlines
  if (currStreamline1 == NULL)
    {
      vtkErrorMacro("No streamlines are on the collection.");
      return;      
    }

  vtkDebugMacro( "Traverse STREAMLINES" );
  // double sumSqDist;
  double sumDist, maxMinDist, countDist, minDist, currDist;
  TractPointsListType::InstanceIdentifier count1, count2, increment;
  unsigned int size1, size2;
  increment = this->HausdorffN;
  typedef itk::Statistics::EuclideanDistance< XYZVectorType > 
    DistanceMetricType;
  DistanceMetricType::Pointer distanceMetric = DistanceMetricType::New();

  // compute distances
  for (int i = 0; i < numberOfStreamlines; i++)
    {
      vtkDebugMacro( "Current Streamline: " << i);
      currStreamline1= (vtkHyperStreamlineDTMRI *)
        this->InputStreamlines->GetItemAsObject(i);

      // Get the tract path's points on an itk list sample object
      this->GetPointsFromHyperStreamlinePointsSubclass(sample1, 
                                                       currStreamline1);
      for (int j = 0; j < numberOfStreamlines; j++)
        {
          currStreamline2= (vtkHyperStreamlineDTMRI *)
            this->InputStreamlines->GetItemAsObject(j);

          // Get the tract path's points on an itk list sample object
          this->GetPointsFromHyperStreamlinePointsSubclass(sample2, 
                                                           currStreamline2);

          // Compare the tracts sample1 and sample2 using 
          // "average Hausdorff" distance.

          // vars for computing distance
          sumDist = 0;
          maxMinDist = 0;
          //sumSqDist = 0;
          countDist = 0;

          size1 = sample1->Size();
          count1 = 0;
          while( count1 < size1 )
            {
              // minDist is min dist so far to this point
              minDist=VTK_DOUBLE_MAX;
          
              size2 = sample2->Size();
              count2 = 0;
              while( count2 < size2 )
                {
                  // distance between points
                  currDist = distanceMetric->
                    Evaluate( sample1->GetMeasurementVector(count1), 
                              sample2->GetMeasurementVector(count2) );

                  vtkDebugMacro( "size1 size2 i,j, count1, count2, Dist (min, curr)" << size1 << " " << size2 << " " << sample1->GetMeasurementVector(count1) << " " << sample2->GetMeasurementVector(count2) << " " << i << " " << j << " " << count1 << " " << count2 << " " << minDist << " " << currDist);

                  if (currDist < minDist)
                    minDist=currDist;

                  count2+=increment;
                }

              // accumulate the min dist to this point 
              // (for mean closest point)
              sumDist = sumDist + minDist; 
              // (for testing squared distances)
              //sumSqDist = sumSqDist + minDist*minDist; 

              // find max of min dists so far
              // (for standard hausdorff)
              if (minDist > maxMinDist) {maxMinDist = minDist;}

              countDist++;
              vtkDebugMacro( "sumDist: " << sumDist);
              count1+=increment;
            }

          // Store distance for this pair of tracts.
          double currentDistance = 0; 
          switch (this->FeatureType)
            {
            case HAUSDORFF:
              {
                // normal Hausdorff is the max of the min dists.
                currentDistance = maxMinDist;
                break;
              }
            case MEAN_CLOSEST_POINT:
              {
                // Save "average Hausdorff" (avg of min dists) in matrix.
                currentDistance = sumDist/countDist;
                break;
              }

            }


          switch (this->SymmetrizeMethod) 
            {
            case 1:
              {
                // mean
                // Symmetric distance measure, we use the 
                // average of dist(a->b) and (b->a):
                m_InterTractDistanceMatrix(i,j) += currentDistance/2;
                m_InterTractDistanceMatrix(j,i) += currentDistance/2;
                break;
              }
            case 2:
              {
                // min
                // min of dist(a->b) and (b->a):
                if (m_InterTractDistanceMatrix(i,j) == 0) 
                  {
                    m_InterTractDistanceMatrix(i,j) = currentDistance;
                    m_InterTractDistanceMatrix(j,i) = currentDistance;
                  } 
                else
                  {
                    if (currentDistance < m_InterTractDistanceMatrix(i,j)) 
                      {
                        m_InterTractDistanceMatrix(i,j) = currentDistance;
                        m_InterTractDistanceMatrix(j,i) = currentDistance;
                      }
                  }
                break;
              }
            case 3:
              {
                // max
                // max of dist(a->b) and (b->a):
                if (m_InterTractDistanceMatrix(i,j) == 0) 
                  {
                    m_InterTractDistanceMatrix(i,j) = currentDistance;
                    m_InterTractDistanceMatrix(j,i) = currentDistance;
                  } 
                else
                  {
                    if (currentDistance > m_InterTractDistanceMatrix(i,j)) 
                      {
                        m_InterTractDistanceMatrix(i,j) = currentDistance;
                        m_InterTractDistanceMatrix(j,i) = currentDistance;
                      }
                  }
                break;
              }
            }

        }
    }


  // to convert distances to similarities/weights
  double sigmasq=this->Sigma*this->Sigma;

  // Now create similarity matrix
  for (int idx1 = 0; idx1 < numberOfStreamlines; idx1++)
    {
      for (int idx2 = 0; idx2 < numberOfStreamlines; idx2++)
        {
          // save the similarity in a matrix
          m_InterTractSimilarityMatrix(idx1,idx2) = 
            exp(-(m_InterTractDistanceMatrix(idx1,idx2))/sigmasq);
        }
    }
  vtkDebugMacro( "Hausdorff distances computed." );

}


void vtkTractShapeFeatures::ComputeFeaturesMeanAndCovariance()
{
  vtkHyperStreamlineDTMRI *currStreamline;

  // to calculate covariance of the points
  typedef itk::Statistics::CovarianceCalculator< TractPointsListType > 
    CovarianceAlgorithmType;
  // the features are mean (3 values) + covariance matrix (6 unique values)
  // to make 9 total components in the feature vector
  typedef itk::Vector< double, 9 > FeatureVectorType;
  //typedef itk::Vector< double, 12 > FeatureVectorType;
  typedef itk::Statistics::ListSample< FeatureVectorType > FeatureListType;

  CovarianceAlgorithmType::MeanType mean;
  CovarianceAlgorithmType::OutputType cov;
  CovarianceAlgorithmType::Pointer covarianceAlgorithm = 
    CovarianceAlgorithmType::New();
  FeatureListType::Pointer features = FeatureListType::New();
  FeatureVectorType fv;

  // get ready to traverse streamline collection.
  this->InputStreamlines->InitTraversal();
  // TO DO: make sure this is a vtkHyperStreamlinePoints object
  currStreamline= (vtkHyperStreamlineDTMRI *)this->InputStreamlines->GetNextItemAsObject();
  
  // test we have streamlines
  if (currStreamline == NULL)
    {
      vtkErrorMacro("No streamlines are on the collection.");
      return;      
    }

  vtkDebugMacro( "Traverse STREAMLINES" );

  while(currStreamline)
    {

      // Get the tract path's points on an itk list sample object
      TractPointsListType::Pointer sample = TractPointsListType::New();
      this->GetPointsFromHyperStreamlinePointsSubclass(sample, currStreamline);
      
      vtkDebugMacro("num points: " << sample->Size() );

      // now compute the covariance of all of the points in this sample (tract)
      covarianceAlgorithm->SetInputSample( sample );
      // the covariance algorithm will output the mean and covariance matrix
      covarianceAlgorithm->SetMean( 0 );
      try {
        covarianceAlgorithm->Update();
      }
      catch (itk::ExceptionObject &e) {
        vtkErrorMacro("Error in covariance computation: " << e);
        return;
      }

      vtkDebugMacro( "Mean = " << *(covarianceAlgorithm->GetMean()) );

      vtkDebugMacro( "Covariance = " << *(covarianceAlgorithm->GetOutput()) );
      
      mean = *(covarianceAlgorithm->GetMean());
      cov = *(covarianceAlgorithm->GetOutput());

      // compute the matrix square root of the covariance matrix
      // this makes the units of its eigenvalues mm, instead of mm^2
      // so its entries have the same scaling as the mean values
      // algorithm: diagonalize, take sqrt of eigenvalues, recreate matrix
      // sqrtm(A) = E * sqrt(D) * E' where D is a diagonal matrix.

      typedef CovarianceAlgorithmType::OutputType InputMatrixType;
      typedef itk::FixedArray< double, 3 > EigenValuesArrayType;
      typedef itk::Matrix< double, 3, 3 > EigenVectorMatrixType;
      typedef itk::SymmetricEigenAnalysis< InputMatrixType,  
        EigenValuesArrayType, EigenVectorMatrixType > SymmetricEigenAnalysisType;
      
      // output storage
      EigenValuesArrayType eigenvalues;
      EigenVectorMatrixType eigenvectors;
      
      SymmetricEigenAnalysisType eig(3);
      
      try {
        eig.SetDimension(3);
        eig.ComputeEigenValuesAndVectors(cov,eigenvalues, eigenvectors);
      }
      catch (itk::ExceptionObject &e) {
        vtkErrorMacro("Error in eigensystem computation: " << e);
        return;
      }

      vtkDebugMacro( "Eigenvalues = " << eigenvalues );
      vtkDebugMacro( "Eigenvectors = " << eigenvectors );

      eigenvalues[0] = sqrt(eigenvalues[0]);
      eigenvalues[1] = sqrt(eigenvalues[1]);
      eigenvalues[2] = sqrt(eigenvalues[2]);

      // Normalize for tract length. We want orientation information
      // to not be swamped by length information.  So make the trace
      // of the covariance matrix equal one.
      //double norm;
      //norm = eigenvalues[0]+eigenvalues[1]+eigenvalues[2];
      //eigenvalues[0] = eigenvalues[0]/norm;
      //eigenvalues[1] = eigenvalues[1]/norm;
      //eigenvalues[2] = eigenvalues[2]/norm;

      for (int i = 0; i < 3; i++)
        {
          for (int j = 0; i < 3; i++)
            {
              cov[i][j]=0;
            }
        }
      for (int i = 0; i < 3; i++)
        {
          // sum outer product matrix from each eigenvalue lambda*vv'
          // the ith eigenvector is in column i of the eigenvector matrix
          cov[0][0]=eigenvectors[0][i]*eigenvectors[0][i]*eigenvalues[i];
          cov[0][1]=eigenvectors[0][i]*eigenvectors[1][i]*eigenvalues[i];
          cov[0][2]=eigenvectors[0][i]*eigenvectors[2][i]*eigenvalues[i];

          cov[1][0]=eigenvectors[1][i]*eigenvectors[0][i]*eigenvalues[i];
          cov[1][1]=eigenvectors[1][i]*eigenvectors[1][i]*eigenvalues[i];
          cov[1][2]=eigenvectors[1][i]*eigenvectors[2][i]*eigenvalues[i];

          cov[2][0]=eigenvectors[2][i]*eigenvectors[0][i]*eigenvalues[i];
          cov[2][1]=eigenvectors[2][i]*eigenvectors[1][i]*eigenvalues[i];
          cov[2][2]=eigenvectors[2][i]*eigenvectors[2][i]*eigenvalues[i];
        }
 
      // TEST
      //mean[0]=1;
      //mean[1]=1;
      //mean[2]=1;

      // save the features of mean and covariance on the features list
      // use the lower triangular part of the covariance matrix.
      fv[0]=mean[0];      
      fv[1]=mean[1];      
      fv[2]=mean[2];
      fv[3]=cov[0][0];
      fv[4]=cov[1][0];
      fv[5]=cov[1][1];
      fv[6]=cov[2][0];
      fv[7]=cov[2][1];
      fv[8]=cov[2][2];

      // test (minor?) eigenvector as feature, gives ori of tract plane
      //fv[9] = eigenvectors[0][2];
      //fv[10] = eigenvectors[1][2];
      //fv[11] = eigenvectors[2][2];
      
      // Save this path's features on the list
      features->PushBack( fv );

      // get next object in collection
      currStreamline= (vtkHyperStreamlineDTMRI *)
        this->InputStreamlines->GetNextItemAsObject();
    }

  // See how many tracts' features we have computed
  vtkDebugMacro( "Number of tracts = " << features->Size() );


  // Now measure distance between feature vectors
  typedef itk::Statistics::EuclideanDistance< FeatureVectorType > 
    DistanceMetricType;
  DistanceMetricType::Pointer distanceMetric = DistanceMetricType::New();


  // Now we need to iterate over features and create feature distance matrix
  FeatureListType::Iterator iter1 = features->Begin() ;
  FeatureListType::Iterator iter2;
  // indices into arrays of distances and weights
  int idx1 = 0;
  int idx2;

  // to convert distances to similarities/weights
  double sigmasq=this->Sigma*this->Sigma;

  while( iter1 != features->End() )
    {
      vtkDebugMacro( "id = " << iter1.GetInstanceIdentifier()  
                     << "\t measurement vector = " 
                     << iter1.GetMeasurementVector() 
                     << "\t frequency = " 
                     << iter1.GetFrequency() 
                     ) ;
      
      iter2 = features->Begin() ;
      idx2 = 0;

      while( iter2 != features->End() )
        {
          // save the distance in a matrix
          m_InterTractDistanceMatrix(idx1,idx2) = distanceMetric->
            Evaluate( iter1.GetMeasurementVector(), 
                      iter2.GetMeasurementVector() );

          // save the similarity in a matrix
          m_InterTractSimilarityMatrix(idx1,idx2) = 
            exp(-(m_InterTractDistanceMatrix(idx1,idx2))/sigmasq);

          vtkDebugMacro( "id1 = " << iter1.GetInstanceIdentifier()  
                         << " id2 = " << iter2.GetInstanceIdentifier()  
                         << " distance = "
                         << m_InterTractDistanceMatrix(idx1,idx2) );
          ++iter2 ;
          idx2++;
        }

      ++iter1 ;
      idx1++;
    }

}


void vtkTractShapeFeatures::ComputeFeaturesEndPoints()
{
  vtkHyperStreamlineDTMRI *currStreamline;

  // the features are endpoints (3 values)
  typedef itk::Vector< double, 3 > FeatureVectorType;
  typedef itk::Statistics::ListSample< FeatureVectorType > FeatureListType;

  FeatureListType::Pointer endpoint = FeatureListType::New();
  FeatureVectorType fv, epA1, epA2, epB1, epB2;

  // Ready the input for access
  this->InputStreamlines->InitTraversal();
  // TO DO: make sure this is a vtkHyperStreamlinePoints object
  currStreamline= (vtkHyperStreamlineDTMRI *)this->InputStreamlines->GetNextItemAsObject();
  
  // test we have streamlines
  if (currStreamline == NULL)
    {
      vtkErrorMacro("No streamlines are on the collection.");
      return;      
    }

  vtkDebugMacro( "Traverse STREAMLINES" );

  while(currStreamline)
    {
      double point[3];
      vtkPoints *hs0, *hs1;

      // GetHyperStreamline0/1 
      hs0=currStreamline->GetOutput()->GetCell(0)->GetPoints();

      // Get both endpoints
      hs0->GetPoint(hs0->GetNumberOfPoints()-1,point);
      fv[0]=point[0];      
      fv[1]=point[1];      
      fv[2]=point[2];
      endpoint->PushBack( fv );

      hs1=currStreamline->GetOutput()->GetCell(1)->GetPoints();
      hs1->GetPoint(hs1->GetNumberOfPoints()-1,point);
      fv[0]=point[0];      
      fv[1]=point[1];      
      fv[2]=point[2];
      endpoint->PushBack( fv );

      // get next object in collection
      currStreamline= (vtkHyperStreamlineDTMRI *)
        this->InputStreamlines->GetNextItemAsObject();
    }

  // See how many tracts' features we have computed
  vtkDebugMacro( "Number of tracts = " << endpoint->Size()/2 );


  // Now measure distance between feature vectors (endpoints)
  typedef itk::Statistics::EuclideanDistance< FeatureVectorType > 
    DistanceMetricType;
  DistanceMetricType::Pointer distanceMetric = DistanceMetricType::New();


  // to convert distances to similarities/weights
  double sigmasq=this->Sigma*this->Sigma;
      
          
  // indices into arrays of distances and weights
  int idxr = 0;
  int idxc;
  
  // iterate over features (endpoints) and create feature distance matrix
  // measure from both endpoints to their matching endpoint
  // We don't have correspondence but we assume the closest pair 
  // of endpoints is a match.  then the other two must also match.
  FeatureListType::Iterator iter1 = endpoint->Begin() ;
  
  while( iter1 != endpoint->End() )
    {
      
      FeatureListType::Iterator iter2 = endpoint->Begin() ;
      idxc = 0;

      epA1 = iter1.GetMeasurementVector();
      ++iter1 ;
      epA2 = iter1.GetMeasurementVector();

      while( iter2 != endpoint->End() )
        {

          epB1 = iter2.GetMeasurementVector();
          ++iter2 ;
          epB2 = iter2.GetMeasurementVector();
          
          // distances between all pairs of endpoints from tracts A and B
          double dist_A1_B1 = distanceMetric->Evaluate( epA1, epB1 );
          double dist_A1_B2 = distanceMetric->Evaluate( epA1, epB2 );
          double dist_A2_B1 = distanceMetric->Evaluate( epA2, epB1 );
          double dist_A2_B2 = distanceMetric->Evaluate( epA2, epB2 );

          // find the min overall distance.
          // assume these endpoints are the best match.
          double distmin;
          distmin = dist_A1_B1 + dist_A2_B2;
          if (dist_A1_B2 + dist_A2_B1 < distmin)
            distmin = dist_A1_B2 + dist_A2_B1;

          // save this total distance in a matrix
          m_InterTractDistanceMatrix(idxr,idxc) = distmin;       
          
          // save the similarity in a matrix
          m_InterTractSimilarityMatrix(idxr,idxc) = 
            exp(-(m_InterTractDistanceMatrix(idxr,idxc))/sigmasq);

          // increment to the next tract to compare
          ++iter2 ;
          idxc++;
        }
      
      ++iter1 ;
      idxr++;
    }
}

