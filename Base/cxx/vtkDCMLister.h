/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDCMLister.h,v $
  Date:      $Date: 2006/02/14 20:40:10 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/

/* 
   dcmlister.h
*/
//
// DICOM header lister
// Attila Tanacs
// ERC for CISST, Johns Hopkins University, USA
// Dept. of Applied Informatics, University of Szeged, Hungary
// tanacs@cs.jhu.edu tanacs@inf.u-szeged.hu
//

#ifndef DCMLISTER_H
#define DCMLISTER_H

//#include <iostream.h>
//#include <fstream.h>
#include <stdio.h>
#include "vtkObject.h"
#include "vtkDCMParser.h"

#include "vtkSlicer.h"

#define AUX_STR_MAX 4096

struct DataElement {
  UINT16 Group;
  UINT16 Element;
  char VR[4];
  char *Name;
  struct DataElement *Next;
};

class VTK_SLICER_BASE_EXPORT vtkDCMLister : public vtkDCMParser
{
 public:
  static vtkDCMLister *New();
  vtkTypeMacro(vtkDCMLister,vtkDCMParser);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  vtkDCMLister();
  vtkDCMLister(const char *filename);
  ~vtkDCMLister();

  int ReadList(const char *filename);
  void ClearList();
  char * PrintList();
  void ListElement(unsigned short Group,
           unsigned short Element, unsigned long length,
           const char *VR, const char *Name);
  char * callback(unsigned short group_code,
        unsigned short element_code,
        unsigned long length,
        char *vr);

  int GetListAll() { return this->ListAll; }
  void SetListAll(int l) { this->ListAll = l; }

  char * GetTCLPreviewRow(int width, int SkipColumn, int max);

 protected:
 void Init();
 int isname(char ch);
 void getelement(int *i);
 void getquotedtext(int *i);

 char *aux_ret;
 char *aux_str;
 char *buff;
 int buff_maxlen;

 private:
 int ListAll;
 DataElement *FirstElement;

 char *line;
 char *element;
};

#endif
