/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDCMLister.cxx,v $
  Date:      $Date: 2006/02/14 20:40:10 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/

// dcmlister.cxx
//
// DICOM header lister
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
#include "vtkDCMLister.h"


//**************************************************************************
//**************************************************************************
// DICOM
//**************************************************************************
//**************************************************************************

vtkDCMLister* vtkDCMLister::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkDCMLister");
  if(ret)
  {
    return (vtkDCMLister*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkDCMLister;
}

void vtkDCMLister::PrintSelf(ostream& os, vtkIndent indent)
{
  struct DataElement *dummy;

  vtkDCMParser::PrintSelf(os,indent);

  os << indent << "vtkDCMLister::PrintSelf()" << "\n";
  //os << indent << "DICOM element list:\n" << PrintList();
  os << indent << "DICOM element list:\n";
  dummy = FirstElement;
  while(dummy != NULL)
    {
      os << indent << indent << dummy->Name << "\n";
      dummy = dummy->Next;
    }
  //if(file_in) os << indent << "File is open.\n";
  //else os << indent << "No open file.\n";
}

vtkDCMLister::vtkDCMLister()
{
  Init();
}

vtkDCMLister::vtkDCMLister(const char *filename)
{
  Init();
  OpenFile(filename);
}

vtkDCMLister::~vtkDCMLister()
{
  this->ClearList();

  delete [] this->aux_ret;
  delete [] this->aux_str;
  delete [] this->line;
  delete [] this->element;
  delete [] this->buff;
}

void vtkDCMLister::Init()
{
  this->aux_ret = NULL;
  this->ListAll = 0;
  this->FirstElement = NULL;
  this->line = new char [1000];
  this->element = new char [1000];
  this->aux_str = new char [AUX_STR_MAX];
  this->buff_maxlen = 0;
  this->buff = NULL;
}

char * vtkDCMLister::GetTCLPreviewRow(int width, int SkipColumn, int max)
{
  int i, idx;
  int pix, grey;
  double sc;

  if(this->aux_ret == NULL)
    this->aux_ret = new char [65535];

  this->aux_ret[0] = '\0';

  sc = 255.0 / double(max);
  for(i=0, idx = 0; i < width; i++, idx += 8)
    {
      pix = this->ReadUINT16();
      grey = int(pix * sc);
      if(grey < 0)
    grey = 0;
      if(grey > 255)
    grey = 255;
      sprintf(this->aux_ret + idx, "#%02x%02x%02x ", grey, grey, grey);
      //this->Skip(6);
      this->Skip(SkipColumn);
    }
  
  return this->aux_ret;
}

int vtkDCMLister::ReadList(const char *filename)
{
  int i;
  FILE *fin;
  unsigned int ui;
  UINT16 gn, en;
  char vr[4];

  struct DataElement *last, *dummy;

  if(FirstElement != NULL)
    ClearList();

  last = FirstElement;
  
  if((fin = fopen(filename, "rt")) == NULL)
  {
    return -1;
  }

  while(1)
  {
    line[0] = '\0';
    if(feof(fin))
      break;
    fgets(line, 999, fin);
    //if(feof(fin) && (line[0] == '\0')) break;
    
    i=0;
    getelement(&i);
    if((element[0] == '#') || (element[0] == '\0'))
      continue; // comment or empty line
    sscanf(element, "%x", &ui);
    gn = (UINT16)ui;
    
    getelement(&i);
    if(element[0] == '\0')
      continue;
    sscanf(element, "%x", &ui);
    en = (UINT16)ui;
    
    getelement(&i);
    if(element[0] == '\0')
      continue;
    stringncopy(vr, element, 2);
    
    getquotedtext(&i);
    if(element[0] == '\0')
      continue;
    
    dummy = new DataElement;
    if(FirstElement == NULL)
      {
    FirstElement = dummy;
      }
    else
      {
    last->Next = dummy;
      }
    
    dummy->Group = gn;
    dummy->Element = en;
    stringncopy(dummy->VR, vr, 2);
    dummy->Name = new char [strlen(element) + 1];
    stringncopy(dummy->Name, element, strlen(element));
    dummy->Next = NULL;
    last = dummy;
    
    //printf("%04x %04x %s %s\n", dummy->Group, dummy->Element, dummy->VR, dummy->Name);
  }
  
  fclose(fin);
  
  return 1;
}

void vtkDCMLister::ClearList()
{
  struct DataElement *dummy;
  
  dummy = FirstElement;
  while(dummy != NULL)
    {
      dummy = dummy->Next;
      delete [] FirstElement->Name;
      delete FirstElement;
      FirstElement = dummy;
    }
  FirstElement = NULL;
}

char * vtkDCMLister::PrintList()
{
  struct DataElement *dummy;
  int i = 0;
  char temp[512];

  sprintf(this->aux_str, "Empty list.");
  dummy = FirstElement;
  while((dummy != NULL) && (i < AUX_STR_MAX))
    {
      stringncopy(temp, dummy->Name, 510);
      sprintf(temp + strlen(temp), "\n");
      stringncopy(aux_str + i, temp, AUX_STR_MAX - i);
      i += strlen(temp) - 1;
      //sprintf(aux_str + i, "\n");
      //i++;
      dummy = dummy->Next;
    }

  return this->aux_str;
}

void vtkDCMLister::ListElement(unsigned short Group,
          unsigned short Element, unsigned long length,
          const char *VR, const char *Name)
{
  if((strcmp(VR, "OB") != 0) &&
     (strcmp(VR, "OW") != 0) &&
     (strcmp(VR, "OX") != 0))
    if(((length + 1) > (unsigned long)buff_maxlen) && (length != 0xffffffff))
    {
        delete [] buff;
        buff_maxlen = length + 1;
        buff = new char [buff_maxlen];
    }
            
  if((strcmp(VR, "PN") == 0) 
     || (strcmp(VR, "LO") == 0)
     || (strcmp(VR, "AE") == 0)
     || (strcmp(VR, "LT") == 0)
     || (strcmp(VR, "SH") == 0)
     || (strcmp(VR, "ST") == 0)
     || (strcmp(VR, "UT") == 0)
     || (strcmp(VR, "DA") == 0)
     || (strcmp(VR, "DS") == 0)
     || (strcmp(VR, "DT") == 0)
     || (strcmp(VR, "IS") == 0)
     || (strcmp(VR, "TM") == 0)
     || (strcmp(VR, "AS") == 0)
     || (strcmp(VR, "UI") == 0)
     || (strcmp(VR, "CS") == 0)
     )
    {
      ReadText(buff, length);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): %s\n", Group, Element,
         VR, Name, length, buff);
    }
  else if(strcmp(VR, "FL") == 0)
    {
      int i;
      float fl;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(float);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
         VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      fl = ReadFL();
      sprintf(aux_str + j, "%f ", fl);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "FD") == 0)
    {
      int i;
      double fl;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(double);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      fl = ReadFD();
      sprintf(aux_str + j, "%f ", fl);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "UL") == 0)
    {
      int i;
      UINT32 ui;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(UINT32);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      ui = ReadUINT32();
      sprintf(aux_str + j, "%u ", ui);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "SL") == 0)
    {
      int i;
      INT32 ui;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(INT32);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      ui = ReadINT32();
      sprintf(aux_str + j, "%d ", ui);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "US") == 0)
    {
      int i;
      UINT16 ui;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(UINT16);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      ui = ReadUINT16();
      sprintf(aux_str + j, "%u ", ui);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "SS") == 0)
    {
      int i;
      INT16 ui;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(INT16);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      ui = ReadINT16();
      sprintf(aux_str + j, "%d ", ui);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if(strcmp(VR, "AT") == 0)
    {
      int i;
      UINT16 ui;
      long next_block = ftell(file_in) + length;
      int num = length / sizeof(UINT16);
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): ", Group, Element,
          VR, Name, length);
      int j = strlen(aux_str);
      for(i = 0; i < num; i++)
    {
      ui = ReadUINT16();
      sprintf(aux_str + j, "%04x ", ui);
      j = strlen(aux_str);
    }
      sprintf(aux_str + j, "\n");
      fseek(file_in, next_block, SEEK_SET);
    }
  else if((strcmp(VR, "OB") == 0) ||
      (strcmp(VR, "OW") == 0) ||
      (strcmp(VR, "OX") == 0)
      )
    {
      sprintf(aux_str, "(%04x,%04x) %s %s (%lu): Data starts at position %ld\n", Group, Element,
          VR, Name, length, ftell(file_in));
    }
  else if(strcmp(VR, "SQ") == 0)
    {
      sprintf(aux_str, "(%04x,%04x) %s %s (%ld)\n", Group, Element, VR, Name, length);
    }
  else
    {
      Skip(length);
      sprintf(aux_str, "\t(%04x,%04x) %s of VR %s not interpreted.\n",
          Group, Element, Name, VR);
    }
}

char * vtkDCMLister::callback(unsigned short group_code,
                unsigned short element_code,
                unsigned long length,
                char *vr)
{
  struct DataElement *dummy;
  int found;
  long next_element;
  //printf("(%04x,%04x) %s (%lu bytes)",
  //     group_code, element_code, vr, length);
  
  if(length != 0xffffffff)
    next_element = GetFilePosition() + length;
  sprintf(aux_str, "Empty.");

  dummy = FirstElement;
  found = 0;
  while((dummy != NULL) && (!found))
    {
      if((dummy->Group == group_code) && (dummy->Element == element_code))
    {
      if(strcmp(vr, "??") == 0)
        ListElement(group_code, element_code, length, dummy->VR, dummy->Name);
      else
        ListElement(group_code, element_code, length, vr, dummy->Name);
      
      found = 1;
      break;
    }
      
      dummy = dummy->Next;
    }
  
  if(!found && ListAll)
    { // element not found in list
      if(strcmp(vr, "??") == 0)
    {
      sprintf(aux_str, "(%04x,%04x) %s (%lu bytes)\n",
       group_code, element_code, vr, length);
    }
      else
    {
      ListElement(group_code, element_code, length, vr, "Unknown");
    }
    }

  if(length != 0xffffffff)
    SetFilePosition(next_element);

  return aux_str;
}
 
//
// Protected aux. functions.
//

int vtkDCMLister::isname(char ch)
{
  return (isalnum(ch) || (ch=='_'));
}

void vtkDCMLister::getelement(int *i)
{
  int j;
  
  j=0;
  while((line[*i]!='\0') && isspace(line[*i])) (*i)++;
  
  if(line[*i]!='\0')
    {
    if(isname(line[*i]))
    {
      do
      {
    element[j]=line[*i];
    j++;
    (*i)++;
      }
      while((isname(line[*i])) && (j<999));
    }
    else
    {
      do
      {
    element[j]=line[*i];
    j++;
    (*i)++;
      }
      while((!isalnum(line[*i])) && (!isspace(line[*i])) && (j<999));
    }
  }

  element[j]='\0';
}

void vtkDCMLister::getquotedtext(int *i)
{
  int j;
  
  getelement(i);
  if(strcmp(element, "\"") != 0)
    {
      return;
    }
  
  j = 0;
  while((line[*i] != '\0') && (line[*i] != '\"'))
    {
      element[j]=line[*i];
      j++;
      (*i)++;
    }
  element[j]='\0';
}
