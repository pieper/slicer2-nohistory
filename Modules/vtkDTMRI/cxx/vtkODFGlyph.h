/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkODFGlyph.h,v $
  Date:      $Date: 2006/02/14 20:57:41 $
  Version:   $Revision: 1.5 $

=========================================================================auto=*/
#ifndef __vtkODFGlyph_h
#define __vtkODFGlyph_h

#include "vtkDTMRIConfigure.h"
#include <vtkStructuredPointsToPolyDataFilter.h>
#include "vtkImageReformat.h"
#include "vtkImageExtractComponents.h"
#include <vtkMatrix4x4.h>

class vtkLookupTable;
class vtkPolyData;



class VTK_DTMRI_EXPORT vtkODFGlyph : public vtkStructuredPointsToPolyDataFilter {

 public:
  vtkTypeMacro(vtkODFGlyph,vtkStructuredPointsToPolyDataFilter);
  //void PrintSelf(ostream& os, vtkIndent indent);

  // Description
  // Construct object
  static vtkODFGlyph *New();

  // Description:
  // Get/Set factor by which to scale each odf
  vtkSetMacro(ScaleFactor,float);
  vtkGetMacro(ScaleFactor,float);
  
  vtkSetMacro(MinODF,double);
  vtkGetMacro(MinODF,double);
  
  vtkSetMacro(MaxODF,double);
  vtkGetMacro(MaxODF,double);


  // Description:
  // Get/Set vtkLookupTable which holds color values for current output
  //vtkSetObjectMacro(ColorTable,vtkLookupTable);
  vtkGetObjectMacro(ColorTable,vtkLookupTable);

  // Description
  // Transform output glyph locations (not orientations!) 
  // by this matrix.
  //
  // Example usage is as follows:
  // 1) Reformat a slice through a tensor volume.
  // 2) Set VolumePositionMatrix to the reformat matrix.
  //    This is analogous to setting the actor's UserMatrix
  //    to this matrix, which only works for scalar data.
  // 3) The output glyphs are positioned correctly without
  //    incorrectly rotating the tensors, as would be the 
  //    case if positioning the scene's actor with this matrix.
  // 
  vtkSetObjectMacro(VolumePositionMatrix, vtkMatrix4x4);
  vtkGetObjectMacro(VolumePositionMatrix, vtkMatrix4x4);
  
  // Description
  // Transform output glyph orientations
  // by this matrix.
  //
  // Example usage is as follows:
  // 1) If tensors are to be displayed in a coordinate system
  //    that is not IJK (array-based), and the whole volume is
  //    being rotated, each tensor needs also to be rotated.
  //    First find the matrix that positions your volume.
  //    This is how the entire volume is positioned, not 
  //    the matrix that positions an arbitrary reformatted slice.
  // 2) Remove scaling and translation from this matrix; we
  //    just need to rotate each tensor.
  // 3) Set TensorRotationMatrix to this rotation matrix.
  //
  vtkSetObjectMacro(TensorRotationMatrix, vtkMatrix4x4);
  vtkGetObjectMacro(TensorRotationMatrix, vtkMatrix4x4);

  //Description:
  //WldToIjkMatrix: matrix that position the volume in the RAS system
  vtkSetObjectMacro(WldToIjkMatrix, vtkMatrix4x4);
  vtkGetObjectMacro(WldToIjkMatrix, vtkMatrix4x4);
  
  // Methods to set up the reformatter
  //Description:
  // Field of View
  vtkSetMacro(FieldOfView,int);
  vtkGetMacro(FieldOfView,int);

  // Description:
  // When determining the modified time of the filter, 
  // this checks the modified time of the mask input,
  // if it exists.
  unsigned long int GetMTime();

protected:
  vtkODFGlyph();
  ~vtkODFGlyph();
  vtkODFGlyph(const vtkODFGlyph&);  // Not implemented.
  void operator=(const vtkODFGlyph&);  // Not implemented.

  void Execute();

  float ScaleFactor; // Factor by which to scale each odf
  int FieldOfView;
  double MinODF;
  double MaxODF;

  int BrightnessLevels; // # of sets of NUM_SPHERE_POINTS values in ColorTable. Each set at a different brightness gradation.
  vtkLookupTable *ColorTable; // color table for current output. indeces match
                              // scalars of output's pointdata
                  
  vtkMatrix4x4 *VolumePositionMatrix;
  vtkMatrix4x4 *TensorRotationMatrix;
  vtkMatrix4x4 *WldToIjkMatrix;                  
  
  vtkImageExtractComponents **ImageExtract;
  vtkImageReformat **ImageReformat;
  int NumberOfInputComponents;
  
private:
//BTX
  static const int ODF_SIZE = 752;
  static const int NUM_SPHERE_POINTS = ODF_SIZE;
  static const double SPHERE_POINTS[NUM_SPHERE_POINTS][3];
//ETX
};

#endif
