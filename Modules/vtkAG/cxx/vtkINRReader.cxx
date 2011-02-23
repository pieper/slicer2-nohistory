/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkINRReader.cxx,v $
  Date:      $Date: 2006/01/06 17:57:09 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/
#include "vtkINRReader.h"
#include <stdio.h>
#include "vtkObjectFactory.h"



//------------------------------------------------------------------------------
vtkINRReader* vtkINRReader::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkINRReader");
  if(ret)
    {
    return (vtkINRReader*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkINRReader;
}

void vtkINRReader::ExecuteInformation()
{
  int xsize=0, ysize=0, zsize=0, comp=0;
  float vx, vy, vz;
  int fixed=0;
  int sign=0;
  int size=0;
  char line[200];
  FILE *fp;
  bool readingHeader=true;

  // default pixel size
  vx = vy = vz = 1.;
  
  // if the user has not set the extent, but has set the VOI
  // set the zaxis extent to the VOI z axis
  if (this->DataExtent[4]==0 && this->DataExtent[5] == 0 &&
      (this->DataVOI[4] || this->DataVOI[5]))
    {
    this->DataExtent[4] = this->DataVOI[4];
    this->DataExtent[5] = this->DataVOI[5];
    }

  if (!this->FileName && !this->FilePattern)
    {
    vtkErrorMacro(<<"Either a FileName or FilePattern must be specified.");
    return;
    }

  // Allocate the space for the filename
  this->ComputeInternalFileName(this->DataExtent[5]);
  
  // get the magic number by reading in a file
  fp = fopen(this->InternalFileName,"rb");
  if (!fp)
    {
    vtkErrorMacro("Unable to open file " << this->InternalFileName);
    return;
    }
  
  do
    {
    fgets(line,199,fp);
    if(line[0]=='\n')
      {// skip empty line
      }
    else if(strncmp(line,"#INRIMAGE-4#{",13)==0)
      {// skip magic number
      }
    else if(strncmp(line,"##}",3)==0)
      {// end of header
      this->SetHeaderSize(ftell(fp));
      readingHeader=false;
      }
    else if(strncmp(line,"#*[H]*",6)==0)
      {// skip comments
      }
    else if(strncmp(line,"#",1)==0)
      {// skip johan's additions
      }
    else if(strncmp(line,"XDIM=",5)==0)
      {
      xsize=atoi(line+5);
      }
    else if(strncmp(line,"YDIM=",5)==0)
      {
      ysize=atoi(line+5);
      }
    else if(strncmp(line,"ZDIM=",5)==0)
      {
      zsize=atoi(line+5);
      }
    else if(strncmp(line,"VDIM=",5)==0)
      {
      comp=atoi(line+5);
      }
    else if(strncmp(line,"VX=",3)==0)
      {
      vx=atof(line+3);
      }
    else if(strncmp(line,"VY=",3)==0)
      {
      vy=atof(line+3);
      }
    else if(strncmp(line,"VZ=",3)==0)
      {
      vz=atof(line+3);
      }
    else if(strncmp(line,"TYPE=",5)==0)
      {
      if(strncmp(line+5,"unsigned fixed",14)==0)
    {
    sign = 1;
    fixed = 1;
    }
      else if(strncmp(line+5,"signed fixed",12)==0)
    {
    sign = -1;
    fixed = 1;
    }
      else if(strncmp(line+5,"float",5)==0)
    {
    fixed = 0;
    }
      else
    {
    vtkErrorMacro(<<"Unsupported TYPE in " << this->InternalFileName);
    return;
    }
      }
    else if(strncmp(line,"PIXSIZE=",8)==0)
      {
      size=atoi(line+8);
      }
    else if(strncmp(line,"SCALE=",6)==0)
      {// don't care about this shit
      }
    else if(strncmp(line,"CPU=",4)==0)
      {
      if(strncmp(line+4,"sun",3)==0)
    {
    this->SetDataByteOrderToBigEndian();
    }
      else if(strncmp(line+4,"decm",4)==0)
    {
    this->SetDataByteOrderToLittleEndian();
    }
      else
    {
    vtkErrorMacro(<<"Unsupported CPU in " << this->InternalFileName);
    return;
    }
      }
    else
      {
      vtkErrorMacro(<<"Unsupported token \"" << line << "\" in " << this->InternalFileName);
      return;
      }
    }
  while(readingHeader);
  fclose(fp);

  // if the user has set the VOI, just make sure its valid
  if (this->DataVOI[0] || this->DataVOI[1] || 
      this->DataVOI[2] || this->DataVOI[3] ||
      this->DataVOI[4] || this->DataVOI[5])
    { 
    if ((this->DataVOI[0] < 0) ||
    (this->DataVOI[1] >= xsize) ||
    (this->DataVOI[2] < 0) ||
    (this->DataVOI[3] >= ysize) ||
    (this->DataVOI[4] < 0) ||
    (this->DataVOI[5] >= zsize))
      {
      vtkWarningMacro("The requested VOI is larger than the file's (" << this->InternalFileName << ") extent ");
      this->DataVOI[0] = 0;
      this->DataVOI[1] = xsize - 1;
      this->DataVOI[2] = 0;
      this->DataVOI[3] = ysize - 1;
      this->DataVOI[4] = 0;
      this->DataVOI[5] = zsize - 1;
      }
    }

  this->DataExtent[0] = 0;
  this->DataExtent[1] = xsize - 1;
  this->DataExtent[2] = 0;
  this->DataExtent[3] = ysize - 1;
  this->DataExtent[4] = 0;
  this->DataExtent[5] = zsize - 1;
  
  this->SetNumberOfScalarComponents(comp);

  switch(fixed)
    {
    case 0:
      switch(size)
    {
    case 32:
      this->SetDataScalarTypeToFloat();
      break;
    case 64:
      this->SetDataScalarTypeToDouble();
      break;
    default:
      vtkErrorMacro(<<"Unsupported pixsize " << size << " in " << this->InternalFileName);
      return;
    }
      break;
    case 1:
      switch(sign)
    {
    case -1:
      switch(size)
        {
        case 8:
          this->SetDataScalarType(2);
          break;
        case 16:
          this->SetDataScalarType(4);
          break;
        case 32:
          this->SetDataScalarType(6);
          break;
        case 64:
          this->SetDataScalarType(8);
          break;
        default:
          vtkErrorMacro(<<"Unsupported pixsize " << size << " in " << this->InternalFileName);
          return;
        }
      break;
    case 1:
      switch(size)
        {
        case 8:
          this->SetDataScalarType(3);
          break;
        case 16:
          this->SetDataScalarType(5);
          break;
        case 32:
          this->SetDataScalarType(7);
          break;
        case 64:
          this->SetDataScalarType(9);
          break;
        default:
          vtkErrorMacro(<<"Unsupported pixsize " << size << " in " << this->InternalFileName);
          return;
        }
      break;
    default:
      vtkErrorMacro(<<"Unsupported sign " << sign << " in " << this->InternalFileName);
      return;
    }
    }     

  this->SetDataOrigin((-xsize+1)/2.*vx,
              (-ysize+1)/2.*vy,
              (-zsize+1)/2.*vz);
  this->SetDataSpacing(vx,vy,vz);
  this->SetFileDimensionality(3);
  this->vtkImageReader::ExecuteInformation();
}


