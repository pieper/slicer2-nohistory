/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageRealtimeScan.h,v $
  Date:      $Date: 2006/10/25 19:36:06 $
  Version:   $Revision: 1.21 $

=========================================================================auto=*/
// .NAME vtkImageRealtimeScan - Get a realtime image from the scanner.
// .SECTION
// vtkImageRealtimeScan just produces images filled with noise.  

#ifndef __vtkImageRealtimeScan_h
#define __vtkImageRealtimeScan_h

#include "vtkImageData.h"
#include "vtkImageSource.h"
#include "vtkMatrix4x4.h"
#include "vtkSlicer.h"


#define LOC_OK 0
#define LOC_NO 1

#define OFFSET_NBYTES      0
#define    LEN_NBYTES      4

#define OFFSET_LOC_NEW     0
#define    LEN_LOC_NEW     2
#define OFFSET_IMG_NEW     OFFSET_LOC_NEW + LEN_LOC_NEW
#define    LEN_IMG_NEW     2
#define OFFSET_LOC_STATUS  OFFSET_IMG_NEW + LEN_IMG_NEW
#define    LEN_LOC_STATUS  2
#define OFFSET_LOC_MATRIX  OFFSET_LOC_STATUS + LEN_LOC_STATUS
#define    LEN_LOC_MATRIX 64

#define OFFSET_IMG_TBLPOS   0
#define    LEN_IMG_TBLPOS   2
#define OFFSET_IMG_PATPOS   OFFSET_IMG_TBLPOS + LEN_IMG_TBLPOS
#define    LEN_IMG_PATPOS   2
#define OFFSET_IMG_IMANUM   OFFSET_IMG_PATPOS + LEN_IMG_PATPOS
#define    LEN_IMG_IMANUM   4 
#define OFFSET_IMG_RECON    OFFSET_IMG_IMANUM + LEN_IMG_IMANUM
#define    LEN_IMG_RECON    4 
#define OFFSET_IMG_MINPIX   OFFSET_IMG_RECON + LEN_IMG_RECON
#define    LEN_IMG_MINPIX   2
#define OFFSET_IMG_MAXPIX   OFFSET_IMG_MINPIX + LEN_IMG_MINPIX
#define    LEN_IMG_MAXPIX   2
#define OFFSET_IMG_DIM      OFFSET_IMG_MAXPIX + LEN_IMG_MAXPIX
#define    LEN_IMG_DIM      6
#define OFFSET_IMG_SPACING  OFFSET_IMG_DIM + LEN_IMG_DIM
#define    LEN_IMG_SPACING 12
#define OFFSET_IMG_MATRIX   OFFSET_IMG_SPACING + LEN_IMG_SPACING
#define    LEN_IMG_MATRIX  64

#define CMD_CLOSE  0 
#define CMD_PING   1
#define CMD_UPDATE 2
#define CMD_HEADER 3
#define CMD_PIXELS 4
#define CMD_POS    5

class VTK_SLICER_BASE_EXPORT vtkImageRealtimeScan : public vtkImageSource 
{
public:
    static vtkImageRealtimeScan *New();
  vtkTypeMacro(vtkImageRealtimeScan,vtkImageSource);
    void PrintSelf(ostream& os, vtkIndent indent);

    void ExecuteInformation();
  
    vtkGetObjectMacro(LocatorMatrix,vtkMatrix4x4);
    vtkGetObjectMacro(ImageMatrix,vtkMatrix4x4);

    int OpenConnection(char *name, int port);
    int CheckConnection();
    int PollRealtime();
    void CloseConnection();
    void SetRefreshImage(int refresh);
    int GetRefreshImage() {return RefreshImage;}

    vtkGetMacro(LocatorStatus, short);
    vtkGetMacro(NewLocator, short);
    vtkGetMacro(NewImage, short);
    vtkGetMacro(PatientPosition, short);
    vtkGetMacro(PatientEntry, short);
    vtkGetMacro(TablePosition, short);
    vtkGetMacro(MinValue, short);
    vtkGetMacro(MaxValue, short);
    vtkGetMacro(Recon, long);
    vtkGetMacro(ImageNum, long);
    
    vtkGetMacro(Test, int);
    vtkSetMacro(Test, int);

    vtkGetMacro(OperatingSystem, int);
    vtkSetMacro(OperatingSystem, int);

    vtkSetStringMacro(TestPrefix);

    int SetPosition(short tblPos, short patEntry, short patPos);

protected:
    vtkImageRealtimeScan();
    ~vtkImageRealtimeScan();

    long SendServer(int cmd);
    void Execute(vtkImageData *data);
    void SwapByte(unsigned char *b, int n);

    /* Modified is automatically set for NewImage, but not NewLocator. */

    short RefreshImage;
    short NewImage;
    short NewLocator;
    short LocatorStatus;
    short TablePosition;
    short PatientPosition;
    short PatientEntry;
    short MinValue;
    short MaxValue;
    long ImageNum;
    long Recon;
    int Test;
    int sockfd;
    char *TestPrefix;
    vtkMatrix4x4 *LocatorMatrix;
    vtkMatrix4x4 *ImageMatrix;

    // Socket connection is platform dependent:
    // -1 - unknown
    // 1  - solaris 
    // 2  - linux
    // 3  - darwin
    // 4  - windows
    int OperatingSystem;

    // 0 - big endian
    // 1 - little endian
    int ByteOrder;
};


#endif

  
