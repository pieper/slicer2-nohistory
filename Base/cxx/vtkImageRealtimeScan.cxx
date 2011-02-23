/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkImageRealtimeScan.cxx,v $
  Date:      $Date: 2006/03/06 19:02:26 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h> // memcpy
//#include <iostream.h>
#include <string.h>
#include <fcntl.h>
#ifndef _WIN32
#include <strings.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <algorithm> // required for std::swap
#endif
#include "vtkImageRealtimeScan.h"
#include "vtkObjectFactory.h"

// convert big-endian to little-endian
#define DoByteSwap(x) SwapByte((unsigned char *) &x,sizeof(x))

static int Read16BitImage (const char *filePrefix, const char *filePattern, 
    int start, int end, int nx, int ny, int skip, int SwapBytes, 
    char *fileName, short *image);

//----------------------------------------------------------------------------
vtkImageRealtimeScan::vtkImageRealtimeScan()
{
    RefreshImage = 0;
    NewImage = 0;
    NewLocator = 0;
    LocatorStatus = LOC_NO;
    Test = 0;
    TestPrefix = NULL;
    LocatorMatrix = vtkMatrix4x4::New(); // Identity
    ImageMatrix   = vtkMatrix4x4::New();
    sockfd = -1;
    PatientPosition = PatientEntry = TablePosition = 0;
    MinValue = MaxValue = 0;
    Recon = 0;
    ImageNum = 0;

    // test byte order
    short int word = 0x0001;
    char *byte = (char *) &word;
    ByteOrder = (byte[0] ? 1 : 0);
}

//----------------------------------------------------------------------------
vtkImageRealtimeScan* vtkImageRealtimeScan::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkImageRealtimeScan");
  if(ret)
    {
    return (vtkImageRealtimeScan*)ret;
    }
  // If the factory was unable to create the object, then create it here.
  return new vtkImageRealtimeScan;
}

vtkImageRealtimeScan::~vtkImageRealtimeScan()
{
    if (this->TestPrefix) delete [] this->TestPrefix;
    LocatorMatrix->Delete();
    ImageMatrix->Delete();
}

#ifndef _WIN32

/******************************************************************************
readn

This procedure reads from a socket according to page 279 of "UNIX Network
Programming" by W. Ricard Stevens, 1990.

PARAMETERS:
        fd     -- file descriptor for socket to read from
        ptr    -- pointer to buffer to read into
        nbytes -- number of bytes to read
RETURNS:
        number of bytes read on sucess, else negative on error
******************************************************************************/
static long readn(int fd, char *ptr, long nbytes)
{
    long nleft, nread;

    nleft = nbytes;

    while (nleft> 0)
    {
        nread = read(fd, ptr, nleft);

        /* check for error */
        if (nread < 0)
            return nread;

        /* check for EOF */
        else if (nread == 0)
            break;

        nleft -= nread;
        ptr  += nread;
    }
    *ptr = 0;
    return nbytes - nleft;
}

/******************************************************************************
writen

This procedure writes to a socket according to page 279 of "UNIX Network
Programming" by W. Ricard Stevens, 1990.

PARAMETERS:
        fd     -- file descriptor for socket to read from
        ptr    -- pointer to buffer to read into
        nbytes -- number of bytes to write
RETURNS:
        number of bytes written on sucess, else negative on error
******************************************************************************/
static long writen(int fd, char *ptr, long nbytes)
{
    long nleft, nwritten;

    nleft = nbytes;

    while (nleft > 0)
    {
        nwritten = write(fd, ptr, nleft);

        /* Check for error */
        if (nwritten <= 0)
            return nwritten;

        nleft -= nwritten;
        ptr   += nwritten;
    }
    return nbytes - nleft;
}

#endif

/******************************************************************************
SendServer

Sends command 'cmd' to the server.
******************************************************************************/
long vtkImageRealtimeScan::SendServer(int cmd)
{
    long nbytes = 0;
#ifndef _WIN32
    long n, len;
    char buf[LEN_NBYTES];
#endif
    
    if (Test) return 0;

    // Return if not connected yet
    if (sockfd < 0) return -1;

#ifndef _WIN32
    
    sprintf(buf, "%d", cmd);
    len = strlen(buf);
    n = writen(sockfd, buf, len);
    if (n < len) {
        // This happens when the server crashes.
        fprintf(stderr, "Client wrote %ld instead of %ld bytes.\n",n,len);
        close(sockfd);
        return -1;
    }

    len = LEN_NBYTES;
    n = readn(sockfd, buf, len);
    if (n < 0) {
        fprintf(stderr, "Client: read error.\n");
        close(sockfd);
        return -1;
    }
    bcopy(&buf[OFFSET_NBYTES], &nbytes, LEN_NBYTES);
    nbytes = ntohl(nbytes);

#endif

    return nbytes;
}

/******************************************************************************
SetPosition

Sends the table and patient positions to the server.  The server will then
use these when transforming locator and image points from XYZ to RAS
coordinate systems.
******************************************************************************/
int vtkImageRealtimeScan::SetPosition(short tblPos, short patEntry, 
                                      short patPos)
{
    long nbytes=0;
#ifndef _WIN32
    long len, n;
    char buf[LEN_NBYTES];
#endif
    
    if (Test) return 0;

    // Return if not connected yet
    if (sockfd < 0) return -1;

#ifndef _WIN32

    // Send command number    
    sprintf(buf, "%d", CMD_POS);
    len = strlen(buf);
    n = writen(sockfd, buf, len);
    if (n < len) {
        // This happens when the server crashes.
        vtkErrorMacro(<< "Client: wrote " << n << " instead of " << len <<
            " bytes.");
        close(sockfd);
        return -1;
    }

    // Encode patEntry and patPos into patPos
    // tblPos:
    //  0 = front
    //  1 = side
    // patPos:
    //  0 = head-first, supine
    //  1 = head-first, prone
    //  2 = head-first, left-decub
    //  3 = head-first, right-decub
    //  4 = feet-first, supine
    //  5 = feet-first, prone
    //  6 = feet-first, left-decub
    //  7 = feet-first, right-decub
    patPos = patPos + patEntry * 4;

    // Send data:
    short tblPos2 = htons(tblPos);
    bcopy(&tblPos2, &buf[OFFSET_IMG_TBLPOS], LEN_IMG_TBLPOS);
    short patPos2 = htons(patPos);
    bcopy(&patPos2, &buf[OFFSET_IMG_PATPOS], LEN_IMG_PATPOS);
    len = LEN_IMG_TBLPOS + LEN_IMG_PATPOS;
    n = writen(sockfd, buf, len);
    if(n != len) {
        vtkErrorMacro(<< "Client: data write error\n"); 
        return -1;
    }

    // Update member variables when transfer successful
    this->TablePosition = tblPos;
    this->PatientPosition = patPos % 4;
     this->PatientEntry = patPos / 4;

    // Read server's reply
    len = LEN_NBYTES;
    n = readn(sockfd, buf, len);
    if (n < 0) {
        vtkErrorMacro(<< "Client: connection stinks!");
        close(sockfd);
        return -1;
    }
    bcopy(&buf[OFFSET_NBYTES], &nbytes, LEN_NBYTES);
    nbytes = ntohl(nbytes);

#endif

    return nbytes;
}
/******************************************************************************
OpenConnection
******************************************************************************/
int vtkImageRealtimeScan::OpenConnection(char *hostname, int port)
{
#ifndef _WIN32
    struct sockaddr_in serv_addr;
    struct hostent *hostptr;
#endif
    
    // If already connected, then just verify the connection
    if (sockfd >= 0)
        return CheckConnection();

    if (Test) {
        sockfd = 1;
        return CheckConnection();
    }

#ifndef _WIN32

    if((hostptr = gethostbyname(hostname)) == NULL) {
        fprintf(stderr,"Bad hostname: [%s]\n",hostname);
        return -1;
    }

    if (OperatingSystem == 1)  // solaris
    {
        bzero((char *)&serv_addr, sizeof(serv_addr));
        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port   = port;

        bcopy(hostptr->h_addr, (char *)&serv_addr.sin_addr, hostptr->h_length);

        if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
            fprintf(stderr, "Socket allocation failed.\n");
            return -1;
        }

        if (connect(sockfd, (sockaddr*)&serv_addr, sizeof(serv_addr)) == -1) {
            fprintf(stderr, "Cannot connect to '%s'.\n", hostname);
            close(sockfd);
            return -1;
        }
    } 
    else if (OperatingSystem == 2)  // linux
    {
        fprintf(stderr,"Hostname %s obtained\n",hostname);

        if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
            fprintf(stderr, "Socket allocation failed.\n");
            return -1;
        }

        fprintf(stderr, "Socket allocation done.\n");

        int error;
        struct sockaddr_in sin;
        memcpy(&sin.sin_addr.s_addr,hostptr->h_addr,hostptr->h_length);
        sin.sin_family = AF_INET;
        sin.sin_port = htons(port);
        if(connect(sockfd,(struct sockaddr *)&sin,sizeof(sin))==-1){
            fprintf(stderr, "Cannot connect to '%s' because of ERROR %d.\n", hostname, error);
            close(sockfd);
            return -1;
        }
        fprintf(stderr, "Connection established to '%s'.\n", hostname);
    }

#endif

    return CheckConnection();
}

/******************************************************************************
CheckConnection
******************************************************************************/
int vtkImageRealtimeScan::CheckConnection()
{
    // Check Client/Server connection with one ping.
    if (SendServer(CMD_PING) < 0) {
        vtkErrorMacro(<< "Client: connection stinks!");
        return -1;
    }
    return 0;
}

/******************************************************************************
CloseConnection
******************************************************************************/
void vtkImageRealtimeScan::CloseConnection()
{
    if (sockfd < 0) return;

    SendServer(CMD_CLOSE);
#ifndef _WIN32
    close(sockfd);
#endif
    sockfd = -1;
}

/******************************************************************************
SetRefreshImage
******************************************************************************/
void vtkImageRealtimeScan::SetRefreshImage(int refresh)
{
    if (refresh == 0)
    {
        // I don't want it to Execute and fetch an image when I'm turning
        // refresh off.
        RefreshImage = refresh;
    }
    else
    {   
        // No Change
        if (RefreshImage != 0)
            return;
 
        // Start refreshing, and also fetch the previous image
        RefreshImage = refresh;
        this->Modified();
    }
}

/******************************************************************************
PollRealtime
******************************************************************************/
int vtkImageRealtimeScan::PollRealtime()
{
    static char buf[200];
    
#ifndef _WIN32
    long n, nbytes;
    vtkFloatingPointType matrix[16];
    int i, j;
    
    // Request the update info
    nbytes = SendServer(CMD_UPDATE);
    if (nbytes < 0) return -1;

    // Read the update info
    n = readn(sockfd, buf, nbytes);
    if (n < 0) {
        vtkErrorMacro(<< "Client: read error.");
        close(sockfd);
        sockfd = -1;
        return -1;
    }

    // Parse the update info
    bcopy(&buf[OFFSET_LOC_NEW], &NewLocator, LEN_LOC_NEW);
    NewLocator = ntohs(NewLocator);

    bcopy(&buf[OFFSET_IMG_NEW], &NewImage,   LEN_IMG_NEW);
    NewImage = ntohs(NewImage);

    // Read locator info if it exists
    if (NewLocator) {
        bcopy(&buf[OFFSET_LOC_STATUS], &LocatorStatus, LEN_LOC_STATUS);
        LocatorStatus = ntohs(LocatorStatus);

        bcopy(&buf[OFFSET_LOC_MATRIX], matrix, LEN_LOC_MATRIX);
        if (ByteOrder)  // little endian 
        {
            for (int ii = 0; ii < 16; ii++)
            {
                DoByteSwap(matrix[ii]);
            }
        }

        for (i=0; i<4; i++) {
            for (j=0; j<4; j++) {
                LocatorMatrix->SetElement(i,j,matrix[i*4+j]);
            }
        }
    }

#else
    NewLocator = 0;
    NewImage = 0;
#endif

    // Read image info if it exists
    if (NewImage && RefreshImage) {
        // Force Execute() to run on the next call to Update()
        this->Modified();  
    }
    return 0;
}

//----------------------------------------------------------------------------
void vtkImageRealtimeScan::ExecuteInformation()
{
    vtkFloatingPointType spacing[3];
    short dim[3];
    int ext[6];
#ifndef _WIN32
    int i, j;
    long n, nbytes;
#endif
    static char buf[200];
    
    // Request header info
    if (!Test && sockfd >= 0) {
#ifndef _WIN32
        nbytes = SendServer(CMD_HEADER);
        if (nbytes < 0) return;
        n = readn(sockfd, buf, nbytes);
        if (n < 0) {
            vtkErrorMacro(<< "Client: read " << n << " bytes instead of " 
                << nbytes);
            close(sockfd);
            return;
        }
#endif
    }

    // Dimensions must be fixed in order to not need reformatting
    dim[0] = 256;
    dim[1] = 256;
    dim[2] = 1;

    // Read header info 
    if (Test || sockfd < 0) 
    {
        spacing[0] = 0.9375;
        spacing[1] = 0.9375;
        spacing[2] = 1.5;
    }
    else
    {
#ifndef _WIN32
    vtkFloatingPointType matrix[16];
    short patPos;
        bcopy(&buf[OFFSET_IMG_TBLPOS],  &(this->TablePosition), LEN_IMG_TBLPOS);
        this->TablePosition = ntohs(this->TablePosition);
        bcopy(&buf[OFFSET_IMG_PATPOS],  &patPos, LEN_IMG_PATPOS);
        patPos = ntohs(patPos);
        bcopy(&buf[OFFSET_IMG_IMANUM],  &(this->ImageNum), LEN_IMG_IMANUM);
        this->ImageNum = ntohl(this->ImageNum);
        bcopy(&buf[OFFSET_IMG_RECON],   &(this->Recon),    LEN_IMG_RECON);
        this->Recon = ntohl(this->Recon);
        bcopy(&buf[OFFSET_IMG_MINPIX],  &(this->MinValue), LEN_IMG_MINPIX);
        this->MinValue = ntohs(this->MinValue);
        bcopy(&buf[OFFSET_IMG_MAXPIX],  &(this->MaxValue), LEN_IMG_MAXPIX);
        this->MaxValue = ntohs(this->MaxValue);
        bcopy(&buf[OFFSET_IMG_DIM    ], dim    , LEN_IMG_DIM);
        for (int ii = 0; ii < 3; ii++)
        {
            dim[ii] = ntohs(dim[ii]);
        }
        bcopy(&buf[OFFSET_IMG_SPACING], spacing, LEN_IMG_SPACING);
        bcopy(&buf[OFFSET_IMG_MATRIX ], matrix,  LEN_IMG_MATRIX);    
        if (ByteOrder)  // little endian 
        {
            for (int ii = 0; ii < 3; ii++)
            {
                DoByteSwap(spacing[ii]);
            }
            for (int ii = 0; ii < 16; ii++)
            {
                DoByteSwap(matrix[ii]);
            }
        }
    
        // Decode patPos into a position and entry value
        this->PatientPosition = patPos % 4;
        this->PatientEntry = patPos / 4;
        
        if (dim[0] != 256 || dim[1] != 256 || dim[2] != 1)
        {
            vtkErrorMacro(<< "Image dimensions are " << dim[0] << "x" <<
                dim[1] << "x" << dim[2] << " instead of 256x256x1.");
            return;
        }
 
        /* Matrix transforms the scanner's coordinate frame to that of
        the image. The image frame has axis vectors Ux, Uy, Uz
        and translation T.  The final matrix looks like:
    
        Ux(r) Uy(r) Uz(r) T(r)
        Ux(a) Uy(a) Uz(a) T(a)
        Ux(s) Uy(s) Uz(s) T(s)
          0     0     0    1
        */
        for (i=0; i<4; i++) {
            for (j=0; j<4; j++) {
                ImageMatrix->SetElement(i,j,matrix[i*4+j]);
            }
        }
#endif
    }

    // Set output parameters

    ext[0] = ext[2] = ext[4] = 0;
    ext[1] = dim[0] - 1;
    ext[3] = dim[1] - 1; 
    ext[5] = dim[2] - 1; 

  // normal vtk crap for the UpdateInformation procedure
 
  vtkImageData *output = this->GetOutput();

  output->SetWholeExtent(ext);
  output->SetScalarType(VTK_SHORT);
  output->SetNumberOfScalarComponents(1);
  output->SetSpacing(spacing);
}

void vtkImageRealtimeScan::Execute(vtkImageData *data)
{
    long numPoints;
    short *outPtr;
    int ny, nx;
    int errcode;
    int *outExt;
#ifndef _WIN32
    long n, nbytes;
    short *image;
    int idxR, idxY, idxZ, outIncX, outIncY, outIncZ;
    int rowLength;
    char *img;
#endif
     char fileName[1000];
 
    if (data->GetScalarType() != VTK_SHORT)
    {
        vtkErrorMacro("Execute: This source only outputs shorts");
    }
    outExt = data->GetExtent();
    nx = outExt[3]-outExt[2]+1;
    ny = outExt[1]-outExt[0]+1;
    numPoints = nx*ny*(outExt[5]-outExt[4]+1);
    outPtr = (short *) data->GetScalarPointer(outExt[0],outExt[2],outExt[4]);

    if (Test)
    {
        if (this->TestPrefix == NULL)
            this->SetTestPrefix("I");
        errcode = Read16BitImage(this->TestPrefix, "%s.%.3d", 1, 1, 
            256, 256, 7904, 1, fileName, outPtr);
        if (errcode) {
            switch (errcode) {
            case 1:  vtkErrorMacro(<< "Open '" << fileName << "'"); break;
            case 2:  vtkErrorMacro(<< "Read '" << fileName << "'"); break;
            default: vtkErrorMacro(<< "???: '" << fileName << "'");
            }
            return;
        }
    }
    else {
#ifndef _WIN32
        nbytes = SendServer(CMD_PIXELS);
        if (nbytes < 0) return;
        if (nbytes != numPoints * sizeof(short)) {
            vtkErrorMacro(<< "Pixel data is " << nbytes << " bytes instead of "
                << numPoints*sizeof(short));
            return;
        }

        img = new char[nbytes];
        n = readn(sockfd, img, nbytes);
        if (n < 0) {
            vtkErrorMacro(<< "Client: read error.");
            close(sockfd);
            return;
        }
            
        memcpy(outPtr, img, nbytes);
        fprintf(stderr, "New image, ctr pix = %d\n", outPtr[ny/2*nx/2]);
        delete [] img;
#endif
    }
}

void vtkImageRealtimeScan::PrintSelf(ostream& os, vtkIndent indent)
{
    vtkImageSource::PrintSelf(os,indent);

    os << indent << "LocatorStatus: " << LocatorStatus<< "\n";
}


// errcode:
//  0 success, 1 can't open file, 2 can't read file
static int Read16BitImage (const char *filePrefix, const char *filePattern, 
    int start, int end, int nx, int ny, int skip, int swapBytes,
    char *fileName, short *image)
{
    FILE *fp;
    int z, nz = end-start+1;
    long i, nxy = nx*ny, nxyz = nxy*nz;
    short *ptr;

    for (z=start; z <= end; z++)
    {
        sprintf(fileName, filePattern, filePrefix, z);
        fp = fopen(fileName, "rb");
        if (fp == NULL)
            return 1;
        if (skip)
            fseek(fp, skip, 0);

        ptr = &image[nxy*(z-start)+nx*(ny-1)];

        for (int j=0; j < ny; j++, ptr -= nx)
        {
            if ( !fread(ptr, sizeof(short), nx, fp) ) {
                return 2;
            }
        }
        fclose(fp);
    }

    // Binary data needs it bytes put in reverse order
    // if written on a Big Endian machine and read on a
    // Little Endian machine, or visa-versa.
    if (swapBytes) 
    {
        unsigned char *bytes = (unsigned char *) image;
        unsigned char tmp;
        for (i = 0; i < nxyz; i++, bytes += 2) 
        {
            tmp = *bytes; 
            *bytes = *(bytes + 1); 
            *(bytes + 1) = tmp;
        }
    }
    return 0;
}

// convert big-endian to little-endian
void vtkImageRealtimeScan::SwapByte(unsigned char *b, int n)
{
    register int i = 0;
    register int j = n-1;

    while (i < j)
    {
        std::swap(b[i], b[j]);
        i++, j--;
    }
}



