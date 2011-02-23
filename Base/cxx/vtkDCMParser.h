/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDCMParser.h,v $
  Date:      $Date: 2006/02/14 20:40:10 $
  Version:   $Revision: 1.17 $

=========================================================================auto=*/

/* 
   dcmparse.h
*/
//
// DICOM header parser
// Attila Tanacs
// ERC for CISST, Johns Hopkins University, USA
// Dept. of Applied Informatics, University of Szeged, Hungary
// tanacs@cs.jhu.edu tanacs@inf.u-szeged.hu
//

#ifndef DCMPARSE_H
#define DCMPARSE_H

//#include <iostream.h>
//#include <fstream.h>
#include <stdio.h>
#include "vtkObject.h"
//#include "vtkDCMDataElement.h"

#include "vtkSlicer.h"

#define TFS_IVRLE 1
#define TFS_EVRLE 2
#define TFS_EVRBE 3
#define TFS_IVRBE 4 // GE private syntax, but it does show up 

/*typedef short INT16;
typedef unsigned short UINT16;
typedef int INT32;
typedef unsigned int UINT32;
typedef long LONG;
typedef unsigned long ULONG;*/

#define INT16 short
#define UINT16 unsigned short
#define INT32 int
#define UINT32 unsigned int
#define LONG long
#define ULONG unsigned long

//typedef void (*dcm_callback)(FILE *file_in, unsigned short group_code,
//                 unsigned short element_code, unsigned int length,
//                 char *vr, int *stop);

struct DCMDataElementStruct
{
  char VR[4];
  unsigned short GroupCode;
  unsigned short ElementCode;
  unsigned int Length;
  unsigned int NextBlock;
};

static const char * const TFS_String[] = 
{
  "Implicit VR Little Endian",
  "Explicit VR Little Endian",
  "Explicit VR Big Endian",
  "Implicit VR Big Endian",
  "Unknown"
};

class vtkDCMParser;

typedef void (*dcm_callback)(DCMDataElementStruct des, int *stop, vtkDCMParser *parser);

class VTK_SLICER_BASE_EXPORT vtkDCMParser : public vtkObject
{
 public:
  static vtkDCMParser *New();
  vtkTypeMacro(vtkDCMParser,vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  vtkDCMParser();
  vtkDCMParser(const char *filename);

  ~vtkDCMParser();

  void Skip(unsigned int length);
  unsigned short ReadUINT16();
  short ReadINT16();
  unsigned int ReadUINT32();
  int ReadINT32();
  float ReadFL();
  double ReadFD();
  float ReadFloatAsciiNumeric(unsigned int next_block);
  int ReadIntAsciiNumeric(unsigned int next_block);
  void ReadText(char *str, unsigned int length);
  char *ReadText(unsigned int length);
  char *ReadElement();
  unsigned long ReadElementLength();
  //void ReadElement(char *vr, char *group_code,
  //           char *element_code, char *length);
  void ReadElement(DCMDataElementStruct *des);
  void UnreadLastElement();
  void ReadDICOMMetaHeaderInfo();
  void ReadDICOMHeaderInfo(dcm_callback dcm_funct);
  int FindElement(unsigned short group, unsigned short element);
  int FindNextElement(unsigned short group, unsigned short element);
  void SeekFirstElement();

  const char *GetMediaStorageSOPClassUID();
  const char *GetMediaStorageSOPInstanceUID();
  const char *GetTransferSyntaxUID();
  const char *GetImplementationClassUID();

  int IsMachineLittleEndian();
  int GetMustSwap();
  void SetMustSwap(int i);
  int GetTransferSyntax();
  const char *GetTransferSyntaxAsString();

  int OpenFile(const char *filename);
  void CloseFile();
  FILE *GetFileID();
  long GetFilePosition();
  int SetFilePosition(long position);
  int IsStatusOK();

  //char * GetTCLPreviewRow(int width, int SkipColumn, int max);

 protected:
  void Init();
  char *stringncopy(char *dest, const char *src, long max);

  //  char *aux_ret;

  FILE *file_in;

  char MediaStorageSOPClassUID[65];
  char MediaStorageSOPInstanceUID[65];
  char TransferSyntaxUID[65];
  char ImplementationClassUID[65];

  int MachineLittleEndian;
  int MustSwap;
  int TransferSyntax;
  
  int FileIOMessage;
  int PrevFileIOMessage;
  char buff[255];
  
  long PrevFilePos;
  long HeaderStartPos;
 private:
};

#endif
