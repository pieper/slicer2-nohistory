/* Copyright (c) Simon Warfield simonw@bwh.harvard.edu */
/* $Id: fileops.h,v 1.1 2005/11/09 20:39:17 nicole Exp $ */

#ifndef _FILEOPS_H_INCLUDED
#define _FILEOPS_H_INCLUDED 1

#ifdef __cplusplus
extern "C" {
#endif

long fileSize(char *fname);
long headerSize(int fileSize);

int readMRIfile(char *fname,
        unsigned char **headerBuffer, int *headersize,
        unsigned short **data, int *numpixelsExpected);

int writeMRIfile(char *fname,
        unsigned char *header, int headersize,
        unsigned short *data, int npixels);

int numSlices(int startsuffix, int endsuffix, int inc);
int fileSuffix(int currentslice, int startsuffix, int endsuffix, int inc);
int makeFileName(char *prefix,int slicenum,int startsuffix,
        int endsuffix, int inc, char name[]);
unsigned short convertShortFromGE(unsigned short ge);
int saveFloatAsMRI(char *fname, float *data, int np);
int readMRIIntoFloat(char *fname, float *data, int np);
int readFloatIntoFloat(char *fname, float **data, int *np);
int saveFloatAsFloat(char *fname, float *data, int np);

unsigned char *findUncompressedSizeOfCompressedFile(char *fname,
                  long int *filesize);

int fileIsCompressed(char *fname, char **newFileName);

char *allocFileName(char *prefix,int slicenum,int startsuffix,
    int endsuffix, int inc);

#ifdef __cplusplus
}
#endif

#endif
