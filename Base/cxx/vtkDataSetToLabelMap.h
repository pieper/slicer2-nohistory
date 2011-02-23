/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkDataSetToLabelMap.h,v $
  Date:      $Date: 2006/04/12 21:53:46 $
  Version:   $Revision: 1.9 $

=========================================================================auto=*/
// .NAME vtkDataSetToLabelMap - convert arbitrary vtkDataSet to a voxel representation with 
// the following encoding (0 = outside voxel, 1 = surface voxel, 2 = inside voxel) 
// .SECTION Description
// author: Delphine Nain, delfin@ai.mit.edu
// vtkDataSetToLabelMap is a filter that converts an arbitrary data set to a
// structured point (i.e., voxel) representation with the following encoding 
// (0 = outside voxel, 1 = surface voxel, 2 = inside voxel). 
// The output Image has the dimensions and origin of the bounding box of the input DataSet. 
// .SECTION see also
// vtkImplicitModeller
// .SECTION autho: Delphine Nain, delfin@ai.mit.edu

#ifndef __vtkDataSetToLabelMap_h
#define __vtkDataSetToLabelMap_h

#include "vtkDataSetToStructuredPointsFilter.h"
#include "vtkSlicer.h"

class vtkShortArray;
class VTK_SLICER_BASE_EXPORT vtkDataSetToLabelMap : public vtkDataSetToStructuredPointsFilter
{

public:
  static vtkDataSetToLabelMap *New();
  vtkTypeMacro(vtkDataSetToLabelMap,vtkDataSetToStructuredPointsFilter);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Construct an instance of vtkDataSetToLabelMap with its sample dimensions
  // set to (50,50,50), and so that the model bounds are
  // automatically computed from its input. The maximum distance is set to 
  // examine the whole grid. This could be made much faster, and probably
  // will be in the future.
     
  // Description:
  // Compute the ModelBounds based on the input geometry.
  void ComputeOutputParameters();

  // Description:
  // Set the i-j-k dimensions on which to sample the distance function.
  void SetOutputSpacing(vtkFloatingPointType i, vtkFloatingPointType j, vtkFloatingPointType k);

  // Description:
  // Set the i-j-k dimensions on which to sample the distance function.
  void SetOutputSpacing(vtkFloatingPointType dim[3]);

  vtkGetVectorMacro(OutputDimensions,int,3);
  vtkGetVectorMacro(OutputSpacing,vtkFloatingPointType,3);
  vtkGetVectorMacro(OutputOrigin,vtkFloatingPointType,3);

  vtkSetMacro(UseBoundaryVoxels,int);
  vtkGetMacro(UseBoundaryVoxels,int);

  vtkGetObjectMacro(InOutScalars,vtkShortArray);
  vtkGetObjectMacro(BoundaryScalars,vtkShortArray);

  // Description:
  // Write the volume out to a specified filename.
  void Write(char *);

protected:
  vtkDataSetToLabelMap();
  ~vtkDataSetToLabelMap();

  vtkDataSetToLabelMap(const vtkDataSetToLabelMap&);
  void operator=(const vtkDataSetToLabelMap&);
  
  void Execute();
  int IsPointInside(vtkFloatingPointType s, vtkFloatingPointType t);
  vtkFloatingPointType ComputeStep(vtkFloatingPointType spacing[3],vtkFloatingPointType vertex0[3],vtkFloatingPointType vertex1[3]);
  void EvaluatePoint(vtkFloatingPointType vo[3], vtkFloatingPointType v1[3], vtkFloatingPointType v2[3], vtkFloatingPointType s, vtkFloatingPointType t,vtkFloatingPointType result[3]);
  // FIXME: i,jk are not parameters
  void BoundaryFill(int i, int j, int k, vtkShortArray *scalars);
  
  vtkFloatingPointType OutputOrigin[3];
  int OutputDimensions[3];
  vtkFloatingPointType OutputSpacing[3];

  vtkShortArray *InOutScalars;
  vtkShortArray *BoundaryScalars;
  
  int UseBoundaryVoxels;
};


#endif


