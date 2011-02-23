/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkTensorMathematics.h,v $
  Date:      $Date: 2007/10/16 21:25:48 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/
// .NAME vtkTensorMathematics - Trace, determinant, anisotropy measures
// .SECTION Description
// Operates on input tensors and outputs image data scalars 
// that describe some feature of the input tensors.
//
// In future should optionally pass through input tensors,
// and also possibly output tensors with eigenvectors as columns.
// Currently a two-input filter like vtkImageMathematics, which
// may be useful someday.
//


#ifndef __vtkTensorMathematics_h
#define __vtkTensorMathematics_h


// Operation options.
#define VTK_TENS_TRACE                   0
#define VTK_TENS_DETERMINANT             1
#define VTK_TENS_RELATIVE_ANISOTROPY     2  
#define VTK_TENS_FRACTIONAL_ANISOTROPY   3
#define VTK_TENS_MAX_EIGENVALUE          4
#define VTK_TENS_MID_EIGENVALUE          5
#define VTK_TENS_MIN_EIGENVALUE          6
#define VTK_TENS_LINEAR_MEASURE          7
#define VTK_TENS_PLANAR_MEASURE          8
#define VTK_TENS_SPHERICAL_MEASURE       9
#define VTK_TENS_COLOR_ORIENTATION      10
#define VTK_TENS_D11                    11
#define VTK_TENS_D22                    12
#define VTK_TENS_D33                    13
#define VTK_TENS_MODE                   14
#define VTK_TENS_COLOR_MODE             15
#define VTK_TENS_MAX_EIGENVALUE_PROJX   16
#define VTK_TENS_MAX_EIGENVALUE_PROJY   17
#define VTK_TENS_MAX_EIGENVALUE_PROJZ   18
#define VTK_TENS_RAI_MAX_EIGENVEC_PROJX 19
#define VTK_TENS_RAI_MAX_EIGENVEC_PROJY 20
#define VTK_TENS_RAI_MAX_EIGENVEC_PROJZ 21
#define VTK_TENS_PARALLEL_DIFFUSIVITY   22
#define VTK_TENS_PERPENDICULAR_DIFFUSIVITY   23
#define VTK_TENS_ISOTROPIC_P            24
#define VTK_TENS_ANISOTROPIC_Q          25



#include "vtkTensorUtilConfigure.h"
#include "vtkImageTwoInputFilter.h"

class vtkMatrix4x4;
class vtkImageData;
class VTK_TENSORUTIL_EXPORT vtkTensorMathematics : public vtkImageTwoInputFilter
{
public:
  static vtkTensorMathematics *New();
  vtkTypeMacro(vtkTensorMathematics,vtkImageTwoInputFilter);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Get the Operation to perform.
  vtkGetMacro(Operation,int);
  vtkSetClampMacro(Operation,int, VTK_TENS_TRACE, VTK_TENS_ANISOTROPIC_Q);

  // Description:
  // Output the trace (sum of eigenvalues = sum along diagonal)
  void SetOperationToTrace() 
    {this->SetOperation(VTK_TENS_TRACE);};

  // Description:
  // Output the determinant
  void SetOperationToDeterminant() 
    {this->SetOperation(VTK_TENS_DETERMINANT);};

  // Description:
  // Output various anisotropy and shape measures
  void SetOperationToRelativeAnisotropy() 
    {this->SetOperation(VTK_TENS_RELATIVE_ANISOTROPY);};
  void SetOperationToFractionalAnisotropy() 
    {this->SetOperation(VTK_TENS_FRACTIONAL_ANISOTROPY);};
  void SetOperationToLinearMeasure() 
    {this->SetOperation(VTK_TENS_LINEAR_MEASURE);};
  void SetOperationToPlanarMeasure() 
    {this->SetOperation(VTK_TENS_PLANAR_MEASURE);};
  void SetOperationToSphericalMeasure() 
    {this->SetOperation(VTK_TENS_SPHERICAL_MEASURE);};
  // This is the skewness of the eigenvalues 
  // (thanks to Gordon Lothar (of the Hill People) Kindlmann)
  void SetOperationToMode() 
    {this->SetOperation(VTK_TENS_MODE);};
  void SetOperationToParallelDiffusivity()
    {this->SetOperation(VTK_TENS_PARALLEL_DIFFUSIVITY);};
  void SetOperationToPerpendicularDiffusivity()
    {this->SetOperation(VTK_TENS_PERPENDICULAR_DIFFUSIVITY);};
  void SetOperationToIsotropicP()
    {this->SetOperation(VTK_TENS_ISOTROPIC_P);};
  void SetOperationToAnisotropicQ()
    {this->SetOperation(VTK_TENS_ANISOTROPIC_Q);};


  // Description:
  // Output a selected eigenvalue
  void SetOperationToMaxEigenvalue() 
    {this->SetOperation(VTK_TENS_MAX_EIGENVALUE);};
  void SetOperationToMiddleEigenvalue() 
    {this->SetOperation(VTK_TENS_MID_EIGENVALUE);};
  void SetOperationToMinEigenvalue() 
    {this->SetOperation(VTK_TENS_MIN_EIGENVALUE);};

  // Description:
  // Output Maxeigenvalue*Maxeigenvec_projection also known as L1Z
  void SetOperationToMaxEigenvalueProjectionX()
  {this->SetOperation(VTK_TENS_MAX_EIGENVALUE_PROJX);};
  void SetOperationToMaxEigenvalueProjectionY()
  {this->SetOperation(VTK_TENS_MAX_EIGENVALUE_PROJY);};
  void SetOperationToMaxEigenvalueProjectionZ()
  {this->SetOperation(VTK_TENS_MAX_EIGENVALUE_PROJZ);};
  
  // Description:
  // Output Relative_anisotropy*Maxeigenvec_projection also known as L1z
  void SetOperationToRAIMaxEigenvecX()
  {this->SetOperation(VTK_TENS_RAI_MAX_EIGENVEC_PROJX);}
  void SetOperationToRAIMaxEigenvecY()
  {this->SetOperation(VTK_TENS_RAI_MAX_EIGENVEC_PROJY);}
  void SetOperationToRAIMaxEigenvecZ()
  {this->SetOperation(VTK_TENS_RAI_MAX_EIGENVEC_PROJZ);}
  
  // Description: 
  // Output a matrix (tensor) component
  void SetOperationToD11() 
    {this->SetOperation(VTK_TENS_D11);};
  void SetOperationToD22() 
    {this->SetOperation(VTK_TENS_D22);};
  void SetOperationToD33() 
    {this->SetOperation(VTK_TENS_D33);};
  
  // Description:
  // Output RGB color according to XYZ of eigenvectors.
  // Output A (alpha, or transparency) according to 
  // anisotropy (1-spherical measure).
  void SetOperationToColorByOrientation() 
    {this->SetOperation(VTK_TENS_COLOR_ORIENTATION);};

  // Description:
  // Output RGB color according to colormapping of mode, with 
  // final RGB being a linear combination of gray and 
  // this color.  Amount of gray is determined by FA.
  // Thanks to Gordon Lothar Kindlmann for this method.
  void SetOperationToColorByMode() 
    {this->SetOperation(VTK_TENS_COLOR_MODE);};

  // Description:
  // Specify scale factor to scale output (float) scalars by.
  // This is not used when the output is RGBA (char color data).
  vtkSetMacro(ScaleFactor,vtkFloatingPointType);
  vtkGetMacro(ScaleFactor,vtkFloatingPointType);

  // Description:
  // Turn on/off extraction of eigenvalues from tensor.
  vtkSetMacro(ExtractEigenvalues,int);
  vtkBooleanMacro(ExtractEigenvalues,int);
  vtkGetMacro(ExtractEigenvalues,int);

  // Description
  // This matrix is only used for ColorByOrientation.
  // We transform the tensor orientation by this matrix
  // before setting the output RGB values.
  //
  // This is useful to put the output colors into a standard
  // coordinate system (i.e. RAS) regardless of the data scan order.
  //
  // Example usage is as follows:
  // 1) If tensors are to be displayed in a coordinate system
  //    that is not IJK (array-based), and the whole volume is
  //    being rotated, each tensor needs also to be rotated.
  //    First find the matrix that positions your volume.
  //    (This is how the entire volume is positioned, not 
  //    the matrix that positions an arbitrary reformatted slice.)
  // 2) Remove scaling and translation from this matrix; we
  //    just need to rotate each tensor.
  // 3) Set TensorRotationMatrix to this rotation matrix.
  //
  virtual void SetTensorRotationMatrix(vtkMatrix4x4*);
  vtkGetObjectMacro(TensorRotationMatrix, vtkMatrix4x4);

  // Description
  // Input scalars are a binary mask: 0 prevents display
  // of tensor quantity at that point
  vtkBooleanMacro(MaskWithScalars, int);
  vtkSetMacro(MaskWithScalars, int);
  vtkGetMacro(MaskWithScalars, int);

  // Description:
  // Scalar mask
  virtual void SetScalarMask(vtkImageData*);
  vtkGetObjectMacro(ScalarMask, vtkImageData);
  

  // Public for access from threads
  static void ModeToRGB(double Mode, double FA,
                 double &R, double &G, double &B);


  // Description:
  // Helper functions to perform operations pixel-wise
  static int FixNegativeEigenvalues(vtkFloatingPointType w[3]);
  static vtkFloatingPointType Determinant(vtkFloatingPointType D[3][3]);
  static vtkFloatingPointType Trace(vtkFloatingPointType D[3][3]);
  static vtkFloatingPointType RelativeAnisotropy(vtkFloatingPointType w[3]);
  static vtkFloatingPointType FractionalAnisotropy(vtkFloatingPointType w[3]);
  static vtkFloatingPointType LinearMeasure(vtkFloatingPointType w[3]);
  static vtkFloatingPointType PlanarMeasure(vtkFloatingPointType w[3]);
  static vtkFloatingPointType SphericalMeasure(vtkFloatingPointType w[3]);
  static vtkFloatingPointType MaxEigenvalue(vtkFloatingPointType w[3]);
  static vtkFloatingPointType MiddleEigenvalue(vtkFloatingPointType w[3]);
  static vtkFloatingPointType ParallelDiffusivity(vtkFloatingPointType w[3]);
  static vtkFloatingPointType PerpendicularDiffusivity(vtkFloatingPointType w[3]);
  static vtkFloatingPointType MinEigenvalue(vtkFloatingPointType w[3]);
  static vtkFloatingPointType RAIMaxEigenvecX(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType RAIMaxEigenvecY(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType RAIMaxEigenvecZ(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType MaxEigenvalueProjectionX(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType MaxEigenvalueProjectionY(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType MaxEigenvalueProjectionZ(vtkFloatingPointType **v, vtkFloatingPointType w[3]);
  static vtkFloatingPointType Mode(vtkFloatingPointType w[3]);
  static vtkFloatingPointType IsotropicP(vtkFloatingPointType w[3]);
  static vtkFloatingPointType AnisotropicQ(vtkFloatingPointType w[3]);
  static void ColorByMode(vtkFloatingPointType w[3], vtkFloatingPointType &R,vtkFloatingPointType &G, vtkFloatingPointType &B);

  //Description
  //Wrap function to teem eigen solver
  static int TeemEigenSolver(double **m, double *w, double **v);

protected:
  vtkTensorMathematics();
  ~vtkTensorMathematics();

  int Operation; // math operation to perform
  vtkFloatingPointType ScaleFactor; // Scale factor for output scalars
  int ExtractEigenvalues; // Boolean controls eigenfunction extraction

  int MaskWithScalars;
  vtkImageData *ScalarMask;

  vtkMatrix4x4 *TensorRotationMatrix;

  void ExecuteInformation(vtkImageData **inDatas, vtkImageData *outData);
  void ExecuteInformation(){this->Superclass::ExecuteInformation();};
  void ThreadedExecute(vtkImageData **inDatas, vtkImageData *outData,
        int extent[6], int id);
private:
  vtkTensorMathematics(const vtkTensorMathematics&);
  void operator=(const vtkTensorMathematics&);
};

#endif













