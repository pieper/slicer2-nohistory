/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBVolReader.h,v $
  Date:      $Date: 2006/05/26 19:41:32 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
// .NAME vtkBVolReader - read an MGH (.mgh) volume file from Freesurfer tools
// .SECTION Description
// .SECTION Caveats
// .SECTION See Also
// vtkPolyData vtkDataReader

#ifndef __vtkBVolReader_h
#define __vtkBVolReader_h

#include <vtkIbrowserConfigure.h>
#include <stdio.h>
#include "vtkImageData.h"
#include "vtkPointData.h"
#include "vtkVolumeReader.h"
#include "vtkTransform.h"

// Header sizes.
const int FS_DIMENSION_HEADER_SIZE = sizeof(int) * 7;
const int FS_RAS_HEADER_SIZE = (sizeof(float) * 15) + sizeof(short);
const int FS_UNUSED_HEADER_SIZE = 256 - FS_RAS_HEADER_SIZE;
const int FS_WHOLE_HEADER_SIZE =
    FS_RAS_HEADER_SIZE + FS_DIMENSION_HEADER_SIZE + FS_UNUSED_HEADER_SIZE;


class VTK_IBROWSER_EXPORT vtkBVolReader : public vtkVolumeReader
{
public:
  vtkTypeMacro(vtkBVolReader,vtkVolumeReader);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  static vtkBVolReader *New();

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
  vtkSetStringMacro(StrippedStem);
  vtkGetStringMacro(StrippedStem);

// Description:
  vtkSetStringMacro(DirName);
  vtkGetStringMacro(DirName);
  
// Description:
  vtkGetVectorMacro(DataDimensions,int,3);

  // Description: 
  // Other objects make use of these methods but we don't. Left here
  // but not implemented.
  vtkImageData *GetImage(int ImageNumber);
    
  vtkMatrix4x4* GetRegistrationMatrix ();

protected:
  vtkBVolReader();
  ~vtkBVolReader();

  void Execute();
  void ExecuteInformation();

  // File name.
  char *FileName;
  char *DirName;
  
  // File name of the registration matrix.
  char *RegistrationFileName;

  // These are calculated and used internally.
  char *SliceFileNameExtension;
  char *StrippedStem; //filebasename
  char *Stem; //filebasename_xxx
      
  // Dimensions of the volume.
  int DataDimensions[3];

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
  
  // Description:
  // Reads the MGH file and creates an array of values.
  vtkDataArray *ReadVolumeData();

  // Description:
  // Reads the MGH file and gets header information from it.
  void ReadVolumeHeader();
  void FindStemFromFilePrefixOrFileName();
  void GuessTypeFromStem();

  // Description:
  // Sets the current frame for the volume.
  void          SetTimePoint( int timePoint );

private:
  vtkBVolReader(const vtkBVolReader&);  // Not implemented.
  void operator=(const vtkBVolReader&);  // Not implemented.
};

#endif

