/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlOptionsNode.h,v $
  Date:      $Date: 2006/02/14 20:47:10 $
  Version:   $Revision: 1.18 $

=========================================================================auto=*/
// .NAME vtkMrmlOptionsNode - MRML node for storing browser-specific data.
// .SECTION Description
// Option nodes allow browser-specific information to be stored in
// a MRML file.  For example, the 3D Slicer uses Option nodes to store
// the user's 3D viewpoint information since there currently is no
// View node in MRML2.0.

#ifndef __vtkMrmlOptionsNode_h
#define __vtkMrmlOptionsNode_h

//#include <iostream.h>
//#include <fstream.h>
#include "vtkMrmlNode.h"
#include "vtkSlicer.h"

class VTK_SLICER_BASE_EXPORT vtkMrmlOptionsNode : public vtkMrmlNode
{
  public:
  static vtkMrmlOptionsNode *New();
  vtkTypeMacro(vtkMrmlOptionsNode,vtkMrmlNode);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  //--------------------------------------------------------------------------
  // Utility Functions
  //--------------------------------------------------------------------------

  // Description:
  // Write the node's attributes
  void Write(ofstream& of, int indent);

  // Description:
  // Copy the nodes attributes to this object
  void Copy(vtkMrmlNode *node);

  //--------------------------------------------------------------------------
  // Get and Set Functions
  //--------------------------------------------------------------------------

  // Description:
  // Name of the program that should recognize these options.
  vtkGetStringMacro(Program);
  vtkSetStringMacro(Program);

  // Description:
  // Short description of the contents of this node. ie: 'presets'
  vtkGetStringMacro(Contents);
  vtkSetStringMacro(Contents);

  // Description:
  // List of options expressed in this form: key1='value1' key2='value2'
  vtkGetStringMacro(Options);
  vtkSetStringMacro(Options);

  protected:
  vtkMrmlOptionsNode();
  ~vtkMrmlOptionsNode();
  vtkMrmlOptionsNode(const vtkMrmlOptionsNode&);
  void operator=(const vtkMrmlOptionsNode&);

  // Description:
  // Contains information for use by specified program
  // Not needed here since superclass vtkMrmlNode has Options
  //char *Options;

  // Description:
  // Name of program that uses these options (i.e. Slicer)
  char *Program;
  // Description:
  // Type of Options stored in this node (i.e. user preferences)
  char *Contents;
};

#endif









