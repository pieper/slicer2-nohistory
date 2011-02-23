/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkPTSWriter.cxx,v $
  Date:      $Date: 2006/01/06 17:56:50 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkPTSWriter.cxx,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#include "vtkPTSWriter.h"

#include "vtkImageData.h"
#include "vtkObjectFactory.h"
#include "vtkPointData.h"

vtkPTSWriter* vtkPTSWriter::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkPTSWriter");
  if(ret)
  {
    return (vtkPTSWriter*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkPTSWriter;
}

vtkPTSWriter::vtkPTSWriter()
{
    this->FileLowerLeft = 1;
}

void vtkPTSWriter::WriteFileHeader(ofstream *file, vtkImageData *cache)
{
  // Currently, no header for PTS files
}

void vtkPTSWriter::WriteAsciiPTS()
{
    vtkImageData *data = this->GetInput();
    if (data == NULL)
    {
        vtkErrorMacro(<< "No data to write!");
        return;
    }
    if (this->FileName == NULL)
    {
        vtkErrorMacro(<< "Please specify filename to write");
        return;
    }

    data->UpdateInformation();

    // Write ASCII PTS file
    FILE *fp;
    if ((fp = fopen(this->FileName, "w")) == NULL)
    {
        vtkErrorMacro(<< "Couldn't open file: " << this->FileName);
        return;
    }

    int idx, idy, idz;
    int xmin, xmax, ymin, ymax, zmin, zmax;
    int *ptr;

    if (!data->GetPointData()->GetScalars())
    {
        vtkErrorMacro(<< "Could not get data from input.");
        return;
    }

    data->GetExtent(xmin, xmax, ymin, ymax, zmin, zmax);

    for (idz = zmin; idz <= zmax; idz++)
    {
        for (idx = xmin; idx <= xmax; idx++)
        {
            for (idy = ymin; idy <= ymax; idy++)
            {
                ptr = (int *)data->GetScalarPointer(idx, idy, idz);
                if (!ptr) continue;
                if (fprintf (fp, "%d %d %d\n", ptr[0], ptr[1], ptr[2]) < 0)
                {
                    fclose(fp);
                    vtkErrorMacro(<< "Out of disk space error.");
                    return;
                }
            }
        }
    }
    fclose(fp);
}

void vtkPTSWriter::WriteFile(ofstream *file, vtkImageData *data,
                             int extent[6])
{
  int idx1, idx2;
  int rowLength, rowAdder, i; // in bytes
  unsigned char *ptr;
  int bpp;
  unsigned long count = 0;
  unsigned long target;
  float progress = this->Progress;
  float area;
  int *wExtent;
  
  bpp = data->GetNumberOfScalarComponents();
  
  // Make sure we actually have data.
  if ( !data->GetPointData()->GetScalars())
    {
    vtkErrorMacro(<< "Could not get data from input.");
    return;
    }

  // Row length of x axis
  rowLength = extent[1] - extent[0] + 1;
  rowAdder = (4 - ((extent[1]-extent[0] + 1)*3)%4)%4;

  wExtent = this->GetInput()->GetWholeExtent();
  area = ((extent[5] - extent[4] + 1)*(extent[3] - extent[2] + 1)*
          (extent[1] - extent[0] + 1)) / 
    ((wExtent[5] -wExtent[4] + 1)*(wExtent[3] -wExtent[2] + 1)*
     (wExtent[1] -wExtent[0] + 1));
    
  target = (unsigned long)((extent[5]-extent[4]+1)*
                           (extent[3]-extent[2]+1)/(50.0*area));
  target++;

  for (idx2 = extent[4]; idx2 <= extent[5]; ++idx2)
    {
    for (idx1 = extent[2]; idx1 <= extent[3]; idx1++)
      {
      if (!(count%target))
        {
        this->UpdateProgress(progress + count/(50.0*target));
        }
      count++;
      ptr = (unsigned char *)data->GetScalarPointer(extent[0], idx1, idx2);
      if (bpp == 1)
        {
        for (i = 0; i < rowLength; i++)
          {
          file->put(ptr[i]);
          file->put(ptr[i]);
          file->put(ptr[i]);
          }
        }
      if (bpp == 2)
        {
        for (i = 0; i < rowLength; i++)
          {
          file->put(ptr[i*2]);
          file->put(ptr[i*2]);
          file->put(ptr[i*2]);
          }
        }
      if (bpp == 3)
        {
        for (i = 0; i < rowLength; i++)
          {
          file->put(ptr[i*3 + 2]);
          file->put(ptr[i*3 + 1]);
          file->put(ptr[i*3]);
          }
        }
      if (bpp == 4)
        {
        for (i = 0; i < rowLength; i++)
          {
          file->put(ptr[i*4 + 2]);
          file->put(ptr[i*4 + 1]);
          file->put(ptr[i*4]);
          }
        }
      for (i = 0; i < rowAdder; i++)
        {
        file->put((char)0);
        }
      }
    }
}

//----------------------------------------------------------------------------
void vtkPTSWriter::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
}
