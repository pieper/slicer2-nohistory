/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkBXHParser.cxx,v $
  Date:      $Date: 2006/01/06 17:57:14 $
  Version:   $Revision: 1.4 $

=========================================================================auto=*/
#include "vtkObjectFactory.h"
#include "vtkBXHParser.h"
#include <ctype.h>

vtkStandardNewMacro(vtkBXHParser);


vtkBXHParser::vtkBXHParser()
{
    this->ElementValue = NULL;    
}


vtkBXHParser::~vtkBXHParser()
{
    if (ElementValue != NULL)
    {
        delete [] this->ElementValue;
    }
    
    istream *fs = this->GetStream();
    if (fs != NULL)
    {
        delete fs;
    }
}


char *vtkBXHParser::ReadElementValue(vtkXMLDataElement *element)
{
    if (element == NULL)
    {
        cout << "vtkBXHParser::ReadElementValue: element is NULL.\n";
        return NULL;
    }

    int num = element->GetNumberOfNestedElements();
    if (num > 0)
    {
        cout << "TvtkBXHParser::ReadElementValue: element is NOT a leaf element.\n";
        return NULL;
    }
    else
    {
        istream *stream = this->GetStream();
        if (stream == NULL)
        {
            ifstream *ifs = new ifstream;  
            ifs->open(this->GetFileName(), ios::in); 
            this->SetStream(ifs);
            stream = this->GetStream();
        } 

        // Scans for the start of the actual inline data.
        char c;
        stream->seekg(element->GetXMLByteIndex());
        stream->clear(stream->rdstate() & ~ios::eofbit);
        stream->clear(stream->rdstate() & ~ios::failbit);
        while(stream->get(c) && (c != '>')) ;
        while(stream->get(c) && isspace(c)) ;
        unsigned long pos = stream->tellg();

        // Value length in number of chars.
        stream->seekg(pos-1);
        int count = 0;
        while (stream->get(c) && (c != '<'))
        {
            count++;            
        }
        if (this->ElementValue != NULL)
        {
            delete [] this->ElementValue;
        }
        this->ElementValue = new char [count+2];
 
        // Reads value
        stream->seekg(pos-1);
        stream->get(this->ElementValue, count+1, '<');
        this->ElementValue[count+1] = '\0';
        return this->ElementValue;
    }
}
