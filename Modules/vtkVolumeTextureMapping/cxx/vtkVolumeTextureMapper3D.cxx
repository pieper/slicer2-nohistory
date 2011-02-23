/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkVolumeTextureMapper3D.cxx,v $
  Date:      $Date: 2006/01/26 18:51:12 $
  Version:   $Revision: 1.11 $

=========================================================================auto=*/
#include "vtkVolumeTextureMapper3D.h"
#include "vtkCamera.h"
#include "vtkGraphicsFactoryAddition.h"
#include "vtkImageData.h"
#include "vtkLargeInteger.h"
#include "vtkMatrix4x4.h"
#include "vtkPointData.h"
#include "vtkRenderWindow.h"
#include "vtkRenderer.h"
#include "vtkTransform.h"
#include "vtkVolumeProperty.h"
#include "vtkImageResample.h"
#include "vtkImageCast.h"
#include "math.h"
#include <GL/gl.h>

#ifdef VOLUME_TEXTURE_DEBUG
FILE* fd = fopen("error_vtkVolumeTextureMapper3D.txt", "w");
#else
FILE* fd = stderr;
#endif

int currentCounter= 0;
template <class T>

//-----------------------------------------------------
//Name: vtkVolumeTextureMapper3D_TextureOrganization
//Description: Organization of textures
//-----------------------------------------------------
void vtkVolumeTextureMapper3D_TextureOrganization( T *data_ptr,                     
                           int size[3],
                           int volume, 
                           vtkVolumeTextureMapper3D *me )
{

  int              i, j, k;
  int              kstart, kend, kinc;
  unsigned char    *tptr;
  T                *dptr;
  unsigned char    *rgbaArray = me->GetRGBAArray();
  vtkRenderWindow  *renWin = me->GetRenderWindow();
#if (VTK_MAJOR_VERSION >= 5)
  vtkFloatingPointType            dataSpacing[3];
#else
  float dataSpacing[3];
#endif
  vtkFloatingPointType            spacing[3];
  unsigned char    *texture;
  int              *zAxis=0, *yAxis=0, *xAxis=0;
  int              loc, inc=0;
  int              textureOffset=0;  
  int              dimensions[3];
  xAxis = &i;
  yAxis = &j;
  zAxis = &k;
  inc = 1;
  
  me->GetDataSpacing(dataSpacing);
  // Create space for the texture
  for (int l=0; l< 3;l++)
  {
    dimensions[l] = me->GetTextureDimension(volume, l);
    spacing[l]=dataSpacing[l];

  }

  texture = new unsigned char[4*dimensions[0]*dimensions[1]];

  kstart = 0;
  kend= me-> GetTextureDimension(volume, 2);
  kinc = me->GetInternalSkipFactor();
  for ( k = kstart; k != kend; k+=kinc )
  {
    for ( j = 0; j < dimensions[1]; j++ )
    {
      i = 0;
      //tptr is the pointer where to store the texture
      //start at texture and add addresses according to j
      tptr = texture+4*j*dimensions[0];
      loc = (*zAxis)*dimensions[0]*dimensions[1]+(*yAxis)*dimensions[0]+(*xAxis);
      dptr = data_ptr + loc;
 
      for ( i = 0; i < dimensions[0]; i++ )
      { 
        //copy information from (rgbaArray + (*dptr)*4) with the length 4 to tptr
        memcpy( tptr, rgbaArray + (*dptr)*4, 4 );
        tptr += 4;
        dptr += inc;
      }
    }
    
    if ( renWin->CheckAbortStatus() )
    {
      break;
    }
  
    //temp hist start
    int texPtr = 0;
    for (int y = 0; y < dimensions[1]; y++)
    {
        for (int x = 0; x < dimensions[0]; x++) 
        {
            int tempVal = (int)texture[texPtr];
            int histVal = me->GetHistValue(volume, tempVal);
            int histMax = me->GetHistMax(volume);
            me->SetHistValue(volume, tempVal);
            histVal++;
            me->SetHistMax(volume, histVal);
            texPtr=texPtr+4;    
        }
    }
    texPtr = 0;

    me->CreateSubImages(texture, size, spacing);    
 
  }
  delete [] texture;
}

vtkCxxRevisionMacro(vtkVolumeTextureMapper3D, "$Revision: 1.11 $");

//----------------------------------------------------------------------------
// Needed when we don't use the vtkStandardNewMacro.
vtkInstantiatorNewMacro(vtkVolumeTextureMapper3D);
//----------------------------------------------------------------------------

//-----------------------------------------------------
//Name: vtkVolumeTextureMapper3D 
//Description: Constructor
//-----------------------------------------------------
vtkVolumeTextureMapper3D::vtkVolumeTextureMapper3D()
{

  this->Texture               = NULL;
  diffX = 0;
  diffY = 0;
  clipPlaneNum = 0;
  numberOfPlanes = 0;
  tMatrixChanged[0] = 1;
  tMatrixChanged[1] = 0;
  tMatrixChanged[2] = 0;
    
  for (int i = 0; i < 3; i++)
  {
     for (int j = 0; j < 4; j++)
     {
        for (int k = 0; k < 4; k++)
        {
            currentTransformation[i][j][k] = 0;
        }
     }    
     currentTransformation[i][0][0] = 1;
     currentTransformation[i][1][1] = 1;
     currentTransformation[i][2][2] = 1;
     currentTransformation[i][3][3] = 1;
  }
  for (int l = 0; l< 3; l++)
  {
    for (int j = 0; j < 3; j++)
    {
      this->SetDimension(l, j, 256);
    }
  }
  LUT0 = vtkLookupTable::New();
  LUT1 = vtkLookupTable::New();
  LUT2 = vtkLookupTable::New();
}

//-----------------------------------------------------
//Name: ~vtkVolumeTextureMapper3D
//Description: Destructor
//-----------------------------------------------------
vtkVolumeTextureMapper3D::~vtkVolumeTextureMapper3D()
{
  if ( this->Texture )
  {
    delete [] this->Texture;
  }
  LUT0->Delete();
  LUT1->Delete();
  LUT2->Delete();
}


//-----------------------------------------------------
//Name: New
//Description: 
//-----------------------------------------------------
vtkVolumeTextureMapper3D *vtkVolumeTextureMapper3D::New()
{
  // First try to create the object from the vtkObjectFactoryAddition
  vtkObject* ret =  vtkGraphicsFactoryAddition::CreateInstance("vtkVolumeTextureMapper3D");
  return (vtkVolumeTextureMapper3D*)ret;
}

//-----------------------------------------------------
//Name: GenerateTextures
//Description: Generation of textures
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GenerateTextures( vtkRenderer *ren, vtkVolume *vol, int volume )
{
  vtkImageData           *input = this->GetInput();
  vtkImageData           *inputResample = vtkImageData::New();
  vtkImageResample       *resample = vtkImageResample::New();
  vtkImageCast           *imageCast =  vtkImageCast::New();
  int                    size[3];
  int                    extent[6];
  void                   *inputPointer;
  int                    inputType;
  int                    texDim[3];
  vtkFloatingPointType   scaleFactor[3];
  
  histMax[volume] = 0;
  for (int j = 0; j < 256; j++)
  {
    histArray[volume][j] = 0;
  }
  
  if ( this->Texture )
  {
    delete [] this->Texture;
    this->Texture = NULL;
  }
  
  vtkFloatingPointType spacing[3];
  input->GetDimensions(size);
  input->GetSpacing(spacing);
  input->GetExtent(extent);
  size[0] = extent[1]+1;
  size[1] = extent[3]+1;
  size[2] = extent[5]+1;

  texDim[0]= this-> GetTextureDimension(volume, 0);
  texDim[1]= this-> GetTextureDimension(volume, 1);
  texDim[2]= this-> GetTextureDimension(volume, 2);
  
  scaleFactor[0]= ((vtkFloatingPointType)texDim[0]-0.5)/(vtkFloatingPointType)extent[1];
  scaleFactor[1]= ((vtkFloatingPointType)texDim[1]-0.5)/(vtkFloatingPointType)extent[3];
  scaleFactor[2]= ((vtkFloatingPointType)texDim[2]-0.5)/(vtkFloatingPointType)extent[5];

  //if texture size is not the same size as the volume extent - resample
  if (scaleFactor[0] != 1 || scaleFactor[1] != 1 || scaleFactor[2] != 1)
  {
    inputResample->DeepCopy(input);
    inputResample->GetExtent(extent);
    
    resample->SetInput(inputResample);
        
    resample-> SetAxisMagnificationFactor( 0, scaleFactor[0]);
    resample-> SetAxisMagnificationFactor( 1, scaleFactor[1]);
    resample-> SetAxisMagnificationFactor( 2, scaleFactor[2]);
    resample-> Update();

    inputResample->DeepCopy(resample->GetOutput());
    inputResample->SetScalarTypeToUnsignedShort();
    inputResample->UpdateData();

    inputPointer=inputResample->GetPointData()->GetScalars()->GetVoidPointer(0);
    inputType = inputResample->GetPointData()->GetScalars()->GetDataType();

    inputResample->GetExtent(extent);
  }
  else 
  {
     inputPointer = input->GetPointData()->GetScalars()->GetVoidPointer(0);
     inputType    = input->GetPointData()->GetScalars()->GetDataType();
  }
  
  switch ( inputType )
  {
    case VTK_UNSIGNED_CHAR:
      vtkVolumeTextureMapper3D_TextureOrganization( (unsigned char *)inputPointer, size, volume, this );
      break;
    case VTK_UNSIGNED_SHORT:
      vtkVolumeTextureMapper3D_TextureOrganization( (unsigned short *)inputPointer,  size, volume, this );
      break;
    default:
      vtkErrorMacro("vtkVolumeTextureMapper3D only works with unsigned short and unsigned char data.\n" << 
          "Input type: " << inputType << " given.");
  }
}

//-----------------------------------------------------
//Name: InitializeRender 
//Description: Initialization
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::InitializeRender( vtkRenderer *ren,
                                                 vtkVolume *vol,
                                                 int majorDirection )
{
  boxSize = 128;
  this->InternalSkipFactor = 1;
  this->vtkVolumeTextureMapper::InitializeRender( ren, vol );
}

//-----------------------------------------------------
//Name: ComputePlaneEquation  (internal function)
//Description: Compute a clip plane equation
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ComputePlaneEquation(double plane[4], double point[3], double normal[3])
{
  plane[0]=normal[0];
  plane[1]=normal[1];
  plane[2]=normal[2];
  plane[3]=normal[0]*point[0]+normal[1]*point[1]+normal[2]*point[2];
}

//-----------------------------------------------------
//Name: Rotate (internal function)
//Description: 
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::Rotate(int dir, double angle)
{
   vtkMatrix4x4       *rotdir = vtkMatrix4x4::New();
   rotdir->Identity();
    
   if (dir == 0)
   {
      rotdir->SetElement(1,1,cos(angle));
      rotdir->SetElement(1,2,sin(angle)); 
      rotdir->SetElement(2,1,-sin(angle));
      rotdir->SetElement(2,2,cos(angle));
   } 
   else if (dir == 1)
   {
       rotdir->SetElement(0,0,cos(angle));
      rotdir->SetElement(0,2,-sin(angle));
      rotdir->SetElement(2,0,sin(angle));
      rotdir->SetElement(2,2,cos(angle));
   }
   else 
   {
      rotdir->SetElement(0,0,cos(angle));
      rotdir->SetElement(0,1,sin(angle));
      rotdir->SetElement(1,0,-sin(angle));
      rotdir->SetElement(1,1,cos(angle));
   }
  
   rotate->DeepCopy(rotdir);
   rotdir->Delete();   
}
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// Functions below can be called by users
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


//-o-o-o-o-o-o-o-o-o-o-
//General functions
//-o-o-o-o-o-o-o-o-o-o-

//-----------------------------------------------------
//Name: SetEnableVolume
//Description: vtkVolumeTextureMapper3D supports 3 volumes.
//With this function the volumes are set to enable or disable.
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetEnableVolume(int volume, int type)
{
  enableVolume[volume] = type;
}

//-----------------------------------------------------
//Name: GetEnableVolume
//Description: vtkVolumeTextureMapper3D supports 3 volumes.
//This function returns an array with information of which volumes
//that are enabled.
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetEnableVolume(int enVol[3]) 
{
  for (int i = 0; i < 3; i++)
  {
    enVol[i] = enableVolume[i];
  }
}

//-----------------------------------------------------
//Name: SetNumberOfVolumes
//Description: Set the number of volumes wanted (max=3)
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetNumberOfVolumes(int num)
{
  volNum = num;
}

//-----------------------------------------------------
//Name: SetBoxSize
//Description: Set the size of the box surronding the volumes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetBoxSize(vtkFloatingPointType size)
{
  boxSize = (int)size;
}

//-----------------------------------------------------
//Name: GetBoxSize
//Description: Return the size of the box surrounding the volumes
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetBoxSize()
{
  return boxSize;
}

//-----------------------------------------------------
//Name: SetOrigin
//Description: Set the size of the box surronding the volumes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetOrigin(vtkFloatingPointType o_x, vtkFloatingPointType o_y, vtkFloatingPointType o_z)
{
  origin[0]=o_x;
  origin[1]=o_y;
  origin[2]=o_z;
}

//-----------------------------------------------------
//Name: GetOrigin
//Description: Return the size of the box surrounding the volumes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetOrigin(vtkFloatingPointType o[3])
{
  for(int i = 0; i < 3; i++)
  {
    o[i]= origin[i];
  }
}

//-----------------------------------------------------
//Name: SetCounter
//Description: A counter 
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetCounter(int counter)
{
  currentCounter = counter;
}

//-----------------------------------------------------
//Name: GetCounter
//Description: Get the current counter
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetCounter()
{
  return currentCounter;
}

//-----------------------------------------------------
//Name: SetNumberOfPlanes
//Description: Set the amount of planes to be used
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetNumberOfPlanes(int planes)
{
  numberOfPlanes = planes;
  for (int vol = 0; vol < 3; vol++ )
  {
    changedTable[vol] = true;
  }
}

//-----------------------------------------------------
//Name: GetNumberOfPlanes
//Description: Get the number of planes that are used
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetNumberOfPlanes()
{
  return numberOfPlanes;
}


//-----------------------------------------------------
//Name: SetDimension
//Description: Set the dimension of a volume (must be powers of two)
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetDimension(int volume, int dir, int dims)
{
  dimension[volume][dir] = dims;
}


//-----------------------------------------------------
//Name: GetTextureDimension
//Description: Get the texture dimension
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetTextureDimension(int volume, int dir)
{
  return dimension[volume][dir];
}

//-o-o-o-o-o-o-o-o-o-o-
//Clip plane functions
//-o-o-o-o-o-o-o-o-o-o-

//-----------------------------------------------------
//Name: EnableClipLines
//Description: If the user wants to see clip plane lines
//then this funtion is set to enable 
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::EnableClipLines(int value)
{
  clipLines = value;
}


//-----------------------------------------------------
//Name: IsClipLinesEnable
//Description: Check if the clip plane line is enabled
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::IsClipLinesEnable()
{
  return clipLines;
}

//-----------------------------------------------------
//Name: VolumesToClip
//Description: Set which volumes that are going to be clipped
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::VolumesToClip(int vol, int value)
{
  if (value == 1) 
  {
    volToClip[vol] = true;
  }
  else 
  {
    volToClip[vol] = false;
  }
}

//-----------------------------------------------------
//Name: GetVolumesToClip
//Description: Get information of which volumes that are 
//going to be clipped
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetVolumesToClip(bool vToClip[3])
{
  for(int i = 0; i < 3; i++)
  {
    vToClip[i] = volToClip[i];
  }
}

//-----------------------------------------------------
//Name: SetNumberOfClipPlanes
//Description: Set the number of clip planes to use
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetNumberOfClipPlanes(int planeNum)
{    
  clipPlaneNum = planeNum;
}


//-----------------------------------------------------
//Name: GetNumberOfClipPlanes
//Description: Get the number of clip planes used
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetNumberOfClipPlanes()
{
  return clipPlaneNum;
}



//-----------------------------------------------------
//Name: InitializeClipPlanes
//Description: Initialization of clip planes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::InitializeClipPlanes()
{
  currentType = 0;
  for (int i = 0; i < 3; i++)
  {
    volToClip[i] = false;
  }
  rotate = vtkMatrix4x4::New();
  rotate->Identity();
  this->ResetClipPlanes(0);
  this->SetEnableClipPlanes(0, 1);
  for (int c = 1; c < 6; c++)
  {
    this->SetEnableClipPlanes(c, 0);
  }
  this->ChangeType(0);
}

//-----------------------------------------------------
//Name: ChangeDist
//Description: Change the clip plane distance from origin
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ChangeDist(int plane, int dist)
{
  currentDistance[plane] = dist;
  this->UpdateClipPlaneEquation(plane);
}

//-----------------------------------------------------
//Name: ChangeSpacing
//Description: Change the spacing between two clip planes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ChangeSpacing(int spacing)
{
  currentSpacing = spacing;
  this->UpdateClipPlaneEquation(0);    
}

//-----------------------------------------------------
//Name: ChangeType
//Description: Change the current type of clipping
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ChangeType(int type)
{
  currentType = type;
  this->ResetClipPlanes(currentType);    
}

//-----------------------------------------------------
//Name: GetClipNum
//Description: Get the number of clip planes required for 
//the current type of clipping 
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetClipNum()
{
  if (currentType == 2)
  {
    return 6;
  }
  else
  {
    return currentType+1;
  }
}

//-----------------------------------------------------
//Name: ResetClipPlanes
//Description: Reset the current clip planes
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ResetClipPlanes(int type)
{
  for (int k = 0; k < 6; k++)
  {
    for (int p = 0; p<3; p++)
    {
      currentPlane[k][p]=0;
      currentPlane[k][p]=0;
      currentPlane[k][p]=0;
    }
    if (currentType != 2)
    {
      SetEnableClipPlanes(k, 0);
    }
  }
  currentPlane[0][0]= 1.0;
  currentPlane[1][0]= -1.0;
  currentPlane[2][1]= 1.0;
  currentPlane[3][1]= -1.0;
  currentPlane[4][2]= 1.0;
  currentPlane[5][2]= -1.0;
          
  if (currentType == 0)
  {
    SetEnableClipPlanes(0, 1);    
  }
  else if (currentType == 1)
  {
    SetEnableClipPlanes(0, 1);
    SetEnableClipPlanes(1, 1);    
  }
  else 
  {
    for (int i = 0; i < 6; i++)
      {
    SetEnableClipPlanes(i, 1);
      }
  }
  for (int i = 0; i < 3; i++)
  {
    currentAngle[i] = 0;
  }
}

//-----------------------------------------------------
//Name: ChangeClipPlaneDir
//Description: Change the direction of a clip plane
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ChangeClipPlaneDir(int plane, int dir, vtkFloatingPointType angle)
{
  vtkMatrix4x4  *tempPlaneEquation = vtkMatrix4x4::New();
  tempPlaneEquation->Identity();
  tempPlaneEquation->SetElement(0, 3, 1);
  angle = angle*3.14/180;
  angle = angle - currentAngle[dir];
  currentAngle[dir]= angle+currentAngle[dir];
     
  this->Rotate(1, currentAngle[1]);
  tempPlaneEquation->Multiply4x4(rotate, tempPlaneEquation, tempPlaneEquation);
  this->Rotate(2, currentAngle[2]);
  tempPlaneEquation->Multiply4x4(rotate, tempPlaneEquation, tempPlaneEquation);
  this->Rotate(0, currentAngle[0]);
  tempPlaneEquation->Multiply4x4(rotate, tempPlaneEquation, tempPlaneEquation);
  
  currentPlane[plane][0] = tempPlaneEquation->GetElement(0, 3);
  currentPlane[plane][1] = tempPlaneEquation->GetElement(1, 3);
  currentPlane[plane][2] = tempPlaneEquation->GetElement(2, 3);
  this->UpdateClipPlaneEquation(plane);
  tempPlaneEquation->Delete();
}


//-----------------------------------------------------
//Name: UpdateClipPlaneEquation
//Description: Updates a clip plane equation
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::UpdateClipPlaneEquation(int plane)
{
  double normDirectionVector[3];
  double planePoint[3];
  double planePointRot[3];
  double newPlane[4];
  double newPlanePoint[3];
  double normPlaneVector[3];
  
  //normal vector
  normDirectionVector[0] = currentPlane[plane][0]/sqrt(currentPlane[plane][0]*currentPlane[plane][0]
                              +currentPlane[plane][1]*currentPlane[plane][1]
                              +currentPlane[plane][2]*currentPlane[plane][2]);
  normDirectionVector[1] = currentPlane[plane][1]/sqrt(currentPlane[plane][0]*currentPlane[plane][0]
                              +currentPlane[plane][1]*currentPlane[plane][1]
                              +currentPlane[plane][2]*currentPlane[plane][2]);
  normDirectionVector[2] = currentPlane[plane][2]/sqrt(currentPlane[plane][0]*currentPlane[plane][0]
                              +currentPlane[plane][1]*currentPlane[plane][1]
                              +currentPlane[plane][2]*currentPlane[plane][2]);

  //plane point
  if (currentType == 0)
  {
    planePoint[0] = currentDistance[plane]*normDirectionVector[0];
    planePoint[1] = currentDistance[plane]*normDirectionVector[1];
    planePoint[2] = currentDistance[plane]*normDirectionVector[2];
    
    this->ComputePlaneEquation(newPlane, planePoint, normDirectionVector);
    planeEq[plane][0]=newPlane[0];
    planeEq[plane][1]=newPlane[1];
    planeEq[plane][2]=newPlane[2];
    planeEq[plane][3]=newPlane[3];
  }

  //if double
  else if (currentType == 1)
  {
    planePoint[0] = (currentDistance[plane]+currentSpacing)*normDirectionVector[0];
    planePoint[1] = (currentDistance[plane]+currentSpacing)*normDirectionVector[1];
    planePoint[2] = (currentDistance[plane]+currentSpacing)*normDirectionVector[2];
    
    this->ComputePlaneEquation(newPlane, planePoint, normDirectionVector);
    planeEq[0][0]=newPlane[0];
    planeEq[0][1]=newPlane[1];
    planeEq[0][2]=newPlane[2];
    planeEq[0][3]=newPlane[3];
    
    planePoint[0] = (currentDistance[plane]-currentSpacing)*normDirectionVector[0];
    planePoint[1] = (currentDistance[plane]-currentSpacing)*normDirectionVector[1];
    planePoint[2] = (currentDistance[plane]-currentSpacing)*normDirectionVector[2];
    
    normDirectionVector[0] = -normDirectionVector[0];
    normDirectionVector[1] = -normDirectionVector[1];
    normDirectionVector[2] = -normDirectionVector[2];
    
    this->ComputePlaneEquation(newPlane, planePoint, normDirectionVector);
    planeEq[1][0]=newPlane[0];
    planeEq[1][1]=newPlane[1];
    planeEq[1][2]=newPlane[2];
    planeEq[1][3]=newPlane[3];
  }
  else if (currentType == 2) 
  {
    planePoint[0] = (currentDistance[plane]+currentSpacing)*normDirectionVector[0];
    planePoint[1] = (currentDistance[plane]+currentSpacing)*normDirectionVector[1];
    planePoint[2] = (currentDistance[plane]+currentSpacing)*normDirectionVector[2];
    
    planePointCube[0][0] = 1;
    planePointCube[0][1] = 0;
    planePointCube[0][2] = 0;
    planePointCube[1][0] = -1;
    planePointCube[1][1] = 0;
    planePointCube[1][2] = 0;
    planePointCube[2][0] = 0;
    planePointCube[2][1] = 1;
    planePointCube[2][2] = 0;
    planePointCube[3][0] = 0; 
    planePointCube[3][1] = -1;
    planePointCube[3][2] = 0;
    planePointCube[4][0] = 0;
    planePointCube[4][1] = 0;
    planePointCube[4][2] = 1; 
    planePointCube[5][0] = 0;
    planePointCube[5][1] = 0;
    planePointCube[5][2] = -1;
    
        
    for (int j = 0; j < 6; j++)
    {
    
      vtkMatrix4x4  *planePoint = vtkMatrix4x4::New();    
      planePoint->SetElement(0,3, planePointCube[j][0]);
      planePoint->SetElement(1,3, planePointCube[j][1]);
      planePoint->SetElement(2,3, planePointCube[j][2]);

      planePoint->Multiply4x4(rotate, planePoint, planePoint);

      planePointRot[0] = planePoint->GetElement(0,3);
      planePointRot[1] = planePoint->GetElement(0,3);
      planePointRot[2] = planePoint->GetElement(0,3);

      normPlaneVector[0] = planePointRot[0]/sqrt(planePointRot[0]*planePointRot[0]
                        +planePointRot[1]*planePointRot[1]
                        +planePointRot[2]*planePointRot[2]);
      normPlaneVector[1] = planePointRot[1]/sqrt(planePointRot[0]*planePointRot[0]
                        +planePointRot[1]*planePointRot[1]
                        +planePointRot[2]*planePointRot[2]);
      normPlaneVector[2] = planePointRot[2]/sqrt(planePointRot[0]*planePointRot[0]
                         +planePointRot[1]*planePointRot[1]
                         +planePointRot[2]*planePointRot[2]);

      newPlanePoint[0] = currentDistance[plane]*normDirectionVector[0]+currentSpacing*normPlaneVector[0];
      newPlanePoint[1] = currentDistance[plane]*normDirectionVector[1]+currentSpacing*normPlaneVector[1];
      newPlanePoint[2] = currentDistance[plane]*normDirectionVector[2]+currentSpacing*normPlaneVector[2];
            
      this->ComputePlaneEquation(newPlane, newPlanePoint, normPlaneVector);
      
      planeEq[j][0]=newPlane[0];
      planeEq[j][1]=newPlane[1];
      planeEq[j][2]=newPlane[2];
      planeEq[j][3]=newPlane[3];
      planePoint->Delete();
    }
  }
}

//-----------------------------------------------------
//Name: SetEnableClipPlanes
//Description: Set a clip plane to enable
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetEnableClipPlanes(int plane, int type)
{
  clipPlaneEnable[plane] = type;
}

//-----------------------------------------------------
//Name: GetEnableClipPlanes
//Description: Find out if a clip plane is enable
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetEnableClipPlanes(int enableClip[6])
{
  for (int i = 0; i < 6; i++)
  {
    enableClip[i] = clipPlaneEnable[i];
  }
}

//-----------------------------------------------------
//Name: GetClipPlaneEquation
//Description: Get a clip plane equation 
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetClipPlaneEquation(double planeEquation[4], int planeNum)
{
  for(int i = 0; i < 4; i++)
  {
    planeEquation[i] = planeEq[planeNum][i];
  }
}


//-o-o-o-o-o-o-o-o-o-o-
//Color functions
//-o-o-o-o-o-o-o-o-o-o-


//-----------------------------------------------------
//Name: SetHistMax
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetHistMax(int volume, int value)
{
    histMax[volume]++;
}

//-----------------------------------------------------
//Name: GetHistMax
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetHistMax(int volume)
{
  return histMax[volume];
}

//-----------------------------------------------------
//Name: SetHistValue
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetHistValue(int volume, int index)
{
  histArray[volume][index]++;
}

//-----------------------------------------------------
//Name: GetHistValue
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetHistValue(int volume, int index)
{
  if (histMax[volume] != 0)
  {
    int histVal = (int)(histArray[volume][index]/255);
    return histVal;
  }
  else
  {
    return 0;
  }
}

//-----------------------------------------------------
//Name: ClearTF
//Description: Clear the transfer functions
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ClearTF()
{
  for (int i = 0; i < 3; i++)
  {
    TFnum[i] = 0;     
  }
}

//-----------------------------------------------------
//Name: GetNumPoint
//Description: Get number of points in the transfer function
//for a specific volume and type
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetNumPoint(int currentVolume)
{
  return (TFnum[currentVolume]-1);
}

//-----------------------------------------------------
//Name: GetPoint
//Description: Get the value of a specific transfer function point
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetPoint(int currentVolume, int num, int xORy)
{
  return TFdata[num][currentVolume][xORy];
}

//-----------------------------------------------------
//Name: AddTFPoint
//Description: Add a transfer function point
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::AddTFPoint(int volume, int point, int value)
{
  bool last = true;

  if (point < 0)
  {
    point =0;
  }
  if (value <0)
  {
    value =0;
  }
 
  if (TFnum[volume] == 0)
  {
      TFdata[0][volume][0] = point; 
      TFdata[0][volume][1] = value;
      TFnum[volume]++;
         last = false;
  }
  else
  {
      for(int i = 0; i < TFnum[volume]; i++ )
      {
          if (TFdata[i][volume][0] >= point)
          {
              //sort
              for (int j = TFnum[volume]; j > i; j--) 
              {
                  TFdata[j][volume][0] = TFdata[j-1][volume][0]; 
                  TFdata[j][volume][1] = TFdata[j-1][volume][1];
              }    
              TFdata[i][volume][0] = point;
              TFdata[i][volume][1] = value;
              TFnum[volume]++;
              last = false;
              break;
          }
      }
  }        
  if (last == true) 
  {
     TFdata[TFnum[volume]][volume][0] = point;
     TFdata[TFnum[volume]][volume][1] = value;
     TFnum[volume]++;
  }
  changedTable[volume] = true;
}



//-----------------------------------------------------
//Name: RemoveTFPoint
//Description: Remove a transfer function point
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::RemoveTFPoint(int volume, int pointPos)
{
  for (int j = pointPos; j < TFnum[volume]; j++) 
  {
      TFdata[j][volume][0] = TFdata[j+1][volume][0]; 
      TFdata[j][volume][1] = TFdata[j+1][volume][1];                
  }
 
  TFnum[volume]--;
}


//-----------------------------------------------------
//Name: InitializeColors
//Description: Initialization of colors
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::IniatializeColors()
{
  for (int i = 0; i < 3; i++) 
  {
    for (int j = 0; j < 4; j++)
    {
      colorMinMax[i][j][0]= 0;
      colorMinMax[i][j][1]= 255;
    }
  }
}

//-----------------------------------------------------
//Name: SetColorMinMax
//Description: Set values to vary between
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetColorMinMax(int volume, int minelmax, int r, int g, int b){
  colorMinMax[volume][0][minelmax] = r;
  colorMinMax[volume][1][minelmax] = g;
  colorMinMax[volume][2][minelmax] = b;
  changedTable[volume] = true;
}
    
//-----------------------------------------------------
//Name: GetColorMinMax
//Description: Get values to vary between
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetColorMinMax(int volume, int minelmax, int rgb)
{
  return colorMinMax[volume][rgb][minelmax];
}

//-----------------------------------------------------
//Name: SetColorTable
//Description: Set the color table with a vtkLookupTable
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetColorTable(vtkLookupTable *lookupTable, int volume)
{
  if (volume == 0)
  {
      LUT0->DeepCopy(lookupTable);
  }
  else if (volume == 1)
  {
      LUT1->DeepCopy(lookupTable);
  }
  else if (volume == 2)
  {
      LUT2->DeepCopy(lookupTable);
  }
  else 
  {
      vtkErrorMacro("A color table is set to a volume that doesn't exist.");
  }

  changedTable[volume] = true;
}

//-----------------------------------------------------
//Name: GetColorTable
//Description: Set the color table with a vtkLookupTable
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetColorTable(int colorTable[256][4], int volume)
{
 
  vtkFloatingPointType colors[4];
  double alphaValue[256];
  int least1, least2;
  double diff1, diff2, quote;

  for (int num = 0; num < TFnum[volume]; num++ )
  {
    for (int i = TFdata[num][volume][0]; i <= TFdata[num+1][volume][0]; i++)
    {
      diff1=(double)TFdata[num+1][volume][1]-(double)TFdata[num][volume][1];
      diff2=(double)TFdata[num+1][volume][0]-(double)TFdata[num][volume][0];
      quote = sqrt(diff1*diff1)/sqrt(diff2*diff2);
      if (TFdata[num+1][volume][1]<TFdata[num][volume][1])
      {
        least2=TFdata[num+1][volume][1];
      }
      else
      {
        least2=TFdata[num][volume][1];
      }
      if (TFdata[num+1][volume][0]<TFdata[num][volume][0])
      {
        least1=TFdata[num+1][volume][0];
      }
      else
      {
        least1=TFdata[num][volume][0];
      }
     
        alphaValue[i]=  ((i-least1)*quote+least2)/numberOfPlanes;
        if (alphaValue[i]<0)
        {
          alphaValue[i]=0;
        }
        else if(alphaValue[i] > 1)
        {
            alphaValue[i] = 1;
        }
      }
  }
 
  vtkLookupTable *LUT = vtkLookupTable::New();
  if (volume == 0)
  {
      LUT->DeepCopy(LUT0);
  }
  else if (volume == 1)
  {
      LUT->DeepCopy(LUT1);
  }
  else if (volume == 2)
  {
      LUT->DeepCopy(LUT2);
  }

  LUT->SetNumberOfColors(256);
  LUT->Build();
  for (int i = 0; i < 256; i++)
  {
    LUT->GetTableValue(i, colors);
    colors[3] = alphaValue[i];
    LUT->SetTableValue(i, colors);

    for (int j = 0; j < 4; j++)
    {
        colorTable[i][j] = (int)ceil(colors[j]*255);    
    }
  }
  LUT->GetTableValue(1, colors);
  for (int j = 0; j < 4; j++)
    {
        colorTable[0][j] = (int)ceil(colors[j]*255);    
    }
}


//-----------------------------------------------------
//Name: GetArrayPos
//Description: Get the array position for a point in the 
//transfer function
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::GetArrayPos(int volume, int point, int value, int boundX, int boundY) 
{
 for (int i = 0; i < TFnum[volume]; i++ )
  {
    if ((TFdata[i][volume][0] < (point+boundX) 
      && TFdata[i][volume][0] > (point-boundX)) 
      && (TFdata[i][volume][1] < (value+boundY) 
      && TFdata[i][volume][1] > (value-boundY)))
    {
      diffX = TFdata[i][volume][0] - point;
      diffY = TFdata[i][volume][1] - value;
      return i;
    }
  }
  return -1;
}


//-----------------------------------------------------
//Name: ChangeTFPoint
//Description: Change an existing transfer function point
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::ChangeTFPoint(int volume,int pos, int point, int value)
{
  TFdata[pos][volume][0] = point+diffX;
  TFdata[pos][volume][1] = value+diffY;
  changedTable[volume] = true;
}

//-----------------------------------------------------
//Name: IsColorTableChanged
//Description: Is the color table changed since update?
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::IsColorTableChanged(int volume)
{
  if (changedTable[volume] == true)
  {
    changedTable[volume] = false;
    return 1;
  }
  else
  {
    return 0;
  }     
}

//-o-o-o-o-o-o-o-o-o-o-
//Transform functions
//-o-o-o-o-o-o-o-o-o-o-


//-----------------------------------------------------
//Name: UpdateTransformMatrix -  Not necessary???
//Description: Updates the transformation matrix with new values
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::UpdateTransformMatrix(int volume, vtkFloatingPointType t00, vtkFloatingPointType t01, vtkFloatingPointType t02, vtkFloatingPointType t03, vtkFloatingPointType t10, vtkFloatingPointType t11, vtkFloatingPointType t12, vtkFloatingPointType t13, vtkFloatingPointType t20, vtkFloatingPointType t21, vtkFloatingPointType t22, vtkFloatingPointType t23, vtkFloatingPointType t30, vtkFloatingPointType t31, vtkFloatingPointType t32, vtkFloatingPointType t33 )
{
  currentTransformation[volume][0][0] = t00;
  currentTransformation[volume][0][1] = t01;
  currentTransformation[volume][0][2] = t02;
  currentTransformation[volume][0][3] = t03;
  currentTransformation[volume][1][0] = t10;
  currentTransformation[volume][1][1] = t11;
  currentTransformation[volume][1][2] = t12;
  currentTransformation[volume][1][3] = t13;
  currentTransformation[volume][2][0] = t20;
  currentTransformation[volume][2][1] = t21;
  currentTransformation[volume][2][2] = t22;
  currentTransformation[volume][2][3] = t23;
  currentTransformation[volume][3][0] = t30;
  currentTransformation[volume][3][1] = t31;
  currentTransformation[volume][3][2] = t32;
  currentTransformation[volume][3][3] = t33;
  
  tMatrixChanged[volume] = 1;
}

//-----------------------------------------------------
//Name: UpdateTransformMatrix with vtkMatrix4x4 input
//Description: Updates the transformation matrix with new values
//--------------------------------------------------

void vtkVolumeTextureMapper3D::UpdateTransformMatrix(int volume, vtkMatrix4x4 *transMatrix )
{
  for(int i = 0; i < 4; i++)
  {
    for(int j = 0; j < 4; j++)
    {
      currentTransformation[volume][i][j] =(vtkFloatingPointType) transMatrix->GetElement(i, j);
    }
  }

  
  tMatrixChanged[volume] = 1;
}

//-----------------------------------------------------
//Name: IsTMatrixChanged
//Description: Check if the transformation matrix is changed
//-----------------------------------------------------
int vtkVolumeTextureMapper3D::IsTMatrixChanged(int volume)
{
  if (tMatrixChanged[volume] == 1)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

//-----------------------------------------------------
//Name: GetTransformMatrix
//Description: Get the current transformation matrix
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::GetTransformMatrix(vtkFloatingPointType transfMatrix[4][4], int volume)
{

  for (int i = 0; i < 4; i++)
  {
    for (int j = 0; j < 4; j++)
    {
      transfMatrix[i][j] = currentTransformation[volume][i][j];
    }
  }
  tMatrixChanged[volume] = 0;
}

//-----------------------------------------------------
//Name: SetTransformMatrixElement
//Description: Set an element in the transformation matrix
//-----------------------------------------------------
void vtkVolumeTextureMapper3D::SetTransformMatrixElement(int volume, int row, int column, vtkFloatingPointType value)
{
  currentTransformation[volume][row][column] = value;
  tMatrixChanged[volume] = 1;
}


//-----------------------------------------------------
//Name: GetTransformMatrixElement
//Description: Get the value of an element in the 
//transformation matrix
//-----------------------------------------------------
vtkFloatingPointType vtkVolumeTextureMapper3D::GetTransformMatrixElement(int volume, int row, int column)
{
  return currentTransformation[volume][row][column];
}


