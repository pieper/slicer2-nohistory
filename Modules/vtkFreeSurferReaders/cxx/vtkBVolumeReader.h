/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBVolumeReader.h,v $
  Date:      $Date: 2006/05/26 19:40:13 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
// .NAME vtkBVolumeReader - read a binary volume file from Freesurfer tools
// .SECTION Description
// .SECTION Caveats
// .SECTION See Also
// vtkPolyData vtkDataReader

#ifndef __vtkBVolumeReader_h
#define __vtkBVolumeReader_h

#include <vtkFreeSurferReadersConfigure.h>
#include "vtkVolumeReader.h"

// Header sizes.
const int FS_DIMENSION_HEADER_SIZE = sizeof(int) * 7;
const int FS_RAS_HEADER_SIZE = (sizeof(float) * 15) + sizeof(short);
const int FS_UNUSED_HEADER_SIZE = 256 - FS_RAS_HEADER_SIZE;
const int FS_WHOLE_HEADER_SIZE =
    FS_RAS_HEADER_SIZE + FS_DIMENSION_HEADER_SIZE + FS_UNUSED_HEADER_SIZE;


class vtkImageData;
class vtkMatrix4x4;
class vtkDataArray;
class VTK_FREESURFERREADERS_EXPORT vtkBVolumeReader : public vtkVolumeReader
{
public:
  vtkTypeMacro(vtkBVolumeReader,vtkVolumeReader);

  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  static vtkBVolumeReader *New();

  // Description:
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

  // Description:
  vtkSetStringMacro(SliceFileNameExtension);
  vtkGetStringMacro(SliceFileNameExtension);

  // Description:
  vtkSetStringMacro(RegistrationFileName);
  vtkGetStringMacro(RegistrationFileName);

  // Description:
  vtkSetStringMacro(Stem);
  vtkGetStringMacro(Stem);

  // Description:
  vtkGetVectorMacro(DataDimensions,int,3);

    // Description:
  // Reads the header file and gets header information from it.
  int ReadVolumeHeader();
    
  // Description: 
  // Other objects make use of these methods but we don't. Left here
  // but not implemented.
  vtkImageData *GetImage(int ImageNumber);
    
  vtkMatrix4x4* GetRegistrationMatrix ();

    vtkGetVectorMacro(RASMatrix,float,12);

    vtkGetVectorMacro(TopL,float,3);
    vtkGetVectorMacro(TopR,float,3);
    vtkGetVectorMacro(BottomR,float,3);
    vtkGetVectorMacro(Normal,float,3);
    

    vtkGetMacro(ScalarType,int);
    vtkGetMacro(NumTimePoints,int);
//    vtkGetVectorMacro(DataSpacing,int,3);

    // Description:
  // Reads the MGH file and creates an array of values. - exposed for gdf reading
  vtkDataArray *ReadVolumeData();
    
protected:
  vtkBVolumeReader();
  ~vtkBVolumeReader();

  void Execute();
  void ExecuteInformation();

  // File name.
  char *FileName;

  // File name of the registration matrix.
  char *RegistrationFileName;

  // These are calculated and used internally.
  char *SliceFileNameExtension;
  char *Stem;
  
  // Dimensions of the volume.
  int DataDimensions[3];
    // int DataSpacing[3];

  // Scalar type of the data.
  int ScalarType;

  // Number of time points.
  int NumTimePoints;
  

  // Time point we want to look at.
  int CurTimePoint;

  // RAS registration matrix. (currently unused)
  // 0 x_r x_a x_s 4
  // 3 y_r y_a y_s 5
  // 6 z_r z_a z_s 8
  // 9 c_r c_a c_s 11
  float RASMatrix[12];
  
  // Functional -> Anatomical registration matrix.
  vtkMatrix4x4 *RegistrationMatrix;

  // Meta data.
  float TE;
  float TR;
  float TI;
  float FlipAngle;

    // corner points, values in array are R, A, S
    float TopL[3];
    float TopR[3];
    float BottomR[3];
    float Normal[3];
    
  void FindStemFromFilePrefixOrFileName();
  void GuessTypeFromStem();

  // Description:
  // Sets the current frame for the volume.
  void          SetTimePoint( int timePoint );

private:
  vtkBVolumeReader(const vtkBVolumeReader&);  // Not implemented.
  void operator=(const vtkBVolumeReader&);  // Not implemented.
};

#endif

