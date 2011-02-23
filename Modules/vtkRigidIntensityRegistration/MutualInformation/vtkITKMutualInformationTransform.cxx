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

#include "vtkITKMutualInformationTransform.h"

#include "vtkImageData.h"
#include "vtkObjectFactory.h"
#include "vtkImageExport.h"
#include "vtkTransform.h"
#include "vtkUnsignedIntArray.h"
#include "vtkDoubleArray.h"

#include "vtkMatrix4x4.h"
#include "vtkImageFlip.h"

#include "itkVTKImageImport.h"
#include "vtkITKUtility.h"

#include "itkExceptionObject.h"

// itk classes
// All the MI Registration Stuff
#include "MIRegistration.h"

//------------------------------------------------------------------------------
vtkITKMutualInformationTransform* vtkITKMutualInformationTransform::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkITKMutualInformationTransform");
  if(ret)
    {
    return (vtkITKMutualInformationTransform*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkITKMutualInformationTransform;
}

//----------------------------------------------------------------------------
vtkITKMutualInformationTransform::vtkITKMutualInformationTransform()
{
}

//----------------------------------------------------------------------------

vtkITKMutualInformationTransform::~vtkITKMutualInformationTransform()
{
}

//----------------------------------------------------------------------------

void vtkITKMutualInformationTransform::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os, indent);
}

//----------------------------------------------------------------------------

// This templated function executes the filter for any type of data.
// But, actually we use only float...
template <class T>
static void vtkITKMutualInformationExecute(vtkITKMutualInformationTransform *self,
                               vtkImageData *source,
                               vtkImageData *target,
                               vtkMatrix4x4 *matrix,
                               T vtkNotUsed(dummy))
{
  // Declare the input and output types
  typedef itk::Image<T,3>                       OutputImageType;

  // ----------------------------------------
  // Sources to ITK MIRegistration
  // ----------------------------------------

  // Create the Registrator
  typedef itk::MIRegistration<OutputImageType,OutputImageType> RegistratorType;
  typename RegistratorType::Pointer MIRegistrator = RegistratorType::New();

  MIRegistrator->Initialize(self,matrix);

  // Set metric related parameters
  MIRegistrator->SetMovingImageStandardDeviation(self->GetSourceStandardDeviation());
  MIRegistrator->SetFixedImageStandardDeviation(self->GetTargetStandardDeviation());
  MIRegistrator->SetNumberOfSpatialSamples(self->GetNumberOfSamples());

  //
  // Start registration
  //
  try { MIRegistrator->Execute(); }
  catch( itk::ExceptionObject & err )
    {
      std::cout << "Caught an exception: " << std::endl;
      std::cout << err << std::endl;
      self->SetError(1);
      return;
    }

  MIRegistrator->ResultsToMatrix(matrix);

  // Get the Value of the agreement
  self->SetMetricValue(MIRegistrator->GetMetricValue());
  // self->SetMetricValue(optimizer->GetValue());

  // the last iteration finished with no error
  self->SetError(0);

  self->Modified();
}

//----------------------------------------------------------------------------
// Update the 4x4 matrix. Updates are only done as necessary.
 
void vtkITKMutualInformationTransform::InternalUpdate()
{
  if (this->Superclass::SourceImage == NULL || 
      this->Superclass::TargetImage == NULL)
    {
    this->Matrix->Identity();
    return;
    }

  if (MaxNumberOfIterations->GetNumberOfTuples() != 
               LearningRate->GetNumberOfTuples())
    vtkErrorMacro (<< MaxNumberOfIterations->GetNumberOfTuples() 
    << "is the number of levels of iterations"
    << LearningRate->GetNumberOfTuples() 
    << "is the number of levels of learning rates. "
    << "the two numbers should be the same");

  if (this->SourceImage->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro (<< "Source type " << this->SourceImage->GetScalarType()
                   << "must be float");
    this->Matrix->Identity();
    return;
    }

  if (this->TargetImage->GetScalarType() != VTK_FLOAT)
    {
    vtkErrorMacro (<< "Target type " << this->SourceImage->GetScalarType()
                   << "must be float");
    this->Matrix->Identity();
    return;
    }

  float dummy = 0.0;
  vtkITKMutualInformationExecute(this,
                                 this->SourceImage,
                                 this->TargetImage,
                                 this->Matrix,
                                 dummy);
}

//------------------------------------------------------------------------

unsigned long vtkITKMutualInformationTransform::GetMTime()
{
  unsigned long result = this->Superclass::GetMTime();
  return result;
}

//----------------------------------------------------------------------------
vtkAbstractTransform *vtkITKMutualInformationTransform::MakeTransform()
{
  return vtkITKMutualInformationTransform::New(); 
}

//----------------------------------------------------------------------------
void vtkITKMutualInformationTransform::InternalDeepCopy(vtkAbstractTransform *transform)
{
  this->Superclass::InternalDeepCopy(transform);

  vtkITKMutualInformationTransform *t = (vtkITKMutualInformationTransform *)transform;

  // nothing to copy
}

//----------------------------------------------------------------------------

int vtkITKMutualInformationTransform::TestMatrixInitialize(vtkMatrix4x4 *aMat)
{
  // Initialize
  typedef itk::Image<float,3>                       OutputImageType;
  typedef itk::MIRegistration<OutputImageType,OutputImageType> RegistratorType;
  RegistratorType::Pointer MIRegistrator = RegistratorType::New();

  MIRegistrator->InitializeRegistration(aMat);

  // A TEST!!!
  {
    vtkMatrix4x4 *matt = vtkMatrix4x4::New();
    MIRegistrator->ParamToMatrix(MIRegistrator->GetInitialParameters(),matt);
    double diff = 0.0;
    for(int ii =0;ii<4;ii++)
      for(int jj=0;jj<4;jj++)
        diff += ((aMat->GetElement(ii,jj) - matt->GetElement(ii,jj))*
                 (aMat->GetElement(ii,jj) - matt->GetElement(ii,jj)));
    if (diff > 1e-6)
      {
        MIRegistrator->Print(std::cout);
        std::cout << "Was unable to set initial matricies accurately" << std::endl;
        std::cout << "Error was : " << diff << std::endl;
        std::cout << "Printing initially set matrix" << endl;
        aMat->Print(std::cout);
        std::cout << "Printing actually set matrix" << endl;
        matt->Print(std::cout);
        matt->Delete();
        return -1;
      }
  }
  return MIRegistrator->TestParamToMatrix();
}

//----------------------------------------------------------------------------



