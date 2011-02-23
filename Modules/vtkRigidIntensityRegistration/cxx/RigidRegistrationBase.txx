/*=auto=========================================================================
(c) Copyright 2003 Massachusetts Institute of Technology (MIT) All Rights Reserved.

This software ("3D Slicer") is provided by The Brigham and Women's 
Hospital, Inc. on behalf of the copyright holders and contributors.
Permission is hereby granted, without payment, to copy, modify, display 
and distribute this software and its documentation, if any, for  
research purposes only, provided that (1) the above copyright notice and 
the following four paragraphs appear on all copies of this software, and 
(2) that source code to any modifications to this software be made 
publicly available under terms no more restrictive than those in this 
License Agreement. Use of this software constitutes acceptance of these 
terms and conditions.

3D Slicer Software has not been reviewed or approved by the Food and 
Drug Administration, and is for non-clinical, IRB-approved Research Use 
Only.  In no event shall data or images generated through the use of 3D 
Slicer Software be used in the provision of patient care.

IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE LIABLE TO 
ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
EVEN IF THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

THE COPYRIGHT HOLDERS AND CONTRIBUTORS SPECIFICALLY DISCLAIM ANY EXPRESS 
OR IMPLIED WARRANTIES INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
NON-INFRINGEMENT.

THE SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
IS." THE COPYRIGHT HOLDERS AND CONTRIBUTORS HAVE NO OBLIGATION TO 
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

=========================================================================auto=*/
#ifndef __RigidRegistrationBase_txx
#define __RigidRegistrationBase_txx

#include "RigidRegistrationBase.h"

#include "itkCommand.h"

#include "vtkMatrix4x4.h"
#include "vnl/vnl_math.h"

#include "NewStoppingCondition.h"
#include "itkVTKImageImport.h"
#include "vtkImageExport.h"
#include "vtkITKUtility.h"
#include "vtkUnsignedIntArray.h"
#include "vtkDoubleArray.h"
#include "vtkITKRigidRegistrationTransformBase.h"

namespace itk
{

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::RigidRegistrationBase()
{
  // Images need to be set from the outside
  m_FixedImage  = NULL;
  m_MovingImage = NULL;

  // The itk components
  m_Transform          = TransformType::New();
  m_Optimizer          = OptimizerType::New();
  m_Metric             = MetricType::New();
  m_Interpolator       = InterpolatorType::New();
  m_FixedImagePyramid  = FixedImagePyramidType::New();
  m_MovingImagePyramid = MovingImagePyramidType::New();
  m_Registration       = RegistrationType::New();

  // Connect them all together
  m_Registration->SetTransform(m_Transform);
  m_Registration->SetOptimizer(m_Optimizer);
  m_Registration->SetMetric(m_Metric);
  m_Registration->SetInterpolator(m_Interpolator);
  m_Registration->SetFixedImagePyramid(m_FixedImagePyramid);
  m_Registration->SetMovingImagePyramid(m_MovingImagePyramid);

  // Default parameters
  m_NumberOfLevels = 1;
  m_TranslationScale = 1.0;

  m_FixedImageShrinkFactors.Fill(1);
  m_MovingImageShrinkFactors.Fill(1);

  m_NumberOfIterations = UnsignedIntArray(1);
  m_NumberOfIterations.Fill(10);

  m_LearningRates = DoubleArray(1);
  m_LearningRates.Fill(1e-4);

  m_InitialParameters = ParametersType(m_Transform->GetNumberOfParameters());
  m_InitialParameters.Fill(0.0);
  m_InitialParameters[3] = 1.0;

  // This Affine Transform is only used to return an Affine Transform
  // should it be requested.
  m_AffineTransform  = AffineTransformType::New();

  // Setup a registration observer
  // The observer watches when a new level is started
  typedef SimpleMemberCommand<Self> CommandType;
  typename CommandType::Pointer command = CommandType::New();
  command->SetCallbackFunction( this, &Self::StartNewLevel );
  m_ObserverTag = m_Registration->AddObserver( IterationEvent(), command );

  // Set up an observer that searcher for convergence
  m_OptimizeObserverTag = 0;

}

//----------------------------------------------------------------------

// Clean Up: Remove the observer
template <typename TFixedImage, typename TMovingImage, typename TMetricType>
RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::~RigidRegistrationBase()
{
  m_Registration->RemoveObserver(m_ObserverTag);
  m_Optimizer->RemoveObserver(m_OptimizeObserverTag);
}

//----------------------------------------------------------------------------

  // some memory leaks here...
template <typename itkImageType>
itkImageType *VTKtoITKImage(vtkImageData *VtkImage, itkImageType *)
{
  typedef typename itk::VTKImageImport<itkImageType>  ImageImportType;
  typedef typename ImageImportType::Pointer           ImageImportPointer;

  vtkImageExport *ImageExporter = vtkImageExport::New();
    ImageExporter->SetInput(VtkImage);
  ImageImportPointer ItkImporter = ImageImportType::New();
  ConnectPipelines(ImageExporter, ItkImporter);
  ItkImporter->Update();
  ItkImporter->GetOutput()->Register();
  return ItkImporter->GetOutput();
}

//----------------------------------------------------------------------------

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::Initialize
(vtkITKRigidRegistrationTransformBase *self, vtkMatrix4x4 *matrix)
{
  // ----------------------------------------
  // Sources to ITK Registration
  // ----------------------------------------

  // Create the Registrator

  this->SetMovingImage(VTKtoITKImage(self->GetSourceImage(),(MovingImageType *)NULL));
  this->GetMovingImage()->UnRegister();

  this->SetFixedImage(VTKtoITKImage(
                               self->GetPossiblyFlippedTargetImage(),
                   (FixedImageType *)NULL));    
  this->GetFixedImage()->UnRegister();

  // ----------------------------------------
  // Do the Registratioon Configuration
  // ----------------------------------------

  // Initialize
  this->InitializeRegistration(matrix);

 // Setup the optimizer

  this->SetTranslationScale(1.0/vnl_math_sqr(self->GetTranslateScale()));
//  // This is the scale on translation
//  for (int j=4; j<7; j++)
//    {
//    scales[j] = MIReg_TranslationScale;
//    // This was chosen by Steve. I'm not sure why.
//    scales[j] = 1.0/vnl_math_sqr(self->GetTranslateScale());
//    }

  //
  // This is the multi-resolution information
  // Number of iterations and learning rate at each level
  //

  DoubleArray      LearnRates(self->GetLearningRate()->GetNumberOfTuples());
  UnsignedIntArray NumIterations(self->GetLearningRate()->GetNumberOfTuples());

  for(int i=0;i<self->GetLearningRate()->GetNumberOfTuples();i++)
    {
      LearnRates[i]    = self->GetLearningRate()->GetValue(i);
      NumIterations[i] = self->GetMaxNumberOfIterations()->GetValue(i);
    }
  this->SetNumberOfLevels(self->GetLearningRate()
                                       ->GetNumberOfTuples());
  this->SetLearningRates(LearnRates);
  this->SetNumberOfIterations(NumIterations);

  //
  // This is the shrink factors for each dimension
  // 

  ShrinkFactorsArray SourceShrink;
  SourceShrink[0] = self->GetSourceShrinkFactors(0);
  SourceShrink[1] = self->GetSourceShrinkFactors(1);
  SourceShrink[2] = self->GetSourceShrinkFactors(2);
  this->SetMovingImageShrinkFactors(SourceShrink);

  ShrinkFactorsArray TargetShrink;
  TargetShrink[0] = self->GetTargetShrinkFactors(0);
  TargetShrink[1] = self->GetTargetShrinkFactors(1);
  TargetShrink[2] = self->GetTargetShrinkFactors(2);
  this->SetFixedImageShrinkFactors(TargetShrink);

  //
  // The Callback Function on the optimizer
  //

  // Might be bad if called many times...could have many identical observers
  NewStoppingCondition::Pointer StoppingCondition=NewStoppingCondition::New();
  StoppingCondition->SetUpdateIter(100);
  StoppingCondition->SetCallbackFunction(self,
             vtkITKRigidRegistrationTransformBase::DataCallback);
  m_OptimizeObserverTag = m_Optimizer->AddObserver( IterationEvent(),
                                                    StoppingCondition );
  // Do not abort.
  self->SetAbort(0);
}

//----------------------------------------------------------------------------

template < typename TFixedImage, typename TMovingImage, typename TMetricType  >
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>
::PrintSelf(std::ostream& os, Indent indent) const
{
  Superclass::PrintSelf(os, indent);

  os << indent << "NumberOfLevels: "  << m_NumberOfLevels << endl;
  os << indent << "TranslationScale: " 
        <<   m_TranslationScale             << endl;
  os << indent << "NumberOfIterations: " 
        <<   m_NumberOfIterations           << endl;
  os << indent << "LearningRates: " 
        <<   m_LearningRates                << endl;
  os << indent << "MovingImageShrinkFactors: " 
        <<   m_MovingImageShrinkFactors     << endl;
  os << indent << "FixedImageShrinkFactors: " 
        <<   m_FixedImageShrinkFactors      << endl;
  os << indent << "InitialParameters: " 
        <<   m_InitialParameters            << endl;
  os << indent << "AffineTransform: " << m_AffineTransform  << endl;
  os << indent << "ObserveTag: "  <<   m_ObserverTag  << endl;
  os << indent << "OptimizeTag: " <<   m_OptimizeObserverTag  << endl;

  os << indent << "FixedImage: " <<  m_FixedImage          << endl;
  os << indent << "MovingImage: " <<  m_MovingImage         << endl;
  os << indent << "Transform: " <<  m_Transform           << endl;
  os << indent << "Optimizer: " <<  m_Optimizer           << endl;
  os << indent << "Metric: " <<  m_Metric              << endl;
  os << indent << "Interpolator: " <<  m_Interpolator        << endl;
  os << indent << "FixedImagePyramid: " <<  m_FixedImagePyramid   << endl;
  os << indent << "MovingImagePyramid: " <<  m_MovingImagePyramid  << endl;
  os << indent << "Registration: " <<  m_Registration        << endl;
}

//----------------------------------------------------------------------------

// Go from an initial Matrix To Setting the initial Parameters of the Registration
template <typename TFixedImage, typename TMovingImage, typename TMetricType>
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::InitializeRegistration(
                         vtkMatrix4x4 *matrix)
{
  vnl_matrix<double> matrix3x4(3,4);

  for(int i=0;i<3;i++)
    for(int j=0;j<4;j++)
      matrix3x4[i][j] = matrix->Element[i][j];
  
  vnl_quaternion<double> matrixAsQuaternion(matrix3x4);

  // There is a transpose between the vnl quaternion and itk quaternion.
  vnl_quaternion<double> conjugated = matrixAsQuaternion.conjugate();

  // This command automatically does the conjugate.
  // But, it does not calculate the paramaters
  // m_Transform->SetRotation(matrixAsQuaternion);

  // Quaternions have 7 parameters. The first four represents the
  // quaternion and the last three represents the offset. 
  m_InitialParameters[0] = conjugated.x();
  m_InitialParameters[1] = conjugated.y();
  m_InitialParameters[2] = conjugated.z();
  m_InitialParameters[3] = conjugated.r();
  m_InitialParameters[4] = matrix->Element[0][3];
  m_InitialParameters[5] = matrix->Element[1][3];
  m_InitialParameters[6] = matrix->Element[2][3];

  // The guess is: a quaternion followed by a translation
  m_Registration->SetInitialTransformParameters(m_InitialParameters);
  m_Transform->SetParameters(m_InitialParameters);
}

//----------------------------------------------------------------------------

// Go from the Param to Matrix
template <typename TFixedImage, typename TMovingImage, typename TMetricType>
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::ParamToMatrix(
                         const ParametersType &Param,
                         vtkMatrix4x4 *matrix)
{
  m_Transform->SetParameters(Param);
  m_Transform->GetRotationMatrix();

  const TransformType::MatrixType ResMat   =m_Transform->GetRotationMatrix();
  const TransformType::OffsetType ResOffset=m_Transform->GetOffset();

  // Copy the Rotation Matrix
  for(int i=0;i<3;i++)
    for(int j=0;j<3;j++)
      matrix->Element[i][j] = ResMat[i][j];

  // Copy the Offset
  for(int s=0;s<3;s++)
    matrix->Element[s][3] = ResOffset[s];

  // Fill in the rest
  matrix->Element[3][0] = 0;
  matrix->Element[3][1] = 0;
  matrix->Element[3][2] = 0;
  matrix->Element[3][3] = 1;
}

//----------------------------------------------------------------------------

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
int RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::TestParamToMatrix()
{
  ParametersType test = ParametersType(m_Transform->GetNumberOfParameters());
  test[0] = 0.08428825861139;
  test[1] = 0.11238434481518;
  test[2] = 0.14048043101898;
  test[3] = 0.98006657784124;
  test[4] = 3.1;
  test[5] = 6.1;
  test[6] = 5.2;

  vtkMatrix4x4 *mat = vtkMatrix4x4::New();
  ParamToMatrix(test,mat);
  InitializeRegistration(mat);

  itkDebugMacro( << "Testing for initial stuff " 
        << m_InitialParameters << endl);

  int err=0;
  for(int i=0;i<7;i++)
    if (fabs(test[i]-m_InitialParameters[i])>0.001)
      err = 1;

  mat->Delete();
  return err;
}

//----------------------------------------------------------------------

// Do the registration
template <typename TFixedImage, typename TMovingImage, typename TMetricType>
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::Execute()
{
  //
  // Setup the optimizer
  //
  typename OptimizerType::ScalesType 
    scales(m_Transform->GetNumberOfParameters());
  scales.Fill(1.0);

  for ( int j = 4; j < 7; j++ )
    {
      scales[j] = m_TranslationScale;
      // scales[j] = 1.0/vnl_math_sqr(m_TranslationScale);
    }

  m_Optimizer->SetScales( scales );
  m_Optimizer->MaximizeOn();

  //
  // Setup the metric
  //

  this->SetMetricParam();

  //
  // Setup the image pyramids
  //
  m_FixedImagePyramid->SetNumberOfLevels(m_NumberOfLevels);
  m_FixedImagePyramid->SetStartingShrinkFactors(
    m_FixedImageShrinkFactors.GetDataPointer());

  m_MovingImagePyramid->SetNumberOfLevels(m_NumberOfLevels);
  m_MovingImagePyramid->SetStartingShrinkFactors(
    m_MovingImageShrinkFactors.GetDataPointer());

  //
  // Setup the registrator
  //
  m_Registration->SetFixedImage(m_FixedImage);
  m_Registration->SetMovingImage(m_MovingImage);
  m_Registration->SetNumberOfLevels(m_NumberOfLevels);
 
  m_Registration->SetInitialTransformParameters(m_InitialParameters);
  m_Registration->SetFixedImageRegion(
                      m_FixedImage->GetBufferedRegion());

  itkDebugMacro( << "Starting Iteration" << endl);
  //this->Print(std::cout); // don't print now, causes a warning that output not set yet
  //
  // Do the Registration
  //
  try { m_Registration->StartRegistration();  }
  catch( itk::ExceptionObject & err )
    {
      std::cout << "Caught an exception: " << std::endl;
      std::cout << err << std::endl;
      throw err;
    }

  itkDebugMacro( << "Ending Iteration" << endl);
  // this->Print(std::cout);
}

//----------------------------------------------------------------------

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
typename RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::AffineTransformPointer
RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::GetAffineTransform()
{
  m_Transform->SetParameters(m_Registration->GetLastTransformParameters());
  m_AffineTransform->SetMatrix(m_Transform->GetRotationMatrix());
  m_AffineTransform->SetOffset(m_Transform->GetOffset());

  return m_AffineTransform;
}

//----------------------------------------------------------------------

template <typename TFixedImage, typename TMovingImage, typename TMetricType>
void RigidRegistrationBase<TFixedImage,TMovingImage,TMetricType>::StartNewLevel()
{
  itkDebugMacro( << "--- Starting level " 
            << m_Registration->GetCurrentLevel()
            << std::endl );

  unsigned int level = m_Registration->GetCurrentLevel();
  if (m_NumberOfIterations.Size() >= level + 1)
    {
      m_Optimizer->SetNumberOfIterations(m_NumberOfIterations[level]);
    }

  if (m_LearningRates.Size() >= level + 1)
    {
      m_Optimizer->SetLearningRate( m_LearningRates[level] );
    }

  itkDebugMacro( << " No. Iterations: " 
            << m_Optimizer->GetNumberOfIterations()
            << " Learning rate: "
            << m_Optimizer->GetLearningRate()
            << std::endl);
}

} // namespace itk


#endif /* __RigidRegistrationBase_txx */
