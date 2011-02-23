/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkOpenGLVolumeTextureMapper3D.h,v $
  Date:      $Date: 2006/01/06 17:58:08 $
  Version:   $Revision: 1.10 $

=========================================================================auto=*/
#ifndef __vtkOpenGLVolumeTextureMapper3D_h
#define __vtkOpenGLVolumeTextureMapper3D_h

#include "vtkVolumeTextureMapper3D.h"

// to declare extension prototypes in GL/gl.h
// (linux and mac get compile errors if you don't)
#define GL_GLEXT_PROTOTYPES

#include <GL/gl.h>

#ifndef GL_EXT_color_table 
// include extension defs and decls that may be newer
// than the ones that are in either GL/gl.h or GL/glext.h
#include "glext.h" 
#endif

//------------------
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

//WINDOWS
#ifndef WIN32
#  include <unistd.h>
#else
#  include <io.h>
#endif


#if !defined(HAVE_GLCOLORTABLE) && defined(HAVE_GLCOLORTABLEEXT)
#  define glColorTable glColorTableEXT
#else
#  if defined(sun) || defined(__sun) || !defined(HAVE_GLCOLORTABLE) && defined(HAVE_GLCOLORTABLESGI)
#     define glColorTable glColorTableSGI
#  endif
#endif

#if !defined(GL_TEXTURE_COLOR_TABLE) && defined(GL_TEXTURE_COLOR_TABLE_EXT)
#  define GL_TEXTURE_COLOR_TABLE GL_TEXTURE_COLOR_TABLE_EXT
#else
#  if !defined(GL_TEXTURE_COLOR_TABLE) && defined(GL_TEXTURE_COLOR_TABLE_SGI)
#    define GL_TEXTURE_COLOR_TABLE GL_TEXTURE_COLOR_TABLE_SGI
#  endif
#endif

#include <vtkVolumeTextureMappingConfigure.h>


class VTK_VOLUMETEXTUREMAPPING_EXPORT vtkOpenGLVolumeTextureMapper3D : public vtkVolumeTextureMapper3D
{
public:
 vtkTypeRevisionMacro(vtkOpenGLVolumeTextureMapper3D,vtkVolumeTextureMapper3D);
 static vtkOpenGLVolumeTextureMapper3D *New();
  
 virtual void Render(vtkRenderer *ren, vtkVolume *vol);
 void CreateSubImages(unsigned char* texture, int size[2], vtkFloatingPointType spacing[3]);
 void RenderQuads(vtkRenderer *ren, vtkVolume *vol);
 void CreateEmptyTexture(int volume);
 void ClipPlane(int plane, vtkFloatingPointType viewUp[3]);
 void InitializeVolRend();
 void NormalizeVector(vtkFloatingPointType vect[3]);
 void ChangeColorTable(int volume, int colorTable[256][4]);
 void CalculatePlaneEquation(vtkFloatingPointType a1, vtkFloatingPointType a2, vtkFloatingPointType a3, vtkFloatingPointType b1, vtkFloatingPointType b2,vtkFloatingPointType  b3, vtkFloatingPointType c1, vtkFloatingPointType c2, vtkFloatingPointType c3, int volume,int num);
 void IntersectionPoint(vtkFloatingPointType result[4], int corner1, int corner2, int plane1, int plane2, vtkFloatingPointType a, vtkFloatingPointType b, vtkFloatingPointType c, vtkFloatingPointType d, int vols);
 void SortVertex(int vertexOrder[12], vtkFloatingPointType vertex[12][3], int* vertexnum, vtkFloatingPointType viewUp[3], vtkFloatingPointType normal[3]);
 void Transformation(); 
 void CalcMaxMinValue();
 void InsertVertex(vtkFloatingPointType vertex[12][3], int *vertexnums, vtkFloatingPointType result[4]);

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//variables
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

int colorTable0[256][4];
int colorTable1[256][4];
int colorTable2[256][4];
int num;
vtkFloatingPointType volumeCornerPoint[4][8][3];
 unsigned char* pix;
int init;
int zVal;
int counter;
int maxVolumes ;
int    using_palette;
vtkFloatingPointType volSize[3][3];
int texSize[3][3];
int textureSizeX[3];
int textureSizeY[3];
int textureSizeZ[3];
int boxSize;
vtkFloatingPointType transformMatrix[3][4][4];
vtkFloatingPointType transformInvMatrix[3][4][4];
vtkFloatingPointType volumePlaneEquation[4][6][4]; 
int cornersInDatasetPlane[6][3];
vtkFloatingPointType maxminCoord[2];
int enableClip[6];
int enableVol[3];
int currentTable[256][4];
GLubyte emptyImage[256][256][128][4];
GLubyte colorImage[256][256][1][4];
GLuint tempIndex3d[3];
GLubyte pixels[256][256][1][1];    
GLubyte pixels4[256][256][1][4];    
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

protected:
  vtkOpenGLVolumeTextureMapper3D();
  ~vtkOpenGLVolumeTextureMapper3D();


private:
  vtkOpenGLVolumeTextureMapper3D(const vtkOpenGLVolumeTextureMapper3D&);  // Not implemented.
  void operator=(const vtkOpenGLVolumeTextureMapper3D&);  // Not implemented.
};


#endif


