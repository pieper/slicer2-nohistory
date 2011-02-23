/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkITKHistogramMatchingImageFilter.h,v $
  Date:      $Date: 2007/06/21 01:05:10 $
  Version:   $Revision: 1.1 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkITKHistogramMatchingImageFilter.h,v $
  Language:  C++
  Date:      $Date: 2007/06/21 01:05:10 $
  Version:   $Revision: 1.1 $
*/
// .NAME vtkITKHistogramMatchingImageFilter - Wrapper class around itk::HistogramMatchingImageFilter
// .SECTION Description
// vtkITKHistogramMatchingImageFilter


/** HistogramMatchingImageFilter normalizes the grayscale values of a source
 * image based on the grayscale values of a reference image. 
 * This filter uses a histogram matching technique where the histograms of the 
 * two images are matched only at a specified number of quantile values.
 *
 * This filter was orginally designed to normalize MR images of the same
 * MR protocol and same body part. The algorithm works best if background
 * pixels are excluded from both the source and reference histograms.
 * A simple background exclusion method is to exclude all pixels whose
 * grayscale values are smaller than the mean grayscale value.
 * ThresholdAtMeanIntensityOn() switches on this simple background
 * exclusion method.
 *
 * The source image can be set via either SetInput() or SetSourceImage().
 * The reference image can be set via SetReferenceImage().
 *
 * SetNumberOfHistogramLevels() sets the number of bins used when
 * creating histograms of the source and reference images.
 * SetNumberOfMatchPoints() governs the number of quantile values to be
 * matched.
 *
 * This filter assumes that both the source and reference are of the same
 * type and that the input and output image type have the same number of
 * dimension and have scalar pixel types.
 */

/*  on the web
 * The histogram matching image filter basically transforms the histogram of one image into the histogram of the other
 * image.  This is done by mapping intensities through the CDF of one image and inverse CDF of the other.
 * 
 * If you take intensity x from image I1, and evaluate the CDF of I1 at x, you get a number y between 0 and 1.
 * 
 *     y = CDF_{I1}(x)
 * 
 * If you then take this value y and run it through the inverse CDF of image I2, you determine corresponding intensity
 * value from image 2.
 * 
 *     x' = CDF_{I2}^{-1}(y) = CDF_{I2}^{-1}( CDF_{I1}(x) )
 * 
 * If you transform all the intensities of Image 1 through this mapping, you will get an image that has approximately
 * the same histogram as Image 2.  I say "approximately" because we are dealing with sampled random variables and 
 * histograms as opposed to dealing with real density functions. 
 * 
 * The HistogramMatchingImageFilter performs this intensity transformation.  To perform the inverse CDF mapping, it
 * samples the range of the CDF at a user specified number of quantiles, then uses linear interpolation within each 
 * of these quantiles to map back to the domain.
 * 
 * I am not sure of a reference for this.  For a keyword search I would look at histogram equalization, and distribution whitening.  They are all related.
 * 
 * Jim
 */ 




#ifndef __vtkITKHistogramMatchingImageFilter_h
#define __vtkITKHistogramMatchingImageFilter_h


#include "vtkITKImageToImageFilterSS.h"
#include "itkHistogramMatchingImageFilter.h"
#include "vtkObjectFactory.h"

class  VTK_EXPORT vtkITKHistogramMatchingImageFilter : public vtkITKImageToImageFilterSS
{
 public:
  static vtkITKHistogramMatchingImageFilter *New();
  vtkTypeRevisionMacro(vtkITKHistogramMatchingImageFilter, vtkITKImageToImageFilterSS);

  void SetSourceImage(vtkImageData *Input) { this->SetInput(Input,0); } 
  void SetReferenceImage(vtkImageData *Input) { this->SetInput(Input,1); } 
  void SetNumberOfHistogramLevels( unsigned long value) 
  {
    DelegateITKInputMacro ( SetNumberOfHistogramLevels, value );
  };

  unsigned long GetNumberOfHistogramLevels ()
  { DelegateITKOutputMacro ( GetNumberOfHistogramLevels ); };
  
  
  void SetNumberOfMatchPoints (short value)
  {  DelegateITKInputMacro (SetNumberOfMatchPoints, value ); }

  unsigned long GetNumberOfMatchPoints ()
  { DelegateITKOutputMacro ( GetNumberOfMatchPoints ); };


  void SetThresholdAtMeanIntensity (int value)
  {  DelegateITKInputMacro (SetThresholdAtMeanIntensity, value ); }

  int GetThresholdAtMeanIntensity ()
  { DelegateITKOutputMacro ( GetThresholdAtMeanIntensity ); };
  
protected:
  //BTX
  typedef itk::HistogramMatchingImageFilter<Superclass::InputImageType, Superclass::OutputImageType> ImageFilterType;

  vtkImageCast* vtkCastReference;
  vtkImageExport* vtkExporterReference;  
  ImageImportType::Pointer itkImporterReference;

  ImageFilterType* GetImageFilterPointer() { return dynamic_cast<ImageFilterType*> ( m_Filter.GetPointer() ); }

  vtkITKHistogramMatchingImageFilter() : Superclass ( ImageFilterType::New() ) {
    this->vtkCastReference = vtkImageCast::New();
    this->vtkCastReference->SetOutputScalarTypeToShort();

    this->vtkExporterReference = vtkImageExport::New();
    this->vtkExporterReference->SetInput ( this->vtkCastReference->GetOutput());

    this->itkImporterReference = ImageImportType::New();
    ConnectPipelines(this->vtkExporterReference, this->itkImporterReference);

    // This essentially links the reference image of the vtk filter with the one of the itk filter
    this->GetImageFilterPointer()->SetReferenceImage(this->itkImporterReference->GetOutput());
  };
  ~vtkITKHistogramMatchingImageFilter() {
    this->vtkCastReference->Delete();
    this->vtkExporterReference->Delete();
  };

  void SetInput(vtkImageData *Input, int idx)
  {
    if (idx == 0) {
      this->vtkCast->SetInput(Input);
    }
    else if (idx == 1) {
      this->vtkCastReference->SetInput(Input);
    }
    else {
      // report error
      assert(0);
    }
  };


  //ETX
  
private:
  vtkITKHistogramMatchingImageFilter(const vtkITKHistogramMatchingImageFilter&);  // Not implemented.
  void operator=(const vtkITKHistogramMatchingImageFilter&);  // Not implemented.
};

vtkCxxRevisionMacro(vtkITKHistogramMatchingImageFilter, "$Revision: 1.1 $");
vtkStandardNewMacro(vtkITKHistogramMatchingImageFilter);

#endif




