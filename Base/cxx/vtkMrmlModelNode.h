/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkMrmlModelNode.h,v $
  Date:      $Date: 2006/03/08 14:54:59 $
  Version:   $Revision: 1.27 $

=========================================================================auto=*/
// .NAME vtkMrmlModelNode - MRML node to represent a 3D surface model.
// .SECTION Description
// Model nodes describe polygonal data.  They indicate where the model is 
// stored on disk, and how to render it (color, opacity, etc).  Models 
// are assumed to have been constructed with the orientation and voxel 
// dimensions of the original segmented volume.

#ifndef __vtkMrmlModelNode_h
#define __vtkMrmlModelNode_h

#include "vtkMrmlNode.h"
#include "vtkMatrix4x4.h"
#include "vtkTransform.h"
#include "vtkSlicer.h"

#include <vtkstd/string>
#include <vtkstd/vector>

class VTK_SLICER_BASE_EXPORT vtkMrmlModelNode : public vtkMrmlNode
{
public:
  static vtkMrmlModelNode *New();
  vtkTypeMacro(vtkMrmlModelNode,vtkMrmlNode);
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
  // Model ID
  vtkSetStringMacro(ModelID);
  vtkGetStringMacro(ModelID);
  
  // Description:
  // Path of the data file, relative to the MRML file
  vtkSetStringMacro(FileName);
  vtkGetStringMacro(FileName);

  // Description:
  // Absolute Path of the data file
  vtkSetStringMacro(FullFileName);
  vtkGetStringMacro(FullFileName);

  // Description:
  // Name of the model's color, which is defined by a Color node in a MRML file
  vtkSetStringMacro(Color);
  vtkGetStringMacro(Color);

  // Description:
  // Opacity of the surface expressed as a number from 0 to 1
  vtkSetMacro(Opacity, float);
  vtkGetMacro(Opacity, float);

  // Description:
  // Indicates if the surface is visible
  vtkBooleanMacro(Visibility, int);
  vtkGetMacro(Visibility, int);
  vtkSetMacro(Visibility, int);

  // Description:
  // Specifies whether to clip the surface with the slice planes
  vtkBooleanMacro(Clipping, int);
  vtkGetMacro(Clipping, int);
  vtkSetMacro(Clipping, int);

  // Description:
  // Indicates whether to cull (not render) the backface of the surface
  vtkBooleanMacro(BackfaceCulling, int);
  vtkGetMacro(BackfaceCulling, int);
  vtkSetMacro(BackfaceCulling, int);

  // Description:
  // Indicates whether to render the scalar value associated with each polygon vertex
  vtkBooleanMacro(ScalarVisibility, int);
  vtkGetMacro(ScalarVisibility, int);
  vtkSetMacro(ScalarVisibility, int);

  // Description:
  // Indicates whether to render the vector value associated with each polygon vertex
  vtkBooleanMacro(VectorVisibility, int);
  vtkGetMacro(VectorVisibility, int);
  vtkSetMacro(VectorVisibility, int);

  // Description:
  // Indicates whether to render the tensor value associated with each polygon vertex
  vtkBooleanMacro(TensorVisibility, int);
  vtkGetMacro(TensorVisibility, int);
  vtkSetMacro(TensorVisibility, int);

  // Description:
  // Range of scalar values to render rather than the single color designated by colorName
  vtkSetVector2Macro(ScalarRange, vtkFloatingPointType);
  vtkGetVector2Macro(ScalarRange, vtkFloatingPointType);

  // Description:
  // Perform registration by setting the matrix that transforms this model
  // from its RAS (right-anterior-superior) space to the WLD (world) space
  // of the 3D scene it is a part of.
  void SetRasToWld(vtkMatrix4x4 *reg);
  vtkGetObjectMacro(RasToWld, vtkMatrix4x4);

    // Description:
    // Numerical ID of the color lookup table to use for rendering the overlay
    // for this model
    vtkGetMacro(LUTName,int);
    vtkSetMacro(LUTName,int);

    // Scalar overlay file list

    // Description:
    // number of scalar file names
    int GetNumberOfScalarFileNames();
    void AddScalarFileName(const char *);
    const char *GetScalarFileName(int idx);
    void DeleteScalarFileNames();
    
protected:
  vtkMrmlModelNode();
  ~vtkMrmlModelNode();
  vtkMrmlModelNode(const vtkMrmlModelNode&);
  void operator=(const vtkMrmlModelNode&);

  // Strings
  char *ModelID;
  char *FileName;
  char *FullFileName;
  char *Color;
  int LUTName;
    
  // Numbers
  float Opacity;

  // Booleans
  int Visibility;
  int Clipping;
  int BackfaceCulling;
  int ScalarVisibility;
  int VectorVisibility;
  int TensorVisibility;

  // Arrays
  vtkFloatingPointType ScalarRange[2];

  vtkMatrix4x4 *RasToWld;

    // Scalar overlay
//BTX
    // use a vector to hold the scalar file names
    vtkstd::vector<vtkstd::string>ScalarFileNamesVec;
//ETX
};

#endif
