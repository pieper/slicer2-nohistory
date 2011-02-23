/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDCMParser.cxx,v $
  Date:      $Date: 2006/01/13 15:39:24 $
  Version:   $Revision: 1.19 $

=========================================================================auto=*/

// dcmprs.cxx
//
// DICOM header parser
// Attila Tanacs
// ERC for CISST, Johns Hopkins University, USA
// Dept. of Applied Informatics, University of Szeged, Hungary
// tanacs@cs.jhu.edu tanacs@inf.u-szeged.hu
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>

#include "vtkObjectFactory.h"
#include "vtkDCMParser.h"


//**************************************************************************
//**************************************************************************
// DICOM
//**************************************************************************
//**************************************************************************

vtkDCMParser* vtkDCMParser::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDCMParser");
  if(ret)
  {
    return (vtkDCMParser*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkDCMParser;
}

void vtkDCMParser::PrintSelf(ostream& os, vtkIndent indent)
{
  this->vtkObject::PrintSelf(os,indent);

  os << indent << "vtkDCMParser::PrintSelf()" << "\n";
  if(file_in) os << indent << "File is open.\n";
  else os << indent << "No open file.\n";
}

vtkDCMParser::vtkDCMParser()
{
  Init();
}

vtkDCMParser::vtkDCMParser(const char *filename)
{
  Init();
  OpenFile(filename);
}

vtkDCMParser::~vtkDCMParser()
{
  CloseFile();
  //delete [] aux_ret;
}

void vtkDCMParser::Init()
{
  file_in = NULL;

  memset(MediaStorageSOPClassUID, 0, 65);
  memset(MediaStorageSOPInstanceUID, 0, 65);
  memset(TransferSyntaxUID, 0, 65);
  memset(ImplementationClassUID, 0, 65);

  short check = 1;
  unsigned char *ptr = (unsigned char *)&check;
  MachineLittleEndian = (ptr[0] == 0x01);

  TransferSyntax = TFS_IVRLE;
  if(MachineLittleEndian)
    MustSwap = 0;
  else
    MustSwap = 1;
  
  PrevFileIOMessage = FileIOMessage = 0;
  
  PrevFilePos = HeaderStartPos = 0;

  //aux_ret = NULL;
}

void vtkDCMParser::Skip(unsigned int Length)
{

  if(this->file_in)
    if(fseek(this->file_in, Length, SEEK_CUR)!=0)
      {
    FileIOMessage=1;
      }
}

unsigned short vtkDCMParser::ReadUINT16()
{
  unsigned char *ptr;
  unsigned char ch;
  unsigned short id = 0;
  
  if(this->file_in)
    {
      if(fread(&id, 2, 1, this->file_in)!=1)
    {
      FileIOMessage=2;
    }
      
      if(MustSwap)
    {
      ptr = (unsigned char *)&id;
      ch = ptr[0];
      ptr[0] = ptr[1];
      ptr[1] = ch;
    }
    }

  return id;
}

short vtkDCMParser::ReadINT16()
{
  unsigned char *ptr;
  unsigned char ch;
  short id;

  if(this->file_in)
    {
      if(fread(&id, 2, 1, file_in)!=1)
    {
      FileIOMessage=3;
    }
      
      if(MustSwap)
    {
      ptr = (unsigned char *)&id;
      ch = ptr[0];
      ptr[0] = ptr[1];
      ptr[1] = ch;
    }
    }
  
  return id;
}

unsigned int vtkDCMParser::ReadUINT32()
{
  unsigned char *ptr;
  unsigned char ch;
  unsigned int id = 0;

  if(this->file_in)
    {
      if(fread(&id, 4, 1, this->file_in)!=1)
    {
      FileIOMessage=3;
    }
      
      if(MustSwap)
    {
      ptr=(unsigned char *)&id;
      ch=ptr[0]; ptr[0]=ptr[3]; ptr[3]=ch;
      ch=ptr[1]; ptr[1]=ptr[2]; ptr[2]=ch;
    }
    }

  return id;
}

int vtkDCMParser::ReadINT32()
{
  unsigned char *ptr;
  unsigned char ch;
  int id;

  if(this->file_in)
    {
      if(fread(&id, 4, 1, file_in)!=1)
    {
      FileIOMessage=3;
    }
      
      if(MustSwap)
    {
      ptr=(unsigned char *)&id;
      ch=ptr[0]; ptr[0]=ptr[3]; ptr[3]=ch;
      ch=ptr[1]; ptr[1]=ptr[2]; ptr[2]=ch;
    }
    }
  
  return id;
}

float vtkDCMParser::ReadFL()
{
  unsigned char *ptr;
  unsigned char ch;
  float id = 0.0;

  if(this->file_in)
    {
      if(fread(&id, 4, 1, this->file_in)!=1)
    {
      FileIOMessage=3;
    }
      
      if(MustSwap)
    {
      ptr=(unsigned char *)&id;
      ch=ptr[0]; ptr[0]=ptr[3]; ptr[3]=ch;
      ch=ptr[1]; ptr[1]=ptr[2]; ptr[2]=ch;
    }
    }

  return id;
}

double vtkDCMParser::ReadFD()
{
  unsigned char *ptr;
  unsigned char ch;
  double id = 0.0;

  if(this->file_in)
    {
      if(fread(&id, 8, 1, this->file_in)!=1)
    {
      FileIOMessage=3;
    }
      
      if(MustSwap)
    {
      ptr=(unsigned char *)&id;
      ch=ptr[0]; ptr[0]=ptr[7]; ptr[7]=ch;
      ch=ptr[1]; ptr[1]=ptr[6]; ptr[6]=ch;
      ch=ptr[2]; ptr[2]=ptr[5]; ptr[5]=ch;
      ch=ptr[3]; ptr[3]=ptr[4]; ptr[4]=ch;
    }
    }

  return id;
}

void vtkDCMParser::ReadText(char *str, unsigned int Length)
{
  
  if(this->file_in)
    {
      if(fread(str, 1, Length, file_in)!=Length)
    {
      str[0] = '\0';
      FileIOMessage=4;
    }
      else str[Length]='\0';
    }
}

char *vtkDCMParser::ReadText(unsigned int Length)
{
  //char str[Length + 1];
  static char str[1024];
  unsigned int length = (Length >= 1024) ? 1024 : Length;
  
  if(this->file_in)
    {
      if(fread(str, 1, length, file_in)!=length)
    {
      str[0] = '\0';
      FileIOMessage=4;
    }
      else str[length]='\0';
    }

  return str;
}

float vtkDCMParser::ReadFloatAsciiNumeric(unsigned int NextBlock)
{
  char buff[20];
  char ch;
  int i, flag;

  sprintf(buff, "0.0");
  if(this->file_in)
    {
      i=0;
      flag=1;
      while(flag && i<19 && (unsigned int)ftell(file_in)<NextBlock)
      {
        ch=getc(file_in);
        if(ch=='\\') flag=0;
        else buff[i++]=ch;
      }
      
      buff[i]='\0';

    }

  return atof(buff);
}

int vtkDCMParser::ReadIntAsciiNumeric(unsigned int NextBlock)
{
  char buff[20];
  char ch;
  int i, flag;

  sprintf(buff, "0.0");
  if(this->file_in)
    {
      i=0;
      flag=1;
      while(flag && i<19 && (unsigned int)ftell(file_in)<NextBlock)
    {
      ch=getc(file_in);
      if(ch=='\\') flag=0;
      else buff[i++]=ch;
    }
      
      buff[i]='\0';

    }

  return atoi(buff);
}

char *vtkDCMParser::ReadElement()
{
  //char buff[128];
  DCMDataElementStruct des;

  if(file_in == NULL)
    {
      sprintf(buff, "Open a file first.");
    }
  else
    {
      ReadElement(&des);
      sprintf(buff, "%s 0x%04x 0x%04x %d %u", des.VR, des.GroupCode,
          des.ElementCode, des.Length, des.NextBlock);
    }

  return buff;

  //sprintf(vr, des.VR);
  ////*group_code = des.GroupCode;
  ////*element_code = des.ElementCode;
  ////*length = des.Length;
  //////*next_block = des.NextBlock;

  //sprintf(group_code, "%04x", des.GroupCode);
  //sprintf(element_code, "%04x", des.ElementCode);
  //sprintf(length, "%04x", des.Length);
}

unsigned long vtkDCMParser::ReadElementLength()
{
  DCMDataElementStruct des;

  if(file_in == NULL)
    return 0l;

  ReadElement(&des);

  return des.Length;
}

void vtkDCMParser::ReadElement(DCMDataElementStruct *des)
{
  if(this->file_in)
    {
      PrevFilePos = ftell(file_in);
      PrevFileIOMessage = FileIOMessage;

      switch(TransferSyntax)
      {
      case TFS_IVRLE:
      case TFS_IVRBE:
        
        des->GroupCode = ReadUINT16();
        des->ElementCode = ReadUINT16();
        des->Length = ReadUINT32();

        des->NextBlock = ftell(file_in);
        if(des->Length != 0xffffffff)
          des->NextBlock += des->Length;

        sprintf(des->VR, "??");
        
        break;
        
      case TFS_EVRLE:
      case TFS_EVRBE:
        
        des->GroupCode = ReadUINT16();
        des->ElementCode = ReadUINT16();
        
        if((des->GroupCode) == 0xfffe)
          {
            if((des->ElementCode == 0xe000) ||
             (des->ElementCode == 0xe00d) ||
             (des->ElementCode == 0xe0dd))
            { // must be implicit VR always
              des->Length = ReadUINT32();

              des->NextBlock = ftell(file_in);
              if(des->Length != 0xffffffff)
                des->NextBlock += des->Length;

              sprintf(des->VR, "??");

              return;
            }
          }
        
        ReadText(des->VR, 2); // getting VR
        
        if((strcmp(des->VR, "OB") == 0) ||
           (strcmp(des->VR, "OW") == 0) ||
           (strcmp(des->VR, "SQ") == 0) ||
           (strcmp(des->VR, "UN") == 0) ||
           (strcmp(des->VR, "UT") == 0)
           )
          {
            des->Length = ReadUINT16(); // reserved field
            des->Length = ReadUINT32();
            des->NextBlock = ftell(file_in);
            if(des->Length != 0xffffffff)
              des->NextBlock += des->Length;
          } else
          {
            des->Length = ReadUINT16();
            des->NextBlock = ftell(file_in);
            if(des->Length != 0xffffffff)
              des->NextBlock += des->Length;
          }
        
        break;
      }
    }
}

void vtkDCMParser::UnreadLastElement()
{
  if(this->file_in)
    {
      fseek(this->file_in, PrevFilePos, SEEK_SET);
      FileIOMessage = PrevFileIOMessage;
    }
}

void vtkDCMParser::ReadDICOMMetaHeaderInfo()
{
  long file_pos;
  //UINT16 GroupCode;
  //UINT16 ElementCode;
  //UINT32 Length;
  //char vr[4];
  int tfs;

  short check;
  unsigned char *ptr;

  int implicit = -1; // sp 2002-08-08 
                     // implicit headers are rare, but occur
                     // -1 means don't know yet
                     // 0 means 2 char VR (value rep) code exists
                     // 1 means gotta guess the VR from context (dictionary)

  DCMDataElementStruct des;

  if(this->file_in == NULL)
    return;

  check = 1;
  ptr = (unsigned char *)&check;
  MachineLittleEndian = (ptr[0] == 0x01);
  tfs = TFS_IVRLE;
  TransferSyntax = TFS_EVRLE;  // explicit to start with

  PrevFileIOMessage = FileIOMessage = 0;

  PrevFilePos = file_pos = ftell(file_in);

  fread(buff, 132, 1, file_in);
  if((buff[128] == 'D') && (buff[129] == 'I')
     && (buff[130] == 'C') && (buff[131] == 'M'))
  {  
    do
    {
      //file_pos = ftell(file_in);
      ReadElement(&des);

      // check to see if this is implicit header - done first time through
      if (implicit == -1)
        { 
        if ( (des.GroupCode != 0x0002) || (des.ElementCode != 0x0) )
          {
          // bad case - metaheader should start with length
          // guess that it's implicit
          implicit = 0;
          TransferSyntax = TFS_EVRLE; // class flag used in reading
          }
        else
          {
          if (strcmp(des.VR, "UL") == 0) // it has a VR field
            {
            implicit = 0;
            TransferSyntax = TFS_EVRLE; // class flag used in reading
            }
          else
            {
            implicit = 1;
            UnreadLastElement();
            TransferSyntax = TFS_IVRLE; // class flag used in reading
            ReadElement(&des); // re-read without the 2 VR bytes
            }
          }
        }


      if(des.GroupCode != 0x0002)
        {
          UnreadLastElement();
          HeaderStartPos = ftell(file_in);
          break;
        }

      switch(des.ElementCode)
        {
        case 0x0002:
          ReadText(buff, des.Length);
          //printf("Media Storage SOP Class UID (%04x,%04x):\n\t%s\n",
          //     GroupCode, ElementCode, buff);
          stringncopy(MediaStorageSOPClassUID, buff, 64);

          break;

        case 0x0003:
          ReadText(buff, des.Length);
          //printf("Media Storage SOP Instance UID (%04x,%04x):\n\t%s\n",
          //     GroupCode, ElementCode, buff);          
          stringncopy(MediaStorageSOPInstanceUID, buff, 64);

          break;

        case 0x0010:
          ReadText(buff, des.Length);
          //printf("Transfer Syntax UID (%04x,%04x):\n\t%s\n",
          //     GroupCode, ElementCode, buff);
          stringncopy(TransferSyntaxUID, buff, 64);

          if(strcmp(buff, "1.2.840.10008.1.2") == 0)
          {
            //printf("\tImplicit VR Little Endian\n");
            tfs = TFS_IVRLE; 
          }
          else
          if(strcmp(buff, "1.2.840.10008.1.2.1") == 0)
          {
            //printf("\tExplicit VR Little Endian\n");
            tfs = TFS_EVRLE;
          }
          else
          if(strcmp(buff, "1.2.840.10008.1.2.2") == 0)
          {
            //printf("\tExplicit VR Big Endian\n");
            tfs = TFS_EVRBE;
          }
          else
          if(strcmp(buff, "1.2.840.113619.5.2") == 0)
          {
            //printf("\tImplicit VR Big Endian\n");
            
            //
            // claims to be BE but header info is LE
            // and data is BE
            //
            tfs = TFS_IVRBE;  
          }
          else
          {
            //printf("\tNot found: assuming explicit VR Little Endian\n");
            tfs = TFS_EVRLE;
          }

          break;

        case 0x0012:
          ReadText(buff, des.Length);
          //printf("Implementation Class UID (%04x,%04x):\n\t%s\n",
          //     GroupCode, ElementCode, buff);
          stringncopy(ImplementationClassUID, buff, 64);
          
          break;
          
        default:
          //printf("skipping (%04x,%04x) %s (%lu bytes)\n",
          //     GroupCode, ElementCode, vr, Length);
          Skip(des.Length);
        }
    }
    while(1);
  } else
  {
    tfs = TFS_IVRLE; // not necessary to set here
    //printf("No MetaHeader Info!\n");
    //printf("Assuming Implicit VR Little Endian Transfer Syntax.\n");
    HeaderStartPos = file_pos;
    fseek(file_in, file_pos, SEEK_SET);
  }

  TransferSyntax = tfs;

  // note special handling of GE broken Implicit BE
  if( (MachineLittleEndian && ((tfs == TFS_EVRBE))) ||
     ( !MachineLittleEndian && 
        ((tfs == TFS_EVRLE) || (tfs == TFS_IVRLE) || (tfs == TFS_IVRBE)) ))
    MustSwap = 1;
  else
    MustSwap = 0;
}

void vtkDCMParser::ReadDICOMHeaderInfo(dcm_callback dcm_funct)
{
  //UINT16 GroupCode;
  //UINT16 ElementCode;
  //UINT32 Length;
  //char vr[4];
  int stop;
  //UINT32 NextBlock;
  DCMDataElementStruct des;

  if(this->file_in == NULL)
    return;

  stop = 0;
  while(!stop)
    {
      ReadElement(&des);
      
      if(feof(file_in) || (FileIOMessage != 0))
    {
      stop = 1;
      break;
    }
    
      if(des.Length != 0xffffffff)
    des.NextBlock = ftell(file_in) + des.Length;
      else
    des.NextBlock = ftell(file_in);

      (*dcm_funct)(des, &stop, this);

      fseek(file_in, des.NextBlock, SEEK_SET);
      if(feof(file_in) || (FileIOMessage != 0))
    {
      stop = 1;
      break;
    }
    }
}

int vtkDCMParser::FindElement(unsigned short group, unsigned short element)
{
  if(file_in == NULL)
    return 0;

  SeekFirstElement();
  return FindNextElement(group, element);
}

int vtkDCMParser::FindNextElement(unsigned short group, unsigned short element)
{
  int stop;
  int found;
  DCMDataElementStruct des;
  long fpos;
  int FileIOState;

  if(file_in == NULL)
    return 0;

  // store current file position information before search
  fpos = ftell(this->file_in);
  FileIOState = FileIOMessage;

  found = 0;
  stop = 0;
  while(!stop)
    {
      ReadElement(&des);
      
      if(feof(file_in) || (FileIOMessage != 0))
    {
      stop = 1;
      break;
    }
    
      if(des.Length != 0xffffffff)
    des.NextBlock = ftell(file_in) + des.Length;
      else
    des.NextBlock = ftell(file_in);

      if((des.GroupCode == group) && (des.ElementCode == element))
    {
      found = stop = 1;
      break;
    }

      fseek(file_in, des.NextBlock, SEEK_SET);
      if(feof(file_in) || (FileIOMessage != 0))
    {
      break;
      stop = 1;
    }
    }

  if(found)
    {
      UnreadLastElement();
      FileIOMessage = 0;
    }
  else
    {
      // set values as they were before calling
      fseek(file_in, fpos, SEEK_SET);
      FileIOMessage = FileIOState;
    }

  return found;
}

void vtkDCMParser::SeekFirstElement()
{
  if(this->file_in)
    {
      fseek(this->file_in, HeaderStartPos, SEEK_SET);
      FileIOMessage = 0;
    }
}

const char *vtkDCMParser::GetMediaStorageSOPClassUID()
{
  return MediaStorageSOPClassUID;
}

const char *vtkDCMParser::GetMediaStorageSOPInstanceUID()
{
  return MediaStorageSOPInstanceUID;
}

const char *vtkDCMParser::GetTransferSyntaxUID()
{
  return TransferSyntaxUID;
}

const char *vtkDCMParser::GetImplementationClassUID()
{
  return ImplementationClassUID;
}

int vtkDCMParser::IsMachineLittleEndian()
{
  return MachineLittleEndian;
}

int vtkDCMParser::GetMustSwap()
{
  return MustSwap;
}

void vtkDCMParser::SetMustSwap(int i)
{
  MustSwap = i;
}

int vtkDCMParser::GetTransferSyntax()
{
  return TransferSyntax;
}

const char *vtkDCMParser::GetTransferSyntaxAsString()
{
  if((TransferSyntax >= 1) && (TransferSyntax <=4))
    return TFS_String[TransferSyntax - 1];
  else
    return TFS_String[4];
}

char *vtkDCMParser::stringncopy(char *dest, const char *src, long max)
{
  const char *p;
  long i, j, n;
  long length;

  if(dest != NULL)
    {
      if(src == NULL) memset(dest, 0, max + 1);
      else
    {
      length = strlen(src);
      n = (length < max) ? length : max;
      for(j=n-1; (j>=0) && (isspace(src[j])); j--);
      for(i=0; (i<n) && (isspace(src[i])); i++);
      for(p=src+i; (i<=j) && ((*p)!='\0'); i++, p++)
        dest[i] = *p;
      for(; i<=max; i++)
        dest[i]='\0';
    }
    }

  return dest;
}

int vtkDCMParser::OpenFile(const char *filename)
{
  if(this->file_in)
    {
      CloseFile();
      Init();
    }

  if((filename == NULL) || (strcmp(filename, "") == 0))
    {
      file_in = NULL;
    }
  else if((file_in = fopen(filename, "rb")) != NULL)
    ReadDICOMMetaHeaderInfo();

  return (file_in != NULL);
}

void vtkDCMParser::CloseFile()
{
  if(this->file_in)
    fclose(this->file_in);

  this->file_in = NULL;
}

FILE *vtkDCMParser::GetFileID()
{
  return this->file_in;
}

long vtkDCMParser::GetFilePosition()
{
  if(this->file_in)
    return ftell(this->file_in);
  else
    return 0l;
}

int vtkDCMParser::SetFilePosition(long position)
{
  if(this->file_in)
    return fseek(this->file_in, position, SEEK_SET);
  else
    return -1;
}

int vtkDCMParser::IsStatusOK()
{
  int ret = 0;
  if(this->file_in)
    if(!feof(file_in) && (FileIOMessage == 0))
      {
    ret = 1;
      }
  
  return ret;
}
