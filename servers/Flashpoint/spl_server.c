/* rtserver.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Intrinsic.h>
#include <xview/xview.h>
#include <xview/frame.h>
#include <xview/panel.h>
#include <sys/param.h>     /* SIGUSR2 */
#include <sys/types.h>     /* getpid */
#include <sys/ioctl.h>     /* FIONREAD */
#include <sys/stat.h>      /* mkfifo, umask */
#include <sys/times.h>     /*  */
#include <signal.h>        /* sigaction */
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>         /* O_WRONLY, O_NDELAY */
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdlib.h>
#include <math.h>
#include <errno.h>        /* errno */
#include "mror_imagebuf.h"
#include "mror.h"

int DBG = 0; 
int DBGALL = 0; 
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

char *progname = NULL;
extern char *sys_errlist[];
float fabs();
double sqrt();

short tblpos=0, patpos=0;
int imageIndex;

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
long readn(fd, ptr, nbytes)
    int fd;
    char *ptr;
    long nbytes;
{
    long nleft, nread;

    nleft = nbytes;

    while (nleft > 0)
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
long writen(fd, ptr, nbytes)
    int fd;
    char *ptr;
    long nbytes;
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

/******************************************************************************
Distance
******************************************************************************/
float Distance(a, b)
    float *a, *b;
{
    float x, y, z;

    x = a[0] - b[0];
    y = a[1] - b[1];
    z = a[2] - b[2];
    return (float)sqrt(x*x + y*y + z*z);
}

/******************************************************************************
Normalize
******************************************************************************/
static void Normalize (v)
    float *v;
{
    float d;

    d = (float) sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
    if (d == 0.0) return;
    v[0] /= d;
    v[1] /= d;
    v[2] /= d;
}

/******************************************************************************
BuildLocatorMatrix
******************************************************************************/
void BuildLocatorMatrix(buf, offset, cnr)
    char *buf;
    int offset;
    float *cnr;
{
    int n;
    float one=1.0, zip=0.0;
                
    n = sizeof(float);
    bcopy(&cnr[0], &buf[offset +    0], n);
    bcopy(&cnr[3], &buf[offset +    n], n);
    bcopy(&cnr[6], &buf[offset +  2*n], n);
    bcopy(&zip,    &buf[offset +  3*n], n);
    bcopy(&cnr[1], &buf[offset +  4*n], n);
    bcopy(&cnr[4], &buf[offset +  5*n], n);
    bcopy(&cnr[7], &buf[offset +  6*n], n);
    bcopy(&zip,    &buf[offset +  7*n], n);
    bcopy(&cnr[2], &buf[offset +  8*n], n);
    bcopy(&cnr[5], &buf[offset +  9*n], n);
    bcopy(&cnr[8], &buf[offset + 10*n], n);
    bcopy(&zip,    &buf[offset + 11*n], n);
    bcopy(&zip,    &buf[offset + 12*n], n);
    bcopy(&zip,    &buf[offset + 13*n], n);
    bcopy(&zip,    &buf[offset + 14*n], n);
    bcopy(&one,    &buf[offset + 15*n], n);
}

/******************************************************************************
BuildImageMatrix
******************************************************************************/
void BuildImageMatrix(buf, offset, cnr)
    char *buf;
    int offset;
    float *cnr;
{
    int n;
    float one=1.0, zip=0.0;
    float Ux[3], Uy[3], Uz[3], T[3];
        
    /*
        "cnr" is in form:

         tl(r) tl(a) tl(s)    0  1  2
         tr(r) tr(a) tr(s)    3  4  5
         br(r) br(a) br(s)    6  7  8

        where tl = top-left, tr = top-right, and br = bottom-right corner points

        Convert this to a matrix that transforms the scanner's coordinate
        frame to that of the image. The image frame has axis vectors Ux, Uy, Uz
        and translation T.  The final matrix looks like:

        Ux(r) Uy(r) Uz(r) T(r)    0  1  2  3
        Ux(a) Uy(a) Uz(a) T(a)    4  5  6  7
        Ux(s) Uy(s) Uz(s) T(s)    8  9 10 11
          0     0     0    1     12 13 14 15
    */
    
    /* Offset from scanner origin to image center is average of tl, br     
    */
    T[0] = (cnr[0] + cnr[6]) / 2.0;
    T[1] = (cnr[1] + cnr[7]) / 2.0;
    T[2] = (cnr[2] + cnr[8]) / 2.0;

    /* Rotate scanner coordinate frame to image coordinate frame with
       matrix R.  Columns of R are Ux, Uy, Uz.
    */
    
    /* Ux = tr - tl
    */
    Ux[0] = cnr[3] - cnr[0];
    Ux[1] = cnr[4] - cnr[1];
    Ux[2] = cnr[5] - cnr[2];
    Normalize(Ux);

    /* Uy = tr - br
    */
    Uy[0] = cnr[3] - cnr[6];
    Uy[1] = cnr[4] - cnr[7];
    Uy[2] = cnr[5] - cnr[8];
    Normalize(Uy);

    /* Uz = Ux x Uy
    */
    Uz[0] = Ux[1]*Uy[2] - Uy[1]*Ux[2];
    Uz[1] = Uy[0]*Ux[2] - Ux[0]*Uy[2];
    Uz[2] = Ux[0]*Uy[1] - Uy[0]*Ux[1];

    /* Matrix = M = T*R = R with T as rightmost column
    */
    n = sizeof(float);
    bcopy(&Ux[0], &buf[offset +    0], n);
    bcopy(&Uy[0], &buf[offset +    n], n);
    bcopy(&Uz[0], &buf[offset +  2*n], n);
    bcopy(&T[0],  &buf[offset +  3*n], n);
    bcopy(&Ux[1], &buf[offset +  4*n], n);
    bcopy(&Uy[1], &buf[offset +  5*n], n);
    bcopy(&Uz[1], &buf[offset +  6*n], n);
    bcopy(&T[1],  &buf[offset +  7*n], n);
    bcopy(&Ux[2], &buf[offset +  8*n], n);
    bcopy(&Uy[2], &buf[offset +  9*n], n);
    bcopy(&Uz[2], &buf[offset + 10*n], n);
    bcopy(&T[2],  &buf[offset + 11*n], n);
    bcopy(&zip,   &buf[offset + 12*n], n);
    bcopy(&zip,   &buf[offset + 13*n], n);
    bcopy(&zip,   &buf[offset + 14*n], n);
    bcopy(&one,   &buf[offset + 15*n], n);
}

/******************************************************************************
Serve
******************************************************************************/
int Serve(fd)
    int fd;
{
    char *msg=NULL;
    int bClose = 0, status, xres, yres, offset;
    float x, y, z, nx, ny, nz, tx, ty, tz, xyz[9], ras[9], spacing[3];
    long totlen, imanum=0, recon=0, i, nbytes, n, len, item;
    short locStatus, prevLocStatus=-2, NewLocator=0, NewImage=0, firstImage=1;
    short minpix, maxpix;
    char pattern[100], buf[200];
    caddr_t ibuf;
    short *pix=NULL, *row=NULL, dim[3];
    int cmd, prevIndex = -2;
    ANNO_UNION wsid;
    float px=0, py=0, pz=0, pnx=0, pny=0, pnz=0, ptx=0, pty=0, ptz=0;
    char cmdname[6][20];
    
    sprintf(cmdname[0], "CLOSE");
    sprintf(cmdname[1], "PING");
    sprintf(cmdname[2], "UPDATE");
    sprintf(cmdname[3], "HEADER");
    sprintf(cmdname[4], "PIXELS");
    sprintf(cmdname[5], "POS");
    
    /* Initialize connection with image buffer */
    msg = (char *)mror_imagebuf_init();
    if (msg) {
        fprintf(stderr, "Error: '%s'\n", msg);
        return -1;
    }

    /* Initialize connection with locator */
    locator_set("pixsys");

    /* Read and respond to commands until client closes connection */
    while (!bClose)
    { 
        NewLocator = NewImage = 0;
        
        /* Read client's request */
        if (DBG && DBGALL) fprintf(stderr, "Server: Reading.\n");
        n = readn(fd, buf, 1);
        if (n < 0) {
            fprintf(stderr, "Server: Read error.\n");
            return -1;
        }

        /* Process command */
        cmd = atoi(buf);
        if (DBG && DBGALL)
            fprintf(stderr, "Server: Read command %d=%s\n",
             cmd, cmdname[cmd]);
        switch(cmd)
        {
        case CMD_CLOSE:

            bClose = 1;
            break;

        case CMD_PING:

            /* Reply with the number of characters that will follow (0).
             */
            nbytes = 0;
            bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
            len = LEN_NBYTES;
            n = writen(fd, buf, len);
            if(n != len) {
                fprintf(stderr, "Server: write error.\n");
                return -1;
            }
            if (DBG) fprintf(stderr, "Server: wrote %d of %d bytes.\n",n,len);
            break;

        case CMD_UPDATE:

            /* Get locator status */
            locStatus = (short)locator_status();
            locStatus = (locStatus == 0) ? LOC_OK : LOC_NO;

            /* Read locator in mm */
            locator_last_xyz_nxyz_txyz(&x, &y, &z, 
                &nx, &ny, &nz, &tx, &ty, &tz);
            
            /* See if locator has new info */
            NewLocator = 1;
            
            if (NewLocator)
            {
                prevLocStatus = locStatus;
                px  = x;   py  = y;   pz  = z;
                pnx = nx;  pny = ny;  pnz = nz;
                ptx = tx;  pty = ty;  ptz = tz;
                
                /* Get locator position in xyz */
                xyz[0] =  x; xyz[1] =  y; xyz[2] =  z;
                xyz[3] = nx; xyz[4] = ny; xyz[5] = nz;
                xyz[6] = tx; xyz[7] = ty; xyz[8] = tz;
                if (DBG && DBGALL) fprintf(stderr, 
            "XYZ: %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f\n",
                    xyz[0], xyz[1], xyz[2], xyz[3], xyz[4], xyz[5],
                    xyz[6], xyz[7], xyz[8]);

                /* Convert xyz to ras */
                xyz_to_ras(&xyz[0], &ras[0], patpos, tblpos);    
                xyz_to_ras(&xyz[3], &ras[3], patpos, tblpos);    
                xyz_to_ras(&xyz[6], &ras[6], patpos, tblpos);    
                if (DBG && DBGALL) fprintf(stderr, 
            "RAS: %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f\n",
                    ras[0], ras[1], ras[2], ras[3], ras[4], ras[5],
                    ras[6], ras[7], ras[8]);
            }

            /* See if image is new */
            imageIndex = get_current_image_index();
            if (firstImage) {
                prevIndex = imageIndex;
                firstImage = 0;
            }

            /* Don't skip images 
                BUT, the imageIndex rolls over, so roll with the punches.
            */
            if (imageIndex != prevIndex) {
                imageIndex = prevIndex + 1;
                if (imageIndex > 79)
                    imageIndex = 0;
                NewImage = 1;
                prevIndex = imageIndex;
            }

            if (DBG) fprintf(stderr, 
                "CMD_UPDATE: NewImage=%d, NewLocator=%d, Status=%d\n", 
                NewImage, NewLocator, locStatus);

            /* Write response to client 
            */
            if (NewLocator)
            {
                /* Respond with nbytes
                */
                nbytes = LEN_LOC_NEW + LEN_IMG_NEW + 
                    LEN_LOC_STATUS + LEN_LOC_MATRIX;
                bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
                len = LEN_NBYTES;
                n = writen(fd, buf, len);
                if(n != len) {
                    fprintf(stderr, "Server: write error '%s'.\n", buf);
                    return -1;
                }

                /* Write "new" flags and locator matrix to client 
                */
                bcopy(&NewLocator, &buf[OFFSET_LOC_NEW],    LEN_LOC_NEW);
                bcopy(&NewImage  , &buf[OFFSET_IMG_NEW],    LEN_IMG_NEW);
                bcopy(&locStatus,  &buf[OFFSET_LOC_STATUS], LEN_LOC_STATUS);
                BuildLocatorMatrix(buf, OFFSET_LOC_MATRIX, ras);
                len = nbytes;
                n = writen(fd, buf, len);
                if(n != len) {
                    fprintf(stderr, "Server: write error '%s'.\n", buf);
                    return -1;
                }
            }
            else
            {
                /* Respond with nbytes 
                */
                nbytes = LEN_LOC_NEW + LEN_IMG_NEW; 
                bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
                len = LEN_NBYTES;
                n = writen(fd, buf, len);
                if(n != len) {
                    fprintf(stderr, "Server: write error '%s'.\n", buf);
                    return -1;
                }
                
                /* Write "new" flags */
                bcopy(&NewLocator, &buf[OFFSET_LOC_NEW], LEN_LOC_NEW);
                bcopy(&NewImage  , &buf[OFFSET_IMG_NEW], LEN_IMG_NEW);
                len = nbytes;
                n = writen(fd, buf, len);
                if(n != len) {
                    fprintf(stderr, "Server: write error '%s'.\n", buf);
                    return -1;
                }
            }
            break;

        case CMD_HEADER:

            /* Write response to client as number of bytes coming
            */
            nbytes = LEN_IMG_PATPOS + LEN_IMG_TBLPOS + 
                LEN_IMG_IMANUM + LEN_IMG_RECON +
                LEN_IMG_MINPIX + LEN_IMG_MAXPIX + 
                LEN_IMG_DIM + LEN_IMG_SPACING + LEN_IMG_MATRIX;
            bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
            len = LEN_NBYTES;
            n = writen(fd, buf, len);
            if(n != len) {
                fprintf(stderr, "Server: header response write error.\n");
                return -1;
            }

            /* Read header data 
            */
            ibuf = (caddr_t)mrt_imagebuf_ptr(0,imageIndex);

            /* Corner points */
/*
These are the other routines that I'm obviously not using.
mrt_hdrdata(ibuf,img,off,len,item)
mrt_pixdata_ptr(ibuf,img,&xres,&yres) xres, yres int*, ibuf,img*
*/
        status = (int)mror_hdrdata(ibuf,
                    MROR_HDR_CORNER_PT_OFFSET, MROR_HDR_CORNER_PT_LEN, xyz);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}
            if (DBG && DBGALL) fprintf(stderr, 
            "XYZ: %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f\n",
                xyz[0], xyz[1], xyz[2], xyz[3], xyz[4], xyz[5],
                xyz[6], xyz[7], xyz[8]);

            /* Patient, Table position */
            status = (int)mror_hdrdata(ibuf,
                MROR_HDR_CONT_WSID_OFFSET, MROR_HDR_CONT_WSID_LEN, &wsid);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}
            patpos = wsid.field.patpos;
            tblpos = wsid.field.tblpos;
            
            /* Convert XYZ (cm) coordinates to RAS (mm) */
            xyz_to_ras(&xyz[0], &ras[0], patpos, tblpos);    
            xyz_to_ras(&xyz[3], &ras[3], patpos, tblpos);    
            xyz_to_ras(&xyz[6], &ras[6], patpos, tblpos);
            for (i=0; i<9; i++)
                ras[i] *= 10.0;    
            if (DBG && DBGALL) fprintf(stderr, 
            "RAS: %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f, %6.2f %6.2f %6.2f\n",
                ras[0], ras[1], ras[2], ras[3], ras[4], ras[5],
                ras[6], ras[7], ras[8]);
            if (DBG) fprintf(stderr, "patpos=%d, tblpos=%d\n", patpos, tblpos);

            /* Read dimensions */
            pix = (short *)mror_pixdata(ibuf, &xres, &yres);
            dim[0] = xres;
            dim[1] = yres;
            dim[2] = 1;
        
            /* Spacing */    
            spacing[0] = Distance(&ras[0], &ras[3]) / (float)dim[0];
            spacing[1] = Distance(&ras[3], &ras[6]) / (float)dim[1];
            status = (int)mror_hdrdata(ibuf, MROR_HDR_CONT_SLTHICK_OFFSET, 
                MROR_HDR_CONT_SLTHICK_LEN, &spacing[2]);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}

            /* Pixel range */
            status = (int)mror_hdrdata(ibuf, TPS_PIXHST_MIN_OFFSET, 
                TPS_PIXHST_MIN_LEN, &minpix);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}
            status = (int)mror_hdrdata(ibuf, TPS_PIXHST_MAX_OFFSET, 
                TPS_PIXHST_MAX_LEN, &maxpix);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}

            /* Recon data type */
            status = (int)mror_hdrdata(ibuf, MROR_HDR_RCN_DATA_TYPE_OFFSET, 
                MROR_HDR_RCN_DATA_TYPE_LEN, &recon);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}

            /* Image number */
            status = (int)mror_hdrdata(ibuf, MRT_INFO_OFFSET, 
                sizeof(long), &imanum);
            if (status) {fprintf(stderr, "Failed read hdr.\n"); return -1;}
            
            /* Debug */
            if (DBG && DBGALL) fprintf(stderr, 
                "dim: %d %d %d, spacing %g %g %g\n",
                 dim[0], dim[1], dim[2], spacing[0], spacing[1], spacing[2]);
            if (DBG) fprintf(stderr, 
                "CMD_HEADER: range: %d %d, recon: %d, ima: %d\n", 
                minpix, maxpix, recon, imanum);

            bcopy(&tblpos,  &buf[OFFSET_IMG_TBLPOS ], LEN_IMG_TBLPOS);
            bcopy(&patpos,  &buf[OFFSET_IMG_PATPOS ], LEN_IMG_PATPOS);
            bcopy(&recon,   &buf[OFFSET_IMG_RECON  ], LEN_IMG_RECON);
            bcopy(&imanum,  &buf[OFFSET_IMG_IMANUM ], LEN_IMG_IMANUM);
            bcopy(&minpix,  &buf[OFFSET_IMG_MINPIX ], LEN_IMG_MINPIX);
            bcopy(&maxpix,  &buf[OFFSET_IMG_MAXPIX ], LEN_IMG_MAXPIX);
            bcopy(dim,      &buf[OFFSET_IMG_DIM    ], LEN_IMG_DIM);
            bcopy(spacing,  &buf[OFFSET_IMG_SPACING], LEN_IMG_SPACING);
            /* Build buffer of: dim, spacing, matrix
             */
            BuildImageMatrix(buf, OFFSET_IMG_MATRIX, ras);

            /* Write header data to client */
            len = nbytes;
            n = writen(fd, buf, len);
            if(n != len) {
                fprintf(stderr, "Server: header data write error\n");
                return -1;
            }
            break;

        case CMD_PIXELS:

            /* Get pointer to image pixels */
            ibuf = (caddr_t)mrt_imagebuf_ptr(0,imageIndex);
            pix = (short *)mror_pixdata(ibuf, &xres, &yres);
            if (DBG) fprintf(stderr, 
                "CMD_PIXELS: xres=%d, yres=%d, ctr pix=%d\n",
                xres, yres, pix[xres*yres/2 + xres/2]);

            /* Write response to client.
            */
            nbytes = dim[0] * dim[1] * sizeof(short);
            bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
            len = LEN_NBYTES;
            n = writen(fd, buf, len);
            if (n != len) {
                fprintf(stderr, "Server: write error '%s'.\n", buf);
                return -1;
            }
            
            /* Send pixels one row at a time, beginning with the bottom
               row of the image (top, left corner of image is coord 0,0).
            */
            nx = dim[0];
            ny = dim[1];
            len = nx * sizeof(short);
            totlen = 0;
            for (y = 0; y < ny; y++)
            {
                i = (ny-1-y)*nx;
                row = &pix[i];
                n = writen(fd, (char *)row, len);
                totlen += n;
                if (n != len) {
                    fprintf(stderr, "Server: write error.\n");
                    return -1;
                }
            }
            if (DBG) fprintf(stderr, "CMD_PIXELS: Wrote %ld bytes\n", totlen);
            break;

        case CMD_POS:
            /* Read the data */
            n = readn(fd, buf, 4);
            if (n < 4) {
                fprintf(stderr, "Server: Read error.\n");
                return -1;
            }
            bcopy(&buf[OFFSET_IMG_PATPOS], &patpos, LEN_IMG_PATPOS);
            bcopy(&buf[OFFSET_IMG_TBLPOS], &tblpos, LEN_IMG_TBLPOS);

            /* Reply with the number of characters that will follow (0).
             */
            nbytes = 0;
            bcopy(&nbytes, &buf[OFFSET_NBYTES], LEN_NBYTES);
            len = LEN_NBYTES;
            n = writen(fd, buf, len);
            if(n != len) {
                fprintf(stderr, "Server: write error.\n");
                return -1;
            }
            if (DBG) fprintf(stderr, "CMD_POS: patpos=%d tblpos=%d\n",
                patpos, tblpos);
            break;

        default:
            break;
        }
    }
    return 0;
}

/******************************************************************************
main

PARAMETERS:
    arg1 -- socket port number 
******************************************************************************/
main(argc, argv)
    int argc;
    char *argv[];
{
    int sockfd, newsockfd, clilen, childpid, status, port;
    struct sockaddr_in cli_addr, serv_addr;
    struct hostent *hostptr;

    if (argc < 2)
    {
        fprintf(stderr, "usage: %s portnum [-v]\n", argv[0]);
        exit(1);
    }
    progname = argv[0];
    port = atoi(argv[1]);
    if (argc == 3)
        DBG = 1;

    /* NETWORK */

    /* Open a TCP internet stream socket */
    if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        fprintf(stderr, "Server can't open socket\n");
        exit(1);
    }
 
    /* Bind local address so that the client can send to me. */
    bzero((char*) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family      = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port        = htons(port);
    if (bind(sockfd, (struct sockaddr *) &serv_addr,
        sizeof(serv_addr)) < 0)
    {
        fprintf(stderr, "Server can't bind local adrs.\n");
        exit(1);
    }
    listen(sockfd, 5);
 
    for (;;)
    {
        fprintf(stderr, "Server listening on port %d\n", port);
        clilen = sizeof(cli_addr);
        newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr,
            &clilen);
 
        if (newsockfd < 0)
        {
            fprintf(stderr, "Server: accept error\n");
            exit(1);
        }
        fprintf(stderr, "Server: accepting.\n");

        if (fork() == 0) {
            /* Child */
            close(sockfd);
            status = Serve(newsockfd);
            close(newsockfd);
            if (status < 0)
                fprintf(stderr, "Server exiting due to error.\n");
            fprintf(stderr, "Server's child exiting.\n");
            exit(status);
        }

        /* Parent */
        close(newsockfd);
    }
}    

