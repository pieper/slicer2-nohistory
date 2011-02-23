/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMGHReader.h,v $
  Date:      $Date: 2006/05/26 19:40:15 $
  Version:   $Revision: 1.8 $

=========================================================================auto=*/
// .NAME vtkMGHReader - read an MGH (.mgh) volume file from Freesurfer tools
// .SECTION Description
// .SECTION Caveats
// .SECTION See Also
// vtkPolyData vtkDataReader

#ifndef __vtkMGHReader_h
#define __vtkMGHReader_h

#include <vtkFreeSurferReadersConfigure.h>
#include "vtkVolumeReader.h"
#if ( (VTK_MAJOR_VERSION >= 5) || ( VTK_MAJOR_VERSION == 4 && VTK_MINOR_VERSION >= 5 ) )
#include "vtk_zlib.h"
#else
#include "zlib.h"
#endif

// Header sizes.
const int FS_DIMENSION_HEADER_SIZE = sizeof(int) * 7;
const int FS_RAS_HEADER_SIZE = (sizeof(float) * 15) + sizeof(short);
const int FS_UNUSED_HEADER_SIZE = 256 - FS_RAS_HEADER_SIZE;
const int FS_WHOLE_HEADER_SIZE =
    FS_RAS_HEADER_SIZE + FS_DIMENSION_HEADER_SIZE + FS_UNUSED_HEADER_SIZE;

// Type constants. We read in one of these and then convert it to a
// VTK scalar constant.
const int MRI_UCHAR = 0;
const int MRI_INT = 1;
const int MRI_FLOAT = 3;
const int MRI_SHORT = 4;

// Forward declaration
class vtkImageData;
class vtkDataArray;
class VTK_FREESURFERREADERS_EXPORT vtkMGHReader : public vtkVolumeReader
{
public:
  vtkTypeMacro(vtkMGHReader,vtkVolumeReader);

  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  static vtkMGHReader *New();

  // Description:
  // Specify file name of vtk data file to read.
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

  // Description:
  vtkGetVectorMacro(DataDimensions,int,3);

    vtkGetVectorMacro(RASMatrix,float,12);
    
  // Description: 
  // Other objects make use of these methods but we don't. Left here
  // but not implemented.
  vtkImageData *GetImage(int ImageNumber);

  // Description:
  // Reads the MGH file and gets header information from it.
  void          ReadVolumeHeader();
  // Description:
  // Reads the MGH file and creates an array of values.
  vtkDataArray *ReadVolumeData();
 

    // expose the values that the read volume header function sets
    vtkGetMacro(ScalarType,int);
    vtkGetMacro(NumFrames,int);
    
protected:
  vtkMGHReader();
  ~vtkMGHReader();

    // for testing
    void SetOutput();
    
  void Execute();
  void ExecuteInformation();

  // File name.
  char *FileName;

  // Dimensions of the volume.
  int DataDimensions[3];

  // Scalar type of the data.
  int ScalarType;

  // Number of frames.
  int NumFrames;

  // Frame we want to look at.
  int CurFrame;

  // RAS registration matrix. (currently unused)
  float RASMatrix[12];


  // Description:
  // Sets the current frame for the volume.
  void          SetFrameIndex( int index );

private:
  vtkMGHReader(const vtkMGHReader&);  // Not implemented.
  void operator=(const vtkMGHReader&);  // Not implemented.

};

#endif

