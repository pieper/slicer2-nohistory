/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModuleNode.cxx,v $
  Date:      $Date: 2007/03/15 19:44:18 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include "vtkMrmlModuleNode.h"
#include "vtkObjectFactory.h"

//------------------------------------------------------------------------------
vtkMrmlModuleNode* vtkMrmlModuleNode::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkMrmlModuleNode");
  if(ret)
  {
    return (vtkMrmlModuleNode*)ret;
  }
  // If the factory was unable to create the object, then create it here.
  return new vtkMrmlModuleNode;
}

//----------------------------------------------------------------------------
vtkMrmlModuleNode::vtkMrmlModuleNode()
{
  // vtkMrmlNode's attributes
    this->ValueVector.clear();
    this->Name = NULL;
    this->ModuleRefID = NULL;
}

//----------------------------------------------------------------------------
vtkMrmlModuleNode::~vtkMrmlModuleNode()
{

    if (this->Name)
    {
        delete [] this->Name;
        this->Name = NULL;
    }
    if (this->ModuleRefID)
    {
        delete [] this->ModuleRefID;
        this->ModuleRefID = NULL;
    }
    
    for (unsigned int i = 0; i < this->ValueVector.size(); i++)
    {
        // clear the array, the destructor will theoretically free memory properly
        this->ValueVector[i].clear();
    }
    this->ValueVector.clear();
}

//----------------------------------------------------------------------------
void vtkMrmlModuleNode::Write(ofstream& of, int nIndent)
{
  // Write all attributes not equal to their defaults
  unsigned int indx;
    
  vtkIndent i1(nIndent);

  of << i1 << "<Module";
  // Strings
  if (this->ModuleRefID && strcmp(this->ModuleRefID, ""))
  {
      of << " moduleRefID='" << this->ModuleRefID << "'";
  }
  if (this->Name && strcmp(this->Name, "")) 
    {
      of << " name='" << this->Name << "'";
    }
  if (this->Description && strcmp(this->Description, "")) 
    {
      of << " description='" << this->Description << "'";
    }
  
  if (this->ValueVector.size() > 0)
  {
      if (0)
      {
      // this way puts all the key/values in one string
      of << " values='";
      for (indx = 0; indx < this->ValueVector.size(); indx++)
      {
          // write out the key and value strings
          of << this->ValueVector[indx][0].c_str() << ":" << this->ValueVector[indx][1].c_str();
          if (indx < (this->ValueVector.size() - 1))
          {
              of << " ";
          }
      }
      of << "'";
      }
      else {
      // make each key/value a first class entry
          for (indx = 0; indx < this->ValueVector.size(); indx++)
          {
              of << " " <<  this->ValueVector[indx][0].c_str() << "='" << this->ValueVector[indx][1].c_str() << "'";
          }
      }
  }
  of << "></Module>\n";
}

//----------------------------------------------------------------------------
// Copy the node's attributes to this object.
// Does NOT copy: ID, FilePrefix, Name
void vtkMrmlModuleNode::Copy(vtkMrmlNode *anode)
{
  vtkMrmlNode::MrmlNodeCopy(anode);
  vtkMrmlModuleNode *node = (vtkMrmlModuleNode *) anode;

  for (unsigned int i = 0; i < this->ValueVector.size(); i++)
  {
      this->ValueVector.push_back(node->ValueVector[i]);
  }
}

//----------------------------------------------------------------------------
void vtkMrmlModuleNode::PrintSelf(ostream& os, vtkIndent indent)
{
    unsigned int indx;
    
    vtkMrmlNode::PrintSelf(os,indent);
    os << indent << "Name: " << (this->Name ? this->Name : "(none)") << "\n";
    os << indent << "Module Reference ID: " << (this->ModuleRefID ? this->ModuleRefID : "(none)") << "\n";
    
    os << indent << "Values:\n";
    for (indx = 0; indx < this->ValueVector.size(); indx++)
    {
        // write out the key and value strings
        os << indent << indent << this->ValueVector[indx][0].c_str() << " = '" << this->ValueVector[indx][1].c_str() << "'\n";
    }
}

//----------------------------------------------------------------------------
void vtkMrmlModuleNode::SetValue(const char *key, const char *value)
{
    unsigned int i;
    

    // check to see that it's not already in the list
    for (i = 0; i < this->ValueVector.size(); i++)
    {
        if (strcmp(ValueVector[i][0].c_str(),key) == 0)
        {
            // if it is, change the value associated with it
            vtkDebugMacro("Updating value at key " << key << " to " << value);
            ValueVector[i][1] = value;
            return;
        }
    }
    // otherwise add it to the end
    vtkstd::vector <vtkstd::string> tmpVec;
    vtkstd::string keyString = key;
    vtkstd::string valueString = value;
    tmpVec.push_back(keyString);
    tmpVec.push_back(valueString);
    this->ValueVector.push_back(tmpVec);
    // clean up temp vars
}


// return an empty string if can't find the key
const char * vtkMrmlModuleNode::GetValue(const char *key)
{
    unsigned int i;
    for (i = 0; i < this->ValueVector.size(); i++)
    {
        if (strcmp(ValueVector[i][0].c_str(),key) == 0)
        {
            return ValueVector[i][1].c_str();
        }
    }
    vtkErrorMacro("Key '" << key << "' not found, returning empty string.");
    return "";
}

// return an string with all keys in double quotes, otherwise return an empty string if none
const char * vtkMrmlModuleNode::GetKeys()
{
    if (this->ValueVector.size() == 0)
    {
        return "";
    }
    vtkstd::string returnString = "";
    for (unsigned int i = 0; i < this->ValueVector.size(); i++)
    {
        returnString += "\"" + this->ValueVector[i][0] + "\"";
        if (i < this->ValueVector.size() - 1)
        {
            returnString  += " ";
        }
    }
    return returnString.c_str();
}

// Overriding the vtkMrmlNode's GetTitle, so that we can return the module ref
// id as well as the node's name
const char * vtkMrmlModuleNode::GetTitle()
{
    char tmp[200]; // classname[100];
    //char nickname[100];
    //int len;

    // make sure we have a name
    if (this->Name == NULL) 
    {
      this->SetName("");
    }
    if (this->ModuleRefID == NULL)
    {
        this->SetModuleRefID("");
    }
    // Create title from current name (if not blank) and module reference id
    if (strcmp(this->ModuleRefID, this->Name) != 0)
    {
        // not the same
        sprintf(tmp, "Module: %s %s", this->ModuleRefID, this->Name);
    }
    else
    {
        // just use one
        sprintf(tmp, "Module: %s", this->ModuleRefID);
    }
    this->SetTitle(tmp);

  // return the current title
  return this->Title;
}
