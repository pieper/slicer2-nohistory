
/*
 * ++
 * 
 * Module:      spl_read_image.c
 * 
 * Version:     1
 * 
 * Facility:    Read any image the SPL has in compressed or regular format
 * 
 * Abstract:    These routines provide i/o support SPL images
 * input files.
 * 
 * Currently supports: 1 signa    - signa files with headers 
                       2 genesis  - genesis files with headers 
                       3 siemens  - siemens files with headers 
                       4 noh2dvax - 2d * files, noheaders, 
                       4 spect    - spect "brick"
 * 
 * 
 * Environment: Sun Unix
 * 
 * Author[s]: S. Warfield, M. Halle
 * 
 * Modified by: M.C. Anderson
 * 
 * 
 */

/*
 * Include files:
 */

#include <stdio.h>
#include <math.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/param.h>
#include <unistd.h>
#include "idbm_err_def.h"
#ifdef  GNU
#include <string.h>
#else
#include <string.h>
#endif
#include <errno.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <assert.h>
#include "image_info_private.h"
#include "signa_header.h"
#include "genesis_hdr_def.h"
#include "genesis_pixeldata.h"
#include "imageFileOffsets.h"
#include "spect.h"

/*
 * Macros:
 */

#define NORMAL 1
#define PIPE 2

/*
 * Typedefs
 */

extern double   pow();
typedef void ImageInfo;


typedef struct {
  unsigned        sign:1;
  unsigned        exponent:7;
  unsigned        mantissa:24;
}               DG_FLOAT;

/*
 * Own storage:
 */

#ifndef lint
static char    *sccs_id = "@(#)spl_read_image.c 6.18";
#endif


unsigned short  ushortval;

/*
 * general-purpose variables
 */
int i;
unsigned short  convertShortFromGE();
unsigned char  *findUncompressedSizeOfCompressedFile();

/* FILE OPERATIONS */
long 
fileSize(fname)
  char           *fname;
{
  struct stat     statBuf;

  if (stat(fname, &statBuf) == -1) {
    fprintf(stderr, "Failed to stat %s\n", fname);
    return -1;
  }
  return statBuf.st_size;
}

long 
headerSize(fileSize)
  int             fileSize;
{
  long            headerSize = -1;

  if (fileSize >= 512 * 512 * 2) {
    headerSize = fileSize - 512 * 512 * 2;
  } else if (fileSize >= 256 * 256 * 2) {
    headerSize = fileSize - 256 * 256 * 2;
  } else if (fileSize >= 128 * 128 * 2) {
    headerSize = fileSize - 128 * 128 * 2;
  } else if (fileSize >= 64 * 64 * 2) {
    headerSize = fileSize - 64 * 64 * 2;
  }
  return headerSize;
}

int 
spl_read_image(
    headerBuffer, 
    data, ii, image_number)

  unsigned char **headerBuffer;
  unsigned  short         **data;
  ImageInfo *ii;
  int       image_number;
{
  ImageInfo_private *iip = (ImageInfo_private *)ii;
  long            fsize = -1;
  long            hsize = -1;
  int             npixels = -1;
  int             i;
  FILE           *fp = NULL;
  char           *newfname = NULL;
  unsigned char  *tmpdata = NULL;
  int             readCompressed = 0;
  int            numpixelsExpected;
  int            headersize;
  char           fname[MAXPATHLEN];


  assert(data != NULL);
  assert(headerBuffer != NULL);

  sprintf(fname,iip->file_pattern,iip->input_prefix, image_number);

  headersize = 0;
  readCompressed = 0;
  readCompressed = fileIsCompressed(fname, &newfname);
  if (readCompressed == 1) {
    tmpdata = findUncompressedSizeOfCompressedFile(newfname, &fsize);
    assert(tmpdata != NULL);
    free(newfname);
    hsize = headerSize(fsize);
  } else {
    /* open the file */
    fp = fopen(fname, "rb");
    if (fp == NULL) {
      fprintf(stderr, "Failed to open file \"%s\"\n", fname);
      perror("spl_read_image");
      return -1;
    }
    fsize = fileSize(fname);
    if (fsize == -1) {
      return -1;
    }
    hsize = headerSize(fsize);
    if (hsize == -1) {
      return -1;
    }
  }



  numpixelsExpected = 0;



  npixels = (fsize - hsize) / (sizeof(unsigned short));

  /* Now determine if we have to malloc space for the image */
  /* If the data is the wrong size, we will free it and allocate our own */
  if ((*data != NULL) && ((numpixelsExpected) < npixels)) {
    free(*data);
    (*data) = NULL;
    numpixelsExpected = 0;
  }
  if (*data == NULL) {
    (*data) = (short *) malloc(npixels * (sizeof(unsigned short)));
    if ((*data) == NULL) {
      fprintf(stderr, "Out of memory\n");
      assert(0);
    }
    numpixelsExpected = npixels;
  }
  /* Now determine if we have to malloc space for the header */
  /*
   * If the headerBuffer is the wrong size, we will free it and allocate our
   * own
   */
  if (((*headerBuffer) != NULL) && (headersize < hsize)) {
    free(*headerBuffer);
    (*headerBuffer) = NULL;
    headersize = 0;
  }
  if ((*headerBuffer) == NULL) {
    (*headerBuffer) = (unsigned char *) malloc(hsize);
    if ((*headerBuffer) == NULL) {
      fprintf(stderr, "Out of memory\n");
      assert(0);
    }
    headersize = hsize;
  }
  if (readCompressed == 1) {
    for (i = 0; i < hsize; i++) {
      (*headerBuffer)[i] = tmpdata[i];
    }
    for (i = 0; i < npixels; i++) {
      (*data)[i] = (*(unsigned short *) &tmpdata[i * 2 + hsize]);
    }
    free(tmpdata);
  } else {
    /* Read the header */
    if (fread(*headerBuffer, sizeof(unsigned char), hsize, fp) < hsize) {
      fprintf(stderr, "Failed reading the header\n");
      fclose(fp);
      return -1;
    }
    /* Read the data */
    if (fread(*data, sizeof(unsigned short), npixels, fp) < npixels) {
      fprintf(stderr, "Failed reading the data\n");
      fclose(fp);
      return -1;
    }
    fclose(fp);
  }
  for (i = 0; i < npixels; i++) {
    (*data)[i] = convertShortFromGE((*data)[i]);
  }
  if ((iip->swap) == 2) { 
    swab((*data),(*data),npixels*(sizeof(unsigned short)));
  }

  return npixels;  /* Success */
}

unsigned short 
convertShortFromGE(ge)
  unsigned short  ge;
{
  unsigned char  *x = (unsigned char *) &ge;
  return (x[0] * (1 << 8) + x[1]);
  /* MSB             LSB in GE format */
}

unsigned char  *
findUncompressedSizeOfCompressedFile(fname, filesize)
  char           *fname;
  long           *filesize;
/*
 * Read a data file of bytes, determine its size, and optionally return an
 * array of these bytes.
 */
{
  FILE           *fp = (FILE *) NULL;
  int             count = 0;
  unsigned char  *tmp = (unsigned char *) NULL;
  char            command[2048];
  int             chunksize = 150000;
  int             numdatabytes = 0;

  assert(fname != NULL);

  command[0] = '\0';
  strncat(command, "gunzip -c ", sizeof(command));
  strncat(command, fname, sizeof(command) - 11);

  (*filesize) = 0;

  if ((fp = popen(command, "r")) == NULL) {
    fprintf(stderr, "Error: Can't popen %s\n", fname);
    return (unsigned char *) NULL;
  }
  tmp = (unsigned char *) malloc(sizeof(unsigned char) * chunksize);
  if (tmp == (unsigned char *) NULL) {
    fprintf(stderr, "Failed trying to malloc space for reading file\n");
    fflush(stderr);
    return tmp;
  }
  numdatabytes = chunksize;

  while (!feof(fp)) {
    if (count == numdatabytes) {
      numdatabytes += chunksize;
      tmp = (unsigned char *) realloc(tmp, numdatabytes);
      assert(tmp != NULL);
    }
    if (fread(&tmp[count], sizeof(unsigned char), 1, fp) != 1) {
      /*
       * Rather than an error condition, we should regard this as a sign that
       * the process is sending no more data
       */
      break;
      /*
       * fprintf(stderr,"Failed trying to read byte %d\n",count + 1);
       * free(tmp); tmp = (unsigned char *)NULL; return tmp;
       */
    }
    count++;
  }
  pclose(fp);
  (*filesize) = count;

  return tmp;
}

int 
fileIsCompressed(fname, newFileName)
  char           *fname;
  char          **newFileName;
{
  struct stat     statBuf;
  int long        fileSize = 0;

  char           *p = (char *) NULL;
  char           *lastSlash = (char *) NULL;
  int             fileIsCompressed = 0;

  assert(newFileName != NULL);

  if (stat(fname, &statBuf) == -1) {
    /* The given file name is wrong.  Lets look for a compressed version */
    if ((*newFileName) == NULL) {
      (*newFileName) = (unsigned char *) malloc(2048);
      assert((*newFileName) != NULL);
    }
    (*newFileName)[0] = '\0';
    strcat((*newFileName), fname);
    strcat((*newFileName), ".gz");
    if (stat((*newFileName), &statBuf) == -1) {
      (*newFileName)[0] = '\0';
      strcat((*newFileName), fname);
      strcat((*newFileName), ".Z");
      if (stat((*newFileName), &statBuf) == -1) {
          free((*newFileName));
          (*newFileName) = NULL;
          return -1;    /* error - no such file */
      }


    }
    fileIsCompressed = 1;
  } else {
    /* If the file name ends in .gz or .Z it is probably compressed */
    p = strrchr(fname, '.');
    lastSlash = strrchr(fname, '/');
    if ((p != NULL) && ((lastSlash == NULL) || (lastSlash < p)) &&
        ((strcmp(p, ".gz") == 0) || (strcmp(p, ".Z") == 0))) {
        fileIsCompressed = 1;
    }
    (*newFileName) = strdup(fname); /* Use the same name */
    assert((*newFileName) != NULL);
  }
  return fileIsCompressed;
}

