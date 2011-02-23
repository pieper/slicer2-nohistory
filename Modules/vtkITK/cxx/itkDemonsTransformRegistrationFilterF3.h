/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkDemonsTransformRegistrationFilterF3.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/

#ifndef __itkDemonsTransformRegistrationFilterF3_h
#define __itkDemonsTransformRegistrationFilterF3_h

//BTX
#include "itkDemonsTransformRegistrationFilter.h"

typedef  itk::Image<float, 3> ImageType;

namespace itk {
class ITK_EXPORT itkDemonsTransformRegistrationFilterF3 : public itk::itkDemonsTransformRegistrationFilter<ImageType>
{
public:
  typedef itkDemonsTransformRegistrationFilterF3             Self;
  typedef itk::itkDemonsTransformRegistrationFilter<ImageType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;


  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(itkDemonsTransformRegistrationFilterF3, itk::itkDemonsTransformRegistrationFilter);
  
protected:  
  // Default constructor
  itkDemonsTransformRegistrationFilterF3(){};

private:
  itkDemonsTransformRegistrationFilterF3(const itkDemonsTransformRegistrationFilterF3&);  // Not implemented.
  void operator=(const itkDemonsTransformRegistrationFilterF3&);  // Not implemented.
};

} // namespace itk

//ETX

#endif
