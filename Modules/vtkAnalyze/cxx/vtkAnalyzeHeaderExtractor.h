/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAnalyzeHeaderExtractor.h,v $
  Date:      $Date: 2006/01/06 17:57:13 $
  Version:   $Revision: 1.3 $

=========================================================================auto=*/

// .NAME vtkAnalyzeHeaderExtractor - Extracts infor from Analyze hdr file 
// .SECTION Description
// vtkAnalyzeHeaderExtractor is used to read header information from 
// any Analyze header file (.hdr).


#ifndef __vtkAnalyzeHeaderExtractor_h
#define __vtkAnalyzeHeaderExtractor_h


#include <vtkAnalyzeConfigure.h>
#include "AnalyzeHeader.h"
#include "vtkObject.h"

class VTK_ANALYZE_EXPORT vtkAnalyzeHeaderExtractor : public vtkObject 
{
public:

    static vtkAnalyzeHeaderExtractor *New();
    vtkTypeMacro(vtkAnalyzeHeaderExtractor,vtkObject);

    vtkAnalyzeHeaderExtractor();
    ~vtkAnalyzeHeaderExtractor();

    // Description:
    // Gets data type. It could be:
    // DT_NONE (0), DT_UNKNOWN (0), DT_BINARY (1), 
    // DT_UNSIGNED_CHAR (2), DT_SIGNED_SHORT (4),
    // DT_SIGNED_INT (8), DT_FLOAT (16), DT_COMPLEX (32),
    // DT_DOUBLE (64), DT_RGB (128), and DT_ALL (255).
    vtkGetMacro(DataType, int);

    // Description:
    // Gets voxel order (orientation) 
    vtkGetMacro(Orient, int);

    // Description:
    // Gets Analyze format (3D or 4D). 
    vtkGetMacro(FileFormat, int);

    // Description:
    // Gets bits per pixel; 1, 8, 16, 32, or 64.
    vtkGetMacro(BitsPix, int);

    // Description:
    // Gets the image dimensions.  
    // ImageDim[0] - image X dimension; number of pixels in an image row.
    // ImageDim[1] - image Y dimension; number of pixels in an image column.
    // ImageDim[2] - volume Z dimension; number of slices in a volume.
    // ImageDim[3] - time points; number of volumes in the sequence.
    vtkGetVector4Macro(ImageDim, int);

    // Description:
    // Gets the pix dimensions.  
    // PixDim[0] - voxel width in mm. 
    // PixDim[1] - voxel height in mm. 
    // PixDim[2] - slice thickness in mm. 
    vtkGetVector3Macro(PixDim, float);

    // Description:
    // Gets the pix range.  
    // PixRange[0] - max pixel value for entire sequence. 
    // PixRange[1] - min pixel value for entire sequence. 
    vtkGetVector2Macro(PixRange, int);

    // Description:
    // Reads the Analyze header file. 
    void Read();

    // Description:
    // Determines the byte order. 
    int IsLittleEndian();

    // Description:
    // Displays all header infor. 
    void ShowHeader(); 

    // Description:
    // Specifies a header file name to read. 
    void SetFileName(const char *);
    vtkGetStringMacro(FileName);

private:

    void SwapLong(unsigned char *); 
    void SwapShort(unsigned char *); 
    void SwapHeader();

    char *FileName;

    int Orient;
    int FileFormat;
    int DataType;
    int BitsPix;

    int ImageDim[4];
    float PixDim[3];
    int PixRange[2];

    dsr Hdr;
    int Swapped;
};


#endif
