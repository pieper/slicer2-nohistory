/*=auto=========================================================================

  Portions (c) Copyright 2006 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModuleNode.h,v $
  Date:      $Date: 2006/07/27 15:59:52 $
  Version:   $Revision: 1.2 $

=========================================================================auto=*/
// .NAME vtkMrmlModuleNode - generic MRML node for representing options that
// a module can save.
// .SECTION Description
// The MRML node will allow modules to instantiate an options node to save
// values to xml files and for saving scenes.

#ifndef __vtkMrmlModuleNode_h
#define __vtkMrmlModuleNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkMatrix4x4.h"
#include "vtkTransform.h"
#include "vtkSlicer.h"
#include <vtkstd/string>
#include <vtkstd/vector>

class VTK_SLICER_BASE_EXPORT vtkMrmlModuleNode : public vtkMrmlNode
{
public:
  static vtkMrmlModuleNode *New();
  vtkTypeMacro(vtkMrmlModuleNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Write the node's attributes to a MRML file in XML format
  void Write(ofstream& of, int indent);

  // Description:
  // Copy the node's attributes to this object
  void Copy(vtkMrmlNode *node);

    // Description:
    // Volume ID
    vtkSetStringMacro(ModuleRefID);
    vtkGetStringMacro(ModuleRefID);
   
    //Description:
    //Set a string value    
    void SetValue(const char *key, const char *value);
    //Description:
    //Get a string value
    const char * GetValue(const char *key);

    //Description:
    // For debugging, return a string with all keys
    const char * GetKeys();

    //Description:
    // Override the vtkMrmlNode so we can return a useful title for display
    const char * GetTitle();
    
protected:
  vtkMrmlModuleNode();
  ~vtkMrmlModuleNode();
  vtkMrmlModuleNode(const vtkMrmlModuleNode&);
  void operator=(const vtkMrmlModuleNode&);

    // Description:
    // ID of the referenced module
    char *ModuleRefID;
    
private:
    //a vector of a vector of paired strings, let the caller parse out what it
    //expects when it gets the value part of the key value vector
//BTX
    vtkstd::vector<vtkstd::vector<vtkstd::string> > ValueVector;
//ETX
};

#endif

