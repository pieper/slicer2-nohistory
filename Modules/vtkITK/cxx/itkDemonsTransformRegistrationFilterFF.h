/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: itkDemonsTransformRegistrationFilterFF.h,v $
  Date:      $Date: 2006/01/06 17:57:43 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/

#ifndef __itkDemonsTransformRegistrationFilterFF_h
#define __itkDemonsTransformRegistrationFilterFF_h

//BTX
#include "itkDemonsTransformRegistrationFilter.h"

typedef  itk::Image<float, 3> ImageType;

namespace itk {
class ITK_EXPORT itkDemonsTransformRegistrationFilterFF : public itk::itkDemonsTransformRegistrationFilter<ImageType>
{
public:
  typedef itkDemonsTransformRegistrationFilterFF             Self;
  typedef itk::itkDemonsTransformRegistrationFilter<ImageType>  Superclass;
  typedef ::itk::SmartPointer<Self>          Pointer;
  typedef ::itk::SmartPointer<const Self>    ConstPointer;


  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(itkDemonsTransformRegistrationFilterFF, itk::itkDemonsTransformRegistrationFilter);
  
protected:  
  // Default constructor
  itkDemonsTransformRegistrationFilterFF(){};

private:
  itkDemonsTransformRegistrationFilterFF(const itkDemonsTransformRegistrationFilterFF&);  // Not implemented.
  void operator=(const itkDemonsTransformRegistrationFilterFF&);  // Not implemented.
};

} // namespace itk

//ETX

#endif
