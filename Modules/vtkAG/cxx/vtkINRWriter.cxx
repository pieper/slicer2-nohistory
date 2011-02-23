/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkINRWriter.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkINRWriter.h"
#include "vtkObjectFactory.h"



//------------------------------------------------------------------------------
vtkINRWriter* vtkINRWriter::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkINRWriter");
  if(ret)
    {
    return (vtkINRWriter*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkINRWriter;
}

vtkINRWriter::vtkINRWriter()
{
  this->SetFileDimensionality(3);
  WritePixelSizes=true;
}

void vtkINRWriter::WriteFileHeader(ofstream *file, vtkImageData *cache)
{
  cache->Update();
  
  int* dims=cache->GetDimensions();
  *file << "#INRIMAGE-4#{" << endl
    << "XDIM=" << dims[0] << endl
    << "YDIM=" << dims[1] << endl
    << "ZDIM=" << dims[2] << endl
    << "VDIM=" << cache->GetNumberOfScalarComponents() << endl;
  
  switch(cache->GetScalarType())
    {
    case 2:
    case 4:
    case 6:
    case 8:
      *file << "TYPE=signed fixed" << endl;
      break;
    case 3:
    case 5:
    case 7:
    case 9:
      *file << "TYPE=unsigned fixed" << endl;
      break;
    case 10:
      *file << "TYPE=float" << endl;
      break;
    case 11:
      *file << "TYPE=float" << endl;
      break;
    default:
      vtkErrorMacro(<< "Unsupported scalar type " << cache->GetScalarType());
      return;
    }
  
  switch(cache->GetScalarType())
    {
    case 2:
    case 3:
      *file << "PIXSIZE=8 bits" << endl;
      break;
    case 4:
    case 5: 
      *file << "PIXSIZE=16 bits" << endl;
      break;
    case 6:
    case 7:
    case 10:
      *file << "PIXSIZE=32 bits" << endl;
      break;
    case 8:
    case 9:
    case 11:
      *file << "PIXSIZE=64 bits" << endl;
      break;
    default:
      vtkErrorMacro(<< "Unsupported scalar type " << cache->GetScalarType());
      return;
    }

  *file << "SCALE=2**0" << endl;
#ifdef VTK_WORDS_BIGENDIAN
  *file << "CPU=sun" << endl;
#else
  *file << "CPU=decm" << endl;
#endif

  if(this->WritePixelSizes)
    {
    vtkFloatingPointType* spa = cache->GetSpacing();
    *file << "VX=" << spa[0] << endl
      << "VY=" << spa[1] << endl
      << "VZ=" << spa[2] << endl;
    }
  
  int fill=252-file->tellp();

  if(fill<0)
    {
    vtkErrorMacro(<< "This shouldn't happen.  Big header.");
    return;
    }

  for(int i=0;i<fill;++i)
    {
    *file << '\n';
    }

  *file << "##}" << endl;
}


