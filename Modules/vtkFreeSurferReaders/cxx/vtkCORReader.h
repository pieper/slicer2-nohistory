/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkCORReader.h,v $
  Date:      $Date: 2006/05/26 19:40:13 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
// .NAME vtkCORReader - read COR file volume from Freesurfer tools
// .SECTION Description
// .SECTION Caveats
// .SECTION See Also
// vtkPolyData vtkDataReader

#ifndef __vtkCORReader_h
#define __vtkCORReader_h

#include <vtkFreeSurferReadersConfigure.h>
#include <stdio.h>
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkVolumeReader.h"
#include "vtkTransform.h"

class VTK_FREESURFERREADERS_EXPORT vtkCORReader : public vtkVolumeReader
{
public:
  vtkTypeMacro(vtkCORReader,vtkVolumeReader);

  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  static vtkCORReader *New();

  // Description:
  vtkGetVectorMacro(DataDimensions,int,3);

  // Description: 
  // Other objects make use of these methods but we don't. Left here
  // but not implemented.
    // Due to a change in vtk between versions 4.0 and 4.1, GetImage's
    // declaration is not backwards compatible. Compiler preprocessor
    // directives won't wrap properly in TCL so there's no automatic
    // way to detect this and have it compile properly
    // Uncomment the line after the next code line if the vtk version
    // is lower than 4.1.
    vtkImageData *GetImage(int ImageNumber);  
//  vtkStructuredPoints *GetImage(int ImageNumber);


protected:
  vtkCORReader();
  ~vtkCORReader();

  void Execute();
  void ExecuteInformation();

  // COR volumes are always 256^3, so this is just for future changes.
  int DataDimensions[3];

  // Description:
  // Reads the actual COR files and creates an array of values.
  vtkDataArray *ReadVolumeData();

  // Description:
  // Read the COR-.info file and get header information from it.
  void          ReadVolumeHeader();

private:
  vtkCORReader(const vtkCORReader&);  // Not implemented.
  void operator=(const vtkCORReader&);  // Not implemented.
};

#endif

