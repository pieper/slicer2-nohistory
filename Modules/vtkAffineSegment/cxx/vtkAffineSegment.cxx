/*=auto=========================================================================

  Portions (c) Copyright 2005 Brigham and Women's Hospital (BWH) All Rights Reserved.

  See Doc/copyright/copyright.txt
  or http://www.slicer.org/copyright/copyright.txt for details.

  Program:   3D Slicer
  Module:    $RCSfile: vtkAffineSegment.cxx,v $
  Date:      $Date: 2006/01/06 17:57:12 $
  Version:   $Revision: 1.7 $

=========================================================================auto=*/
#ifdef _WIN32
#define _USE_MATH_DEFINES
#endif

#include <stdio.h>
#include <stdlib.h>

#include <math.h>

#if defined(__sun)
#include <ieeefp.h>
#endif

#include <algorithm>

#include "vtkObjectFactory.h"

#include "vtkAffineSegment.h"
#define DEBUG

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

// used to compute the median
int compareInt(const void *a, const void *b)
{
  return  (*(int*)a) - (*(int*)b);
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

vtkAffineSegment* vtkAffineSegment::New()
{
  // First try to create the object from the vtkObjectFactory
  vtkObject* ret = vtkObjectFactory::CreateInstance("vtkAffineSegment");
  if(ret)
    {
      return (vtkAffineSegment*)ret;
    }

  // If the factory was unable to create the object, then create it here.
  return new vtkAffineSegment;
}

// speed at index
float vtkAffineSegment::speed( int index )
{
  float s;
    
  s = 1;

  return s;
}


//Return the number of seeds currently
int vtkAffineSegment::nValidSeeds( void )
{
  if(somethingReallyWrong)
    return 0;

  return (int)(seedPoints.size());
}

/* Compute 3D Affine invariant stopping term phi_hat */
//given the image data, compute Affine Phi (Affine invariant Stopping term)
void vtkAffineSegment::ComputeAffine_phihat(short *inData)
{
  int idxZ,idxY,idxR;
  float lx,ly,lz,lxx,lxy,lxz,lyz,lyy,lzz;
  int offset_xf,xyz,frame_size;
  float H,J;

  for (idxZ = 0; idxZ < dimZ; idxZ++)
    {
      for (idxY = 0;idxY < dimY; idxY++)
    {
               
      frame_size = dimX*dimY;
      xyz = idxY*dimX+idxZ*frame_size;
      offset_xf = xyz+frame_size; //for offset in z-direction

      /* idxR + xyz gives our current position */

      for (idxR = 0; idxR < dimX; idxR++)
        {

          /* at the boundaries we need to do some special things
         so that we have access to the correct data or else we will crash
         as we will access data not present */
          if((idxR == 0) || (idxR == dimX-1) || (idxY == 0) || (idxY == dimY-1) || (idxZ == 0) || (idxZ == dimZ-1)) 
        {
          if(idxZ == 0)
            {
              lz = (1/(2*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz]);
              lzz = (1/(dz*dz)) * 2 * lz;

              if((idxR != 0) && (idxR != dimX -1))
            lxz = (1/(4*dx*dz)) * (inData[idxR+1+offset_xf] - inData[idxR+1+xyz] - inData[idxR-1+offset_xf]
                           + inData[idxR-1+xyz]);

              if(idxR == dimX -1 )
            lxz = (1/(4*dx*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz] - inData[idxR-1+offset_xf]
                                               + inData[idxR-1+xyz]);

              if(idxR == 0)
            lxz = (1/(4*dx*dz)) * (inData[idxR+1+offset_xf] - inData[idxR+1+xyz] - inData[idxR+offset_xf]
                           + inData[idxR+xyz]);

              if((idxY != 0) && (idxY != dimY -1))
            lyz = (1/(4*dy*dz)) * (inData[idxR+dimX+offset_xf] - inData[idxR+dimX+xyz] -
                           inData[idxR-dimX+offset_xf] + inData[idxR+xyz-dimX]);
              if(idxY == 0)
            lyz = (1/(4*dy*dz)) * (inData[idxR+dimX+offset_xf] - inData[idxR+dimX+xyz] -
                           inData[idxR+offset_xf] + inData[idxR+xyz]);
              if(idxY == dimY-1)
            lyz = (1/(4*dy*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz] -
                           inData[idxR-dimX+offset_xf] + inData[idxR+xyz-dimX]);


            }

          if(idxZ == dimZ-1)
            {

              lz = (1/(2*dz)) * (inData[idxR+xyz] - inData[idxR+xyz-frame_size]);
              lzz = (1/(dz*dz)) * 2 * lz;

              if((idxR != 0) && (idxR != dimX -1))
            lxz = (1/(4*dx*dz)) * (inData[idxR+1+xyz] - inData[idxR+xyz+1-frame_size] - inData[idxR-1+xyz]
                           + inData[idxR+xyz-1-frame_size]);
              if(idxR == 0)
            lxz = (1/(4*dx*dz)) * (inData[idxR+1+xyz] - inData[idxR+xyz+1-frame_size] - inData[idxR+xyz]
                           + inData[idxR+xyz-frame_size]);
              if(idxR == dimX-1)
            lxz = (1/(4*dx*dz)) * (inData[idxR+xyz] - inData[idxR+xyz-frame_size] - inData[idxR-1+xyz]
                           + inData[idxR+xyz-1-frame_size]);


              if((idxY != 0) && (idxY != dimY -1))
            lyz = (1/(4*dy*dz)) * (inData[idxR+dimX+xyz] - inData[idxR+xyz+dimX-frame_size] -
                           inData[idxR-dimX+xyz] + inData[idxR+xyz-dimX-frame_size]);
              if(idxY == 0)
            lyz = (1/(4*dy*dz)) * (inData[idxR+dimX+xyz] - inData[idxR+xyz+dimX-frame_size] -
                           inData[idxR+xyz] + inData[idxR+xyz-frame_size]);
              if(idxY == dimY-1)
            lyz = (1/(4*dy*dz)) * (inData[idxR+xyz] - inData[idxR+xyz-frame_size] -
                           inData[idxR-dimX+xyz] + inData[idxR+xyz-dimX-frame_size]);
                                
            } 


          if(idxR == 0)
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR+xyz]);
              lxx = (1/(dx*dx)) * (inData[(idxR+1)+xyz] - 2 * inData[idxR+xyz] + inData[idxR+xyz]);
              if(idxY == 0)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - 2*inData[idxR+xyz] + inData[idxR+xyz]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz+dimX] - inData[idxR+1+xyz] -
                         inData[idxR+xyz+dimX] + inData[idxR+xyz]);
            }
              else if(idxY == dimY-1)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR +xyz-dimX]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz] - 2*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz] - inData[idxR+1+xyz-dimX] -
                         inData[idxR+xyz] + inData[idxR+xyz-dimX]);
            }
              else
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz-dimX]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - 2*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz+dimX] - inData[idxR+1+xyz-dimX] -
                         inData[idxR+xyz+dimX] + inData[idxR+xyz-dimX]);
            }

            }

          if(idxR == dimX-1)
            {
              lx = (1/(2*dx)) * (inData[idxR+xyz] - inData[idxR-1+xyz]);
              lxx = (1/(dx*dx)) * (inData[idxR+xyz] - 2 * inData[idxR+xyz] + inData[idxR-1+xyz]);
              if(idxY == 0)
            { 
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - 2*inData[idxR+xyz] + inData[idxR+xyz]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz] -
                         inData[idxR-1+xyz+dimX] + inData[idxR-1+xyz]);
            }
              else if(idxY == dimY -1)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR +xyz-dimX]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz] - 2*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+xyz] - inData[idxR+xyz-dimX] -
                         inData[idxR-1+xyz] + inData[idxR-1+xyz-dimX]);
            }
              else
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz-dimX]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - 2*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz-dimX] -
                         inData[idxR-1+xyz+dimX] + inData[idxR-1+xyz-dimX]);
            }

            }

          if((idxY == 0) && (idxR != 0) && (idxR != dimX-1))
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz]);
              lxx = (1/(dx*dx)) * (inData[(idxR+1)+xyz] - 2 * inData[idxR+xyz] + inData[idxR-1+xyz]);
              lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz+dimX] - inData[idxR+1+xyz] -
                         inData[idxR-1+xyz+dimX] + inData[idxR-1+xyz]);
            }

          if((idxY == dimY-1) && (idxR != 0) && (idxR != dimX-1))
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR+xyz-dimX]);
              lxx = (1/(dx*dx)) * (inData[(idxR+1)+xyz] - 2 * inData[idxR+xyz] + inData[idxR-1+xyz]);
              lyy = (1/(dy*dy)) * (-1*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
              lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz] - inData[idxR+1+xyz-dimX] -
                         inData[idxR-1+xyz] + inData[idxR-1+xyz-dimX]);
            }
                            

          J = (((lyy*lzz-lyz*lyz)*lx*lx) + ((lxx*lzz-lxz*lxz)*ly*ly) + ((lxx*lyy-lxy*lxy)*lz*lz) +
               (2*lx*ly*(lxz*lyz-lxy*lzz)) + (2*ly*lz*(lxy*lxz-lyz*lxx)) +
               (2*lx*lz*(lxy*lyz-lxz*lyy)));
                            

          H = lxx*(lyy*lzz-lyz*lyz) - lxy*(lxy*lzz-lyz*lxz) + lxz*(lxy*lyz-lxz*lyy);


          phi_hat[idxR+xyz] = sqrt(H*H/(J*J + 1));
          eucl_phi[idxR+xyz] = 1.0/(1+lx*lx+ly*ly+lz*lz);
                            

          continue;
        } //end if (the BIG OR's)

          /*if not on any of the boundaries of the cube, compute
        as normal stuff */

          lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
          ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz-dimX]);
          lz = (1/(2*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz-frame_size]);

          lxx = (1/(dx*dx)) * (inData[(idxR+1)+xyz] - 2 * inData[idxR+xyz] + inData[idxR-1+xyz]);
          lyy = (1/(dy*dy)) * (inData[idxR+xyz+dimX] - 2*inData[idxR+xyz] + inData[idxR+xyz-dimX]);
          lzz = (1/(dz*dz)) * (inData[idxR+offset_xf] - 2*inData[idxR+xyz] + inData[idxR+xyz-frame_size]);


          lxy = (1/(4*dx*dy)) * (inData[idxR+1+xyz+dimX] - inData[idxR+1+xyz-dimX] -
                     inData[idxR-1+xyz+dimX] + inData[idxR-1+xyz-dimX]);
          lyz = (1/(4*dy*dz)) * (inData[idxR+dimX+offset_xf] - inData[idxR+dimX+xyz-frame_size] -
                     inData[idxR-dimX+offset_xf] + inData[idxR+xyz-dimX-frame_size]);
          lxz = (1/(4*dx*dz)) * (inData[idxR+1+offset_xf] - inData[idxR+1+xyz-frame_size] - inData[idxR-1+offset_xf]
                     + inData[idxR+xyz-1-frame_size]);

          J = (((lyy*lzz-lyz*lyz)*lx*lx) + ((lxx*lzz-lxz*lxz)*ly*ly) + ((lxx*lyy-lxy*lxy)*lz*lz) +
           (2*lx*ly*(lxz*lyz-lxy*lzz)) + (2*ly*lz*(lxy*lxz-lyz*lxx)) +
           (2*lx*lz*(lxy*lyz-lxz*lyy)));
                            

          H = lxx*(lyy*lzz-lyz*lyz) - lxy*(lxy*lzz-lyz*lxz) + lxz*(lxy*lyz-lxz*lyy);

          //our temporary storage of affine invariant gradient
          phi_hat[idxR+xyz] = (J*J+1)/(H*H+J*J+1);
                     
          //euclidean phi_hat
          eucl_phi[idxR+xyz] = 1.0/(1+lx*lx+ly*ly+lz*lz);

        } //end for(idxR < dimX)

    } //end for(idxY < dimY)



    } //end for(idxZ < dimZ)


  return;
}

/* compute the first derivatives of affine invariant term phi_hat */
// given the Affine invariant phi, compute its x,y,z derivatives
//this function is called only once when we do the expansion for the fist time

void vtkAffineSegment::Compute_phi_hat_xyz(float *inData)
{
  int idxZ,idxY,idxR;
  float lx,ly,lz;
  int offset_xf,xyz,frame_size;
 
 
  for (idxZ = 0; idxZ < dimZ; idxZ++)
    {
      for (idxY = 0;idxY < dimY; idxY++)
    {
               
      frame_size = dimX*dimY;
      xyz = idxY*dimX+idxZ*frame_size;
      offset_xf = xyz+frame_size; //for offset in z-direction

      /* idxR + xyz gives our current position */

      for (idxR = 0; idxR < dimX; idxR++)
        {

          /* at the boundaries we need to do some special things
         so that we have access to the correct data or else we will crash
         as we will access data not present */
          if((idxR == 0) || (idxR == dimX-1) || (idxY == 0) || (idxY == dimY-1) || (idxZ == 0) || (idxZ == dimZ-1)) 
        {
          if(idxZ == 0)
            lz = (1/(2*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz]);

          if(idxZ == dimZ-1)
            lz = (1/(2*dz)) * (inData[idxR+xyz] - inData[idxR+xyz-frame_size]);


          if(idxR == 0)
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR+xyz]);
                          
              if(idxY == 0)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz]);
            }
              else if(idxY == dimY-1)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR +xyz-dimX]);
            }
              else
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz-dimX]);
            }

            }

          if(idxR == dimX-1)
            {
              lx = (1/(2*dx)) * (inData[idxR+xyz] - inData[idxR-1+xyz]);
              if(idxY == 0)
            { 
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz]);
            }
              else if(idxY == dimY -1)
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR +xyz-dimX]);
            }
              else
            {
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR +xyz-dimX]);
            }

            }

          if((idxY == 0) && (idxR != 0) && (idxR != dimX-1))
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
              ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz]);
            }

          if((idxY == dimY-1) && (idxR != 0) && (idxR != dimX-1))
            {
              lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
              ly = (1/(2*dy)) * (inData[idxR+xyz] - inData[idxR+xyz-dimX]);
            }
                          
          phi_hat_x[idxR+xyz] = lx;
          phi_hat_y[idxR+xyz] = ly;
          phi_hat_z[idxR+xyz] = lz;
                            

          continue;
        } //end if (the BIG OR's)

          /*if not on any of the boundaries of the cube, compute
        as normal stuff */

          lx = (1/(2*dx)) * (inData[(idxR+1)+xyz] - inData[idxR-1+xyz]);
          ly = (1/(2*dy)) * (inData[idxR+xyz+dimX] - inData[idxR+xyz-dimX]);
          lz = (1/(2*dz)) * (inData[idxR+offset_xf] - inData[idxR+xyz-frame_size]);
                         
          phi_hat_x[idxR+xyz] = lx;
          phi_hat_y[idxR+xyz] = ly;
          phi_hat_z[idxR+xyz] = lz;

        } //end for(idxR < dimX)

    } //end for(idxY < dimY)



    } //end for(idxZ < dimZ)


  return;
}

//Allocate Space to the all arrays we will need
//called from init.
//called only once
void vtkAffineSegment::Allocate_Space()
{
  this->level_set = (float*) calloc(this->dimZ*this->dimY*this->dimX,sizeof(float));
  if(!(this->level_set))
    return;

  this->sdist = (float*) calloc(this->dimZ*this->dimY*this->dimX,sizeof(float));
  if(!(this->sdist))
    return;

  /* assign appropriate memory */
          
  this->phi_hat = new float[this->dimXYZ];
  if(!(this->phi_hat))
    return;

  this->eucl_phi = new float[this->dimXYZ];
  if(!(this->eucl_phi))
    return;

  this->phi_hat_x = new float[this->dimXYZ];
  if(!(this->phi_hat_x))
    return;

  this->phi_hat_y = new float[this->dimXYZ];
  if(!(this->phi_hat_y))
    return;

  this->phi_hat_z = new float[this->dimXYZ];
  if(!(this->phi_hat_z))
    return;

  this->temp_phi_ext_x = new float[this->dimXYZ];
  if(!(this->temp_phi_ext_x))
    return;

  this->temp_phi_ext_y = new float[this->dimXYZ];
  if(!(this->temp_phi_ext_y))
    return;

  this->temp_phi_ext_z = new float[this->dimXYZ];
  if(!(this->temp_phi_ext_z))
    return;

  this->temp_phi_ext = new float[this->dimXYZ];
  if(!(this->temp_phi_ext))
    return; 

  this->temp_eucl_phi = new float[this->dimXYZ];
  if(!(this->temp_eucl_phi))
    return;

  return;
}

//Release space once we are done
// this is called only once  when we do uninit
void vtkAffineSegment::Release_Space()
{

  if(!this->level_set)
    free(this->level_set);
  if(!this->sdist)
    free(this->sdist);
  if(!this->phi_hat)
    delete[] this->phi_hat;
  if(!this->eucl_phi)
    delete[] this->eucl_phi;
  if(!this->phi_hat_x)
    delete[] this->phi_hat_x;
  if(!this->phi_hat_y)
    delete[] this->phi_hat_y;
  if(!this->phi_hat_z)
    delete[] this->phi_hat_z;
  if(!this->temp_phi_ext)
    delete [] this->temp_phi_ext;
  if(!this->temp_eucl_phi)
    delete [] this->temp_eucl_phi;
  if(!this->temp_phi_ext_x)
    delete [] this->temp_phi_ext_x;
  if(!this->temp_phi_ext_y)
    delete [] this->temp_phi_ext_y;
  if(!this->temp_phi_ext_z)
    delete [] this->temp_phi_ext_z; 

  return;

}

//One of the main functions we call when we want to contract
// this is the basic Affine invariant 3D surface flow
// Here assumption is that the user has already created an
// initial surface using the "Expand" function call
// and now needs to smooth or reduce the surface area

// we assume that memory has already been allocated and all hte
// constant affine invariant terms have been calculated. the level
//sset also has been created during the "Exapnd" routine
//typically we come here when we have grown the surface engouh
//as a result, if the seedPoints are less than 20, we have nothing
//much to contract !
static void vtkAffineSegmentContract(vtkAffineSegment *self,
                     vtkImageData *inData, short *inPtr,
                     vtkImageData *outData, short *outPtr, 
                     int outExt[6], int id)
{
  
  double lx,ly,lxx,lyy,lxy,lzz,lz, lyz, lxz;
  double kapa4, kapa4_mean;
  float psi_hat_xm;
  float psi_hat_ym;
  float psi_hat_zm;
  float psi_hat_xp;
  float psi_hat_yp;
  float psi_hat_zp;

  unsigned long count = 1;

  int x;
  int dimX,dimY,dimZ,dimXY;
  double temp;
  VecFloat update_term;
  double t_max = 0.0;
  float psi_hat_x = 0.0;
  float psi_hat_y = 0.0;
  float psi_hat_z = 0.0;
  float eucl_grad = 0.0;
  float edge_val = 0.0;
  int curr_pos;
  int initial_interface_size = self->seedPoints.size();

  dimX = self->dimX;
  dimY = self->dimY;
  dimZ = self->dimZ;
  dimXY = self->dimXY;

  kapa4 = 0.0;
  vtkFloatingPointType dx,dy,dz;

  //if the interface has less than ten points, then there is really nothing to contract
  if(self->seedPoints.size()<20)
    return;

  dx = inData->GetSpacing()[0];
  dy = inData->GetSpacing()[1];
  dz = inData->GetSpacing()[2];
  if((dx <= 0) || (dy <= 0) || (dz <= 0))
    dx = dy = dz = 1.0;

  /*
    #ifdef DEBUG
    FILE *fp = 0;
    self->fpc = NULL;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\contract3d.txt","w+");
    if(fp == NULL)
    return;
    fprintf(fp,"dimX=%d,dimY=%d,dimZ=%d\n",dimX,dimY,dimZ);
    fprintf(fp,"scalar Type %s\n",inData->GetScalarTypeAsString());
    fprintf(fp,"seedPoint Size = %d\n",self->seedPoints.size());
    fflush(fp);
    
    #endif

  */
  //we assume that we have the seedPoints array filled with the
  // interface points.
  
  //speed of inflationary term
  int v = 50;

  int lastPercentageProgressBarUpdated=-1;

  //now start doing our iterations
  for(int iter = 0;!self->AbortExecute && iter < self->NumberOfContractions;iter++)
    {
      
      if(((iter%1)==0)||(iter==0))
    {
      count = -2*initial_interface_size;
      self->Compute_Extension(self);
      initial_interface_size = self->zero_set.size();
      count += self->knownPoints.size();
      //fprintf(fp,"finished computing Extension# %d, seedPoints = %d,count=%d\n",iter,self->seedPoints.size(),count);
      //fflush(fp);
    }
      


      //if no known points, dont do anything
      if(self->knownPoints.size()<1)
    continue;

      //modify our data based on this  time-step
      //initialize data
      t_max=0.0;
      psi_hat_x = 0.0;
      psi_hat_y = 0.0;
      psi_hat_z = 0.0;
      eucl_grad = 0.0;

      for(x=0;x<(int)count;x++)
    {
      curr_pos = self->knownPoints[x];
      // update progress bar
      int currentPercentage = GRANULARITY_PROGRESS*iter*x / (count*self->NumberOfContractions);
        
      if( currentPercentage > lastPercentageProgressBarUpdated )
        {
          lastPercentageProgressBarUpdated = currentPercentage;
          self->UpdateProgress(float(currentPercentage)/float(GRANULARITY_PROGRESS));
        }


      //calculate the second term (inflation term) using the Upwind differencing scheme        
      psi_hat_xm = 0.0;
      psi_hat_ym = 0.0;
      psi_hat_zm = 0.0;
      psi_hat_xp = 0.0;
      psi_hat_yp = 0.0;
      psi_hat_zp = 0.0;
     
      psi_hat_xm = self->level_set[curr_pos] - self->level_set[curr_pos-1];
      psi_hat_xp = self->level_set[curr_pos+1] - self->level_set[curr_pos]; 
      psi_hat_ym = self->level_set[curr_pos] - self->level_set[curr_pos-1*dimX];
      psi_hat_yp = self->level_set[curr_pos+1*dimX] - self->level_set[curr_pos];
      psi_hat_zm = self->level_set[curr_pos] - self->level_set[curr_pos-1*dimXY];
      psi_hat_zp = self->level_set[curr_pos+1*dimXY] - self->level_set[curr_pos];
      //do upwind differencing scheme for calculating second term
      if(self->phi_ext_x[x] < 0)
        psi_hat_x = psi_hat_xm;
      else
        psi_hat_x = psi_hat_xp;

      if(self->phi_ext_y[x] < 0)
        psi_hat_y = psi_hat_ym;
      else
        psi_hat_y = psi_hat_yp;

      if(self->phi_ext_z[x] < 0)
        psi_hat_z = psi_hat_zm;
      else
        psi_hat_z = psi_hat_zp;

      if(self->eucl_ext[x] >= 0)
        eucl_grad = sqrt(pow((double)min(psi_hat_xm,0),2.0) + pow((double)max(psi_hat_xp,0),2.0) + pow((double)min(psi_hat_ym,0),2.0) +
                 pow((double)max(psi_hat_yp,0),2.0) + pow((double)min(psi_hat_zm,0),2.0) + pow((double)max(psi_hat_zp,0),2.0));
      else
        eucl_grad = sqrt(pow((double)max(psi_hat_xm,0),2.0) + pow((double)min(psi_hat_xp,0),2.0) + pow((double)max(psi_hat_ym,0),2.0) +
                 pow((double)min(psi_hat_yp,0),2.0) + pow((double)max(psi_hat_zm,0),2.0) + pow((double)min(psi_hat_zp,0),2.0));


      //now lets calculate the (sign(H) x kappa) -- term
      lx = (1/(2*dx)) * (self->level_set[curr_pos+1] - self->level_set[curr_pos-1]);
      ly = (1/(2*dy)) * (self->level_set[curr_pos+dimX] - self->level_set[curr_pos-dimX]);
      lz = (1/(2*dz)) * (self->level_set[curr_pos+dimXY] - self->level_set[curr_pos-dimXY]);

      lxx = (1/(dx*dx)) * (self->level_set[curr_pos+1] - 2 * self->level_set[curr_pos] + self->level_set[curr_pos-1]);
      lyy = (1/(dy*dy)) * (self->level_set[curr_pos+dimX] - 2*self->level_set[curr_pos] + self->level_set[curr_pos-dimX]);
      lzz = (1/(dz*dz)) * (self->level_set[curr_pos+dimXY] - 2*self->level_set[curr_pos] + self->level_set[curr_pos-dimXY]);


      lxy = (1/(4*dx*dy)) * (self->level_set[curr_pos+1+dimX] - self->level_set[curr_pos+1-dimX] -
                 self->level_set[curr_pos-1+dimX] + self->level_set[curr_pos-1-dimX]);
      lyz = (1/(4*dy*dz)) * (self->level_set[curr_pos+dimX+dimXY] - self->level_set[curr_pos+dimX-dimXY] -
                 self->level_set[curr_pos-dimX+dimXY] + self->level_set[curr_pos-dimX-dimXY]);
      lxz = (1/(4*dx*dz)) * (self->level_set[curr_pos+1+dimXY] - self->level_set[curr_pos+1-dimXY] - self->level_set[curr_pos-1+dimXY]
                 + self->level_set[curr_pos-1-dimXY]);

      // this is gaussian curvature                      
      kapa4 = (((lyy*lzz-lyz*lyz)*lx*lx) + ((lxx*lzz-lxz*lxz)*ly*ly) + ((lxx*lyy-lxy*lxy)*lz*lz) +
           (2*lx*ly*(lxz*lyz-lxy*lzz)) + (2*ly*lz*(lxy*lxz-lyz*lxx)) +
           (2*lx*lz*(lxy*lyz-lxz*lyy))); 

      //calculate mean curvature so that we can use its sign
      kapa4_mean = ((lx*lx*(lyy+lzz)) + (ly * ly *(lzz+lxx)) + (lz*lz*(lxx+lyy)) -
            (2*lx*ly*lxy) - (2*ly*lz*lyz) - (2*lx*lz*lxz));

      if(kapa4 < 0)
        kapa4=0.0;
      else
        kapa4 = pow(kapa4,0.25); 
                

      /* use the sign of mean curvature. Without using this, the algorithm is highly
         unstable and basically blows up. Using the sign of H instead of K gives the right
         smoothing effect. */
      if(kapa4_mean < 0)
        kapa4 = -kapa4;

      //gradient
      edge_val = sqrt(lx*lx+ly*ly+lz*lz);

      if(edge_val != 0)
        temp = (self->phi_ext[x] * kapa4) + (self->phi_ext_x[x] * psi_hat_x + self->phi_ext_y[x] * psi_hat_y +
                         self->phi_ext_z[x] * psi_hat_z) * (kapa4/edge_val) + v * eucl_grad * self->eucl_ext[x]; 
      else
        temp = (self->phi_ext[x] * kapa4) + (self->phi_ext_x[x] * psi_hat_x + self->phi_ext_y[x] * psi_hat_y +
                         self->phi_ext_z[x] * psi_hat_z) * (kapa4/0.01) +  v * eucl_grad * self->eucl_ext[x]; 

                
      if(fabs(temp)>t_max)
        t_max = fabs(temp);

      update_term.push_back(temp);


    } //finished calculating the update term

      self->dt = 0.5 / t_max;

      //update our level set
      for(x=0;x<(int)update_term.size();x++)
    {
      curr_pos = self->knownPoints[x];
      self->level_set[curr_pos] = self->level_set[curr_pos] + self->dt * update_term[x];
    }
      //fprintf(fp,"dt = %f, t_max = %f\n",self->dt,t_max);
      update_term.clear();
            
            
            

    } //end for(iterations )

  /*
    #ifdef DEBUG
    if(!fp)
    fclose(fp);
    #endif
  */

  return;
}

//This is the funciton called when the user says "Expand"
// here we are merely doing Inflation = speed * phi * gradient
// this is called so that we create an initial surface from 
// a bunch of fiducial points. Since this is very wiggly,
// we do smoothing using the "Contract" function
// this function can be called a number of times and hence we have
// the flag: "already_computed", so that we compute certain terms
// only once.
//The user should typically call this function first

static void vtkAffineSegmentInflation(vtkAffineSegment *self,
                      vtkImageData *inData, short *inPtr,
                      vtkImageData *outData, short *outPtr, 
                      int outExt[6], int id)
{
  
  
  float psi_hat_xm;
  float psi_hat_ym;
  float psi_hat_zm;
  float psi_hat_xp;
  float psi_hat_yp;
  float psi_hat_zp;

  unsigned long count = 1;

  int x;
  int dimX,dimY,dimZ,dimXY;
  double temp;
  VecFloat update_term;
  double t_max = 0.0;
  float psi_hat_x = 0.0;
  float psi_hat_y = 0.0;
  float psi_hat_z = 0.0;
  float eucl_grad = 0.0;
  float edge_val = 0.0;
  int curr_pos;

  dimX = self->dimX;
  dimY = self->dimY;
  dimZ = self->dimZ;
  dimXY = self->dimXY;

  if(self->seedPoints.size()<1)
    return;
  /*
    #ifdef DEBUG
    FILE *fp = 0;
    self->fpc = NULL;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\out3d.txt","w+");
    if(fp == NULL)
    return;
    self->fpc = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\compute_T.txt","w+");
    if(self->fpc == NULL)
    return;
    fprintf(fp,"dimX=%d,dimY=%d,dimZ=%d\n",dimX,dimY,dimZ);
    fprintf(fp,"scalar Type %s\n",inData->GetScalarTypeAsString());
    fprintf(fp,"seedPoint Size = %d\n",self->seedPoints.size());
    fprintf(fp,"IntialSize = %d\n",self->InitialSize);
    fflush(fp);
    
    #endif
  */

  //# of points to update in the level_set
  int initial_size = self->seedPoints.size();

  //if we are coming for the first time, compute everything or else we have already computed these
  if(!self->already_computed)
    {
      //generate our initial ellipsoid which will act as our starting level set
      //we use the fiducials that the user created to generate an ellipsoid around them

      self->Calculate_SignedDistance(self,self->InitialSize,false);
      self->FindInitialBoundary();

      //compute affine invariant phi_hat. 
      self->ComputeAffine_phihat(inPtr);

      //compute phi_hat_x,y,z
      self->Compute_phi_hat_xyz(self->phi_hat);

      //first compute the signed distance function which is stored in "level_set"
      //this acts as our level set with negative inside and positive outside
      self->Calculate_SignedDistance(self,300000,true);
      self->already_computed = true;
    }
  
  //get the inflationary term selected by the user
  int v = self->Inflation;

  //for progress bar
  int lastPercentageProgressBarUpdated=-1;

  //now start doing our iterations
  for(int iter = 0;!self->AbortExecute && iter < self->NumberOfIterations;iter++)
    {
      //compute extension every 10th time. We assume that there is not going to be much
      //change in the values of extensions since we dont move that much in every iteraiton
      // however the number 10 is arbitary and we should find a way to fix this
      // or not compute any extension at all and do narrow banding, which requires re-initialization
      //of level set array

      if(((iter%10)==0)||(iter==0))
    {
      count = -1*initial_size;
      self->Compute_Extension(self);
      count += self->knownPoints.size();
      //fprintf(fp,"finished computing Extension# %d, seedPoints = %d,count=%d\n",iter,self->seedPoints.size(),count);
      //fflush(fp);
    }
      


      //if no known points, dont do anything
      if(self->knownPoints.size()<1)
    continue;

      //modify our data based on this  time-step
      //initialize data
      t_max=0.0;
      psi_hat_x = 0.0;
      psi_hat_y = 0.0;
      psi_hat_z = 0.0;
      eucl_grad = 0.0;

      for(x=0;x<(int)count;x++)
    {
      curr_pos = self->knownPoints[x];
      // update progress bar
      int currentPercentage = GRANULARITY_PROGRESS*iter*x / (count*self->NumberOfIterations);
        
      if( currentPercentage > lastPercentageProgressBarUpdated )
        {
          lastPercentageProgressBarUpdated = currentPercentage;
          self->UpdateProgress(float(currentPercentage)/float(GRANULARITY_PROGRESS));
        }


      //calculate the second term using the Upwind differencing scheme        
      psi_hat_xm = 0.0;
      psi_hat_ym = 0.0;
      psi_hat_zm = 0.0;
      psi_hat_xp = 0.0;
      psi_hat_yp = 0.0;
      psi_hat_zp = 0.0;
     
      psi_hat_xm = self->level_set[curr_pos] - self->level_set[curr_pos-1];
      psi_hat_xp = self->level_set[curr_pos+1] - self->level_set[curr_pos]; 
      psi_hat_ym = self->level_set[curr_pos] - self->level_set[curr_pos-1*dimX];
      psi_hat_yp = self->level_set[curr_pos+1*dimX] - self->level_set[curr_pos];
      psi_hat_zm = self->level_set[curr_pos] - self->level_set[curr_pos-1*dimXY];
      psi_hat_zp = self->level_set[curr_pos+1*dimXY] - self->level_set[curr_pos];
      //do upwind differencing scheme for calculating second term
      if(self->phi_ext_x[x] < 0)
        psi_hat_x = psi_hat_xm;
      else
        psi_hat_x = psi_hat_xp;

      if(self->phi_ext_y[x] < 0)
        psi_hat_y = psi_hat_ym;
      else
        psi_hat_y = psi_hat_yp;

      if(self->phi_ext_z[x] < 0)
        psi_hat_z = psi_hat_zm;
      else
        psi_hat_z = psi_hat_zp;

      if(self->eucl_ext[x] <= 0)
        eucl_grad = sqrt(pow((double)min(psi_hat_xm,0),2.0) + pow((double)max(psi_hat_xp,0),2.0) + pow((double)min(psi_hat_ym,0),2.0) +
                 pow((double)max(psi_hat_yp,0),2.0) + pow((double)min(psi_hat_zm,0),2.0) + pow((double)max(psi_hat_zp,0),2.0));
      else
        eucl_grad = sqrt(pow((double)max(psi_hat_xm,0),2.0) + pow((double)min(psi_hat_xp,0),2.0) + pow((double)max(psi_hat_ym,0),2.0) +
                 pow((double)min(psi_hat_yp,0),2.0) + pow((double)max(psi_hat_zm,0),2.0) + pow((double)min(psi_hat_zp,0),2.0));

      temp = v * eucl_grad * self->eucl_ext[x];

                
      if(fabs(temp)>t_max)
        t_max = fabs(temp);

      update_term.push_back(temp);


    } //finished calculating the update term

      self->dt = 0.5 / t_max;

      for(x=0;x<(int)update_term.size();x++)
    {
      curr_pos = self->knownPoints[x];
      self->level_set[curr_pos] = self->level_set[curr_pos] - self->dt * update_term[x];
    }
      //fprintf(fp,"dt = %f, t_max = %f\n",self->dt,t_max);
      update_term.clear();
            
            
            

    } //end for(iterations )

  /*
    #ifdef DEBUG
    if(!fp)
    fclose(fp);
    if(!self->fpc)
    fclose(self->fpc);
    #endif
  */
    
  return;

}

//This function calculates the initial surface (sphere) from fiducials and
//is also used to compute the initial signed distance function which is stored
//in level set array. When make_negative flag is "on", it means we are
//creating the signed distance function
//evolve_upto gives the number points upto which we want to evolve
// this function assumes that there is data present the  seedPoints array
// it evolves from these set of points

void vtkAffineSegment::Calculate_SignedDistance(vtkAffineSegment *self,int evolve_upto,bool make_negative)
{
  //assume that seedPoints contains some initial data

  /*
    #ifdef DEBUG
    FILE *fp = 0;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\signed_dist.txt","w+");
    fprintf(fp,"SeedPoint size = %d, index=%d\n",self->seedPoints.size(),seedPoints[0]);
    if(self->seedPoints.size()<1)
    return;
    if(fp == NULL)
    return;
    #endif
  */

  //clear and initialize everything
  int index=0;
  int k,n,i,j;
  int indx = 0;
  knownPoints.clear();
  tree.clear();
  zero_set.clear();

  for(k=0;k<dimZ;k++)
    {
      for(j=0;j<dimY;j++)
        for(i=0;i<dimX;i++)
      {

            node[index].T=(float)INF;
            node[index].status=fmsFAR;
            level_set[index] = 0.00;
            sdist[index] = 0.0;
            temp_phi_ext[index] = 0.0;
            temp_phi_ext_x[index] = 0.0;
            temp_phi_ext_y[index] = 0.0;
            temp_phi_ext_z[index] = 0.0;
            temp_eucl_phi[index]=0.0;

        if( (i<BAND_OUT) || (j<BAND_OUT) ||  (k<BAND_OUT) ||
                (i>=(dimX-BAND_OUT)) || (j>=(dimY-BAND_OUT)) || (k>=(dimZ-BAND_OUT)) )
          {
        node[index].status=fmsOUT;
          }
            index++;
              
      }
    }
    

  //make the fiducial very very small, but not zero so that later on
  //we dont think it is the boundary of the interface
  if(!make_negative)
    level_set[self->seedPoints[0]] = 0.000001;

  //the seedPoints r the zero level set pts, so they are known.
  //here we already know the extension vals. so put them in temps
  //these are useful in "computeT" func
  while(self->seedPoints.size()>0)
    {
      index=self->seedPoints[self->seedPoints.size()-1];
      self->seedPoints.pop_back();
      knownPoints.push_back(index);
      node[index].T=sdist[index];
      node[index].status=fmsKNOWN;
      temp_phi_ext[index] = phi_hat[index];
      temp_phi_ext_x[index] = phi_hat_x[index];
      temp_phi_ext_y[index] = phi_hat_y[index];
      temp_phi_ext_z[index] = phi_hat_z[index];
      temp_eucl_phi[index] = eucl_phi[index];
      //zero_set.push_back(index);
    }

  // if the points  have a KNOWN neighbor, put them  in TRIAL
  for(k=0;k<(int)self->knownPoints.size();k++)
    {
      int index = self->knownPoints[k];
      int indexN;
      bool hasKnownNeighbor =  false;
      for(n=1;n<=self->nNeighbors;n++)
    {
      indexN=index+self->shiftNeighbor(n);
      if((node[indexN].status==fmsKNOWN ) || (node[indexN].status == fmsTRIAL))
        hasKnownNeighbor=true;
      //if this neighbour is already known or trial, then dont put again
      if(!(hasKnownNeighbor))
        {
          FMleaf f;
          self->node[indexN].T=self->computeT(indexN);
          self->node[indexN].status=fmsTRIAL;     
          f.nodeIndex=indexN;
          self->insert( f );
        }
      hasKnownNeighbor =  false;
    }
    }
    
  //fprintf(fp,"Now Evolve, tree size = %d\n",tree.size());
 

  for(n=0;n<(int)evolve_upto;n++)
    {
        
      //should calculate extension and store it
      float T=self->step(&indx);
      level_set[indx] = T;
    
      if(!make_negative)
    inside_sphere.push_back(indx);
      //zero_set.push_back(indx);

      if( T==INF )
    { 
      self->vtkErrorWrapper( "AffineSegment: nowhere else to go. End of evolution." );
      break;
    } 
    }


  self->minHeapIsSorted();
  //fprintf(fp,"Now Evolve, sphere_size = %d\n",inside_sphere.size());

  if(make_negative)
    MakeNegative_Inside();
  /*
    if(!fp)
    fclose(fp);

  */
  return;
}

/* makes the initial level set to have negative distance vals
   inside 
   we keep the indices that are supposed to be negative in the array "inside_sphere"
*/
void vtkAffineSegment::MakeNegative_Inside()
{
  int i;
  int curr_pos;
  for(i=0;i<(int)inside_sphere.size();i++)
    {
      curr_pos = inside_sphere[i];
      level_set[curr_pos] = -level_set[curr_pos];
    }
  inside_sphere.clear();

  return;
}
//----------------------------------------------------------------------------
//This is used to find the boundary for the very first time when we create the
//small spheres. Used only once

void vtkAffineSegment::FindInitialBoundary()
{
    

  int k;
  long curr_pos;
  /*
    #ifdef DEBUG
    FILE *fp = 0;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\init_bdry.txt","w+");
    if(fp == NULL)
    return;
    #endif
  */
  curr_pos=0;


  //clear the seedpoints array
  this->seedPoints.clear();
  for(k=0;k<dimXYZ;k++)
    {
        
      if((curr_pos+dimXY < dimXYZ) && (curr_pos-dimXY>=0))
        if(((level_set[curr_pos]==0) && (level_set[curr_pos+1]>0)) || 
       ((level_set[curr_pos]==0) && (level_set[curr_pos+dimX]>0)) ||
       ((level_set[curr_pos]==0) && (level_set[curr_pos+1*dimXY]>0)) ||
       ((level_set[curr_pos]==0) && (level_set[curr_pos-1]>0)) ||
       ((level_set[curr_pos]==0) && (level_set[curr_pos-dimX]>0)) ||
       ((level_set[curr_pos]==0) && (level_set[curr_pos-1*dimXY]>0)))
      {
            seedPoints.push_back(curr_pos); 
            //zero_set.push_back(curr_pos);
      }

        
      curr_pos++;
        
    }
  /*
    #ifdef DEBUG
    if(!fp)
    fclose(fp);
    #endif
  */


  return;
}

// this is one of the most widely used function
//it computes the extension velocities using Eric's fast marching
//algo. It assumes that the level set (signed distance) is already there
//it finds the interface and then computes extension velocities for
//upto 6 * interface size (points). this has been arbitrarily chosen
//This function is similar to "Signed Distance funciton" but has
//some things that are different
void vtkAffineSegment::Compute_Extension(vtkAffineSegment *self)
{
  if(self->somethingReallyWrong)
    return;
 
  int n=0;
  int k,j,i;
  int indx,index;

  //clear everything before we start
  self->knownPoints.clear();
  self->phi_ext.clear();
  self->phi_ext_x.clear();
  self->phi_ext_y.clear();
  self->phi_ext_z.clear();
  self->seedPoints.clear();
  self->tree.clear();
  self->zero_set.clear();
  self->eucl_ext.clear();
  /*
    #ifdef DEBUG
    FILE *fp = 0;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\compute_ext.txt","w+");
    fprintf(fp,"SeedPoint size = %d\n",self->seedPoints.size());
    if(fp == NULL)
    return;
    #endif
  */  
  self->initialized = true;
  index = 0;
 

  for(k=0;k<dimZ;k++)
    {
      for(j=0;j<dimY;j++)
        for(i=0;i<dimX;i++)
      {

            node[index].T=(float)INF;
            node[index].status=fmsFAR;
          
        if( (i<BAND_OUT) || (j<BAND_OUT) ||  (k<BAND_OUT) ||
                (i>=(dimX-BAND_OUT)) || (j>=(dimY-BAND_OUT)) || (k>=(dimZ-BAND_OUT)) )
          {
        node[index].status=fmsOUT;
          }
            index++;
              
      }
    }


  // for all seed points, set the current distance from zero level set
  // initialize the signed distance function for calculating extensions

  Initialize_sdist(false);
      
  /*
    #ifdef DEBUG
    fprintf(fp,"Reached after sdist\n");
    fprintf(fp,"after sdist seedpoint size = %d, known Points = %d\n",self->seedPoints.size(),self->knownPoints.size());
    fprintf(fp,"tree size = %d\n",tree.size());
    fflush(fp);
    #endif
  */

  while(self->seedPoints.size()>0)
    {
      index=self->seedPoints[self->seedPoints.size()-1];
      self->seedPoints.pop_back();
      knownPoints.push_back(index);
      zero_set.push_back(index);
      node[index].T=sdist[index];
      node[index].status=fmsKNOWN;
      //assign the corresponding extension values
      phi_ext.push_back(temp_phi_ext[index]);
      phi_ext_x.push_back(temp_phi_ext_x[index]);
      phi_ext_y.push_back(temp_phi_ext_y[index]);
      phi_ext_z.push_back(temp_phi_ext_z[index]);
      eucl_ext.push_back(temp_eucl_phi[index]);
    }

  // if the points  have a KNOWN neighbor, put them  in TRIAL
  for(k=0;k<(int)self->knownPoints.size();k++)
    {
      int index = self->knownPoints[k];
      int indexN;
      bool hasKnownNeighbor =  false;
      for(n=1;n<=self->nNeighbors;n++)
    {
      indexN=index+self->shiftNeighbor(n);
      if((node[indexN].status==fmsKNOWN )|| (node[indexN].status == fmsTRIAL)) 
        hasKnownNeighbor=true;

      if(!(hasKnownNeighbor))
        {
          FMleaf f;
          //fprintf(fp,"Status= %d, index=%d\n",node[indexN].status,indexN);
          self->node[indexN].T=self->computeT(indexN);        
          f.nodeIndex=indexN;
          self->insert( f );
          self->node[indexN].status=fmsTRIAL;
        }
      hasKnownNeighbor =  false;
    }
    }

  //arbitarily chosen
  self->nPointsEvolution = 15*knownPoints.size();

  for(n=0;n<self->nPointsEvolution;n++)
    {
            
      //should calculate extension and store it
      float T=self->step(&indx);
      //zero_set.push_back(indx);

      if( T==INF )
    { 
      self->vtkErrorWrapper( "AffineSegment: nowhere else to go. End of evolution." );
      break;
    } 
    }

  /*
    #ifdef DEBUG
    fprintf(fp,"finished computing extension, nPoints= %d\n",self->nPointsEvolution);
    fflush(fp);
    #endif
  */
  // check minHeap still OK
  self->minHeapIsSorted();

  self->firstPassThroughShow = true;

  //now we have created the extensions
  // extensions are in phi_hat, phi_hat_x, phi_hat_y, phi_hat_z

  /*
    #ifdef DEBUG
    if(!fp)
    fclose(fp);
    #endif
  */
  return;

}


/* this function finds the zero level set and initializes the signed distance function
   and phi_hat for doing Fast Marching */

void vtkAffineSegment::Initialize_sdist(bool isnegative)
{
  int k;
  float dist_to_zero;
  float dl,dr;
  float tmp;
  long curr_pos;
  float phi_extension,phi_extension_x,phi_extension_y,phi_extension_z;
  float eucl_phi_ext;
  /*
    #ifdef DEBUG
    FILE *fp = 0;
    fp = NULL;
    fp = fopen("c:\\cygwin\\slicer2\\Modules\\vtkAffineSegment\\init_sdist.txt","w+");
    fprintf(fp,"dimX=%d,dimY=%d,dimZ=%d,dimXY=%d,dimXYZ=%d\n",dimX,dimY,dimZ,dimXY,dimXYZ);
    if(fp == NULL)
    return;
    #endif
  */
  curr_pos=0;


  //clear the seedpoints array
  this->seedPoints.clear();
  for(k=0;k<dimXYZ;k++,curr_pos++)
    {
      //keep the indices which have negative vals, could be useful in
      //re-initialization of level set
      if(isnegative)
    if(level_set[curr_pos] < 0)
      inside_sphere.push_back(curr_pos);

      //initially the array is empty
      sdist[curr_pos] = 0;
      temp_phi_ext[curr_pos] = 0;
      temp_phi_ext_x[curr_pos] = 0;
      temp_phi_ext_y[curr_pos] = 0;
      temp_phi_ext_z[curr_pos] = 0;
      temp_eucl_phi[curr_pos] = 0;

      dl = fabs(level_set[curr_pos]);
      dist_to_zero = 100;

      if(curr_pos+1 < dimXYZ)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos+1]<0))
      {
        dr = fabs(level_set[curr_pos+1]);
        //fprintf(fp,"dl = %f, +1 = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos+1],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos+1]) + phi_hat[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos+1]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos+1]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos+1]) + phi_hat_z[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos+1]) + eucl_phi[curr_pos];
          }
      }
      if(curr_pos-1 >= 0)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos-1]<0))
      {
        dr = fabs(level_set[curr_pos-1]);
        //fprintf(fp,"dl = %f, -1 = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos-1],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos-1]) + phi_hat[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos-1]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos-1]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos-1]) + phi_hat_z[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos-1]) + eucl_phi[curr_pos];
          }
      }

      //make sure we dont overstep into next frame or out of bound
      if(curr_pos+dimX < dimXYZ)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos+dimX]<0))
      {
        dr = fabs(level_set[curr_pos+dimX]);
        //fprintf(fp,"dl = %f, +dimX = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos+dimX],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos+1*dimX]) + phi_hat[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos+1*dimX]) + eucl_phi[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos+dimX]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos+dimX]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos+dimX]) + phi_hat_z[curr_pos];
          }
      }
      if(curr_pos-dimX >= 0)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos-1*dimX]<0)) 
      {
        dr = fabs(level_set[curr_pos-1*dimX]);
        //fprintf(fp,"dl = %f, -dimX = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos-dimX],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos-1*dimX]) + phi_hat[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos-1*dimX]) + eucl_phi[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos-1*dimX]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos-1*dimX]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos-1*dimX]) + phi_hat_z[curr_pos];
          }
      }
      if(curr_pos-dimXY>=0)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos-1*dimXY]<0))
      {
        dr = fabs(level_set[curr_pos-1*dimXY]);
        //fprintf(fp,"dl = %f, -dimXY = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos-dimXY],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos-1*dimXY]) + phi_hat[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos-1*dimXY]) + eucl_phi[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos-1*dimXY]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos-1*dimXY]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos-1*dimXY]) + phi_hat_z[curr_pos];
          }
      }
 
      if(curr_pos+dimXY<dimXYZ)
    if((level_set[curr_pos]>=0) && (level_set[curr_pos+1*dimXY]<0))
      {
        dr = fabs(level_set[curr_pos+1*dimXY]);
        //fprintf(fp,"dl = %f, +dimXY = %f, curr_pos = %d\n",level_set[curr_pos],level_set[curr_pos+dimXY],curr_pos);
        tmp = dl/(dl+dr);
        if(tmp < dist_to_zero)
          {
        dist_to_zero = tmp;
        phi_extension = -dist_to_zero * (phi_hat[curr_pos] - phi_hat[curr_pos+1*dimXY]) + phi_hat[curr_pos];
        eucl_phi_ext = -dist_to_zero * (eucl_phi[curr_pos] - eucl_phi[curr_pos+1*dimXY]) + eucl_phi[curr_pos];
        phi_extension_x = -dist_to_zero * (phi_hat_x[curr_pos] - phi_hat_x[curr_pos+dimXY]) + phi_hat_x[curr_pos];
        phi_extension_y = -dist_to_zero * (phi_hat_y[curr_pos] - phi_hat_y[curr_pos+dimXY]) + phi_hat_y[curr_pos];
        phi_extension_z = -dist_to_zero * (phi_hat_z[curr_pos] - phi_hat_z[curr_pos+dimXY]) + phi_hat_z[curr_pos];
          }
      }

      /* if we found the interface, then put that value into our array 
     to initialize it for doing Fast Marching */

      if(dist_to_zero != 100) {
    sdist[curr_pos] = dist_to_zero;
    //fprintf(fp,"dist = %f,dl = %f, dr = %f\n",dist_to_zero,dl,dr);
    temp_phi_ext[curr_pos] = phi_extension;
    temp_phi_ext_x[curr_pos] = phi_extension_x;
    temp_phi_ext_y[curr_pos] = phi_extension_y;
    temp_phi_ext_z[curr_pos] = phi_extension_z;
    temp_eucl_phi[curr_pos] = eucl_phi_ext;
    seedPoints.push_back(curr_pos); 
      }

                
    }

  /*
    #ifdef DEBUG
    if(!fp)
    fclose(fp);
    #endif
  */
  return;
}

//This function puts the chosen label val to output
// here we show the current postion of level_set
//interface points are stored in "zero_set"
void vtkAffineSegment::show()
{
  if(somethingReallyWrong)
    return;

  vtkImageData *outData = this->GetOutput();
  short *outPtr = (short *) outData->GetScalarPointer();

  if( nEvolutions<0 )
    return;

  if(zero_set.size()<1 )
    return;
  
  seedPoints.clear();
  for(int i =0;i<(int)zero_set.size();i++)
    {
      outPtr[zero_set[i]] = label;
      //store the interface, we may require it later on
      seedPoints.push_back(zero_set[i]);
    }

  
  return;

}

void vtkAffineSegment::setActiveLabel(int label)
{
  this->label=label;
}

//----------------------------------------------------------------------------
// Description:
// This method is passed a input and output data, and executes the filter
// algorithm to fill the output from the input.
// It just executes a switch statement to call the correct function for
// the datas data types.
void vtkAffineSegment::ThreadedExecute(vtkImageData *inData, 
                       vtkImageData *outData,
                       int outExt[6], int id)
{

  outData->SetExtent(this->GetOutput()->GetWholeExtent());
  outData->AllocateScalars();

  int  s;
  outData->GetWholeExtent(outExt);
  void *inPtr = inData->GetScalarPointerForExtent(outExt);
  void *outPtr = outData->GetScalarPointerForExtent(outExt);

  int x1;

  x1 = GetInput()->GetNumberOfScalarComponents();
  if (x1 != 1) 
    {
      vtkErrorMacro(<<"Input has "<<x1<<" instead of 1 scalar component.");
      somethingReallyWrong = true;
      return;
    }
  
  /* Need short data */
  s = inData->GetScalarType();
  if (s != VTK_SHORT) 
    {
      vtkErrorMacro("Input scalars are type "<< s 
            << " instead of "<< VTK_SHORT);
      somethingReallyWrong = true;
      return;
    }

  //depending on whether we called Expand or Contract
  if(Evolve == 1)
    if(!Contract)
      vtkAffineSegmentInflation(this, inData, (short *)inPtr, 
                outData, (short *)(outPtr), outExt,0); 
    else
      {
    vtkAffineSegmentContract(this, inData, (short *)inPtr, 
                 outData, (short *)(outPtr), outExt,0); 
    Contract = false;
      }
  

}

void vtkAffineSegment::setNPointsEvolution( int n )
{
  nPointsEvolution=n;
}

void vtkAffineSegment::PrintSelf(ostream& os, vtkIndent indent)
{
  vtkImageToImageFilter::PrintSelf(os,indent);

  os << indent << "dimX: " << this->dimX << "\n";
  os << indent << "dimY: " << this->dimY << "\n";
  os << indent << "dimZ: " << this->dimZ << "\n";
  os << indent << "dimXY: " << this->dimXY << "\n";
  os << indent << "label: " << this->label << "\n";
}

bool vtkAffineSegment::emptyTree(void)
{
  return (tree.size()==0);
}

void vtkAffineSegment::insert(const FMleaf leaf) {

  // insert element at the back
  tree.push_back( leaf );
  node[ leaf.nodeIndex ].leafIndex=(int)(tree.size()-1);

  // trickle the element up until everything 
  // is sorted again
  upTree( (int)(tree.size()-1) );
}

bool vtkAffineSegment::minHeapIsSorted( void )
{
  int N=(int)tree.size();
  int k;

  for(k=(N-1);k>=1;k--)
    {
      if(node[tree[k].nodeIndex].leafIndex!=k)
    {
      vtkErrorMacro( "Error in vtkAffineSegment::minHeapIsSorted(): "
             << "tree[" << k << "] : pb leafIndex/nodeIndex (size=" 
             << (unsigned int)tree.size() << ")" );
    }
    }
  for(k=(N-1);k>=1;k--)
    {
      if( ( node[tree[k].nodeIndex].T)==0 )
    vtkErrorMacro( "Error in vtkAffineSegment::minHeapIsSorted(): "
               << "NaN or Inf value in minHeap : " << node[tree[k].nodeIndex].T );

      if( node[tree[k].nodeIndex].T<node[ (int)(tree[(k-1)/2].nodeIndex) ].T )
    {
      vtkErrorMacro( "Error in vtkAffineSegment::minHeapIsSorted(): "
             << "minHeapIsSorted is false! : size=" << (unsigned int)tree.size() << "at leafIndex=" << k 
             << " node[tree[k].nodeIndex].T=" << node[tree[k].nodeIndex].T
             << "<node[ (int)(tree[(k-1)/2].nodeIndex) ].T=" << node[ (int)(tree[(k-1)/2].nodeIndex) ].T);

      return false;
    }
    }
  return true;
}

void vtkAffineSegment::downTree(int index) {
  /*
   * This routine sweeps downward from leaf 'index',
   * swapping child and parent if the value of the child
   * is smaller than that of the parent. Note that this only
   * guarantees the heap property if the value at the
   * starting index is greater than all its parents.
   */
  int LeftChild = 2 * index + 1;
  int RightChild = 2 * index + 2;
  
  while (LeftChild < (int)tree.size())
    {
      /*
       * Terminate the process when the current leaf has no
       * children. If no swap occurs at a higher leaf, this
       * condition is forced.
       */

      /* 
       * Find the child with the smallest value. The node has at least
       * one child, and so has at least a left child.
       */
      int MinChild = LeftChild;

      /*
       * If the node has a right child, and if the right child
       * has smaller crossing time than the left child, then the 
       * right child is the MinChild.
       */
      if (RightChild < (int)tree.size()) {
    
    if (node[tree[LeftChild].nodeIndex].T>
        node[tree[RightChild].nodeIndex].T) 
      MinChild = RightChild;
      }
    
      /*
       * If the MinChild has smaller T than the current leaf,
       * swap them, and move the current leaf to the MinChild.
       */
      if (node[tree[MinChild].nodeIndex].T<
      node[tree[index].nodeIndex].T)
    {
      FMleaf tmp=tree[index];
      tree[index]=tree[MinChild];
      tree[MinChild]=tmp;

      // make sure pointers remain correct
      node[ tree[MinChild].nodeIndex ].leafIndex = MinChild;
      node[ tree[index].nodeIndex ].leafIndex = index;
      
      index = MinChild;
     
      LeftChild = 2 * index + 1;
      RightChild =  LeftChild + 1;
    }
      else
    /*
     * If the current leaf has a lower value than its
     * MinChild, the job is done, force a stop.
     */
    break;
    } 
}

void vtkAffineSegment::upTree(int index) {
  /*
   * This routine sweeps upward from leaf 'index',
   * swapping child and parent if the value of the child
   * is less than that of the parent. Note that this only
   * guarantees the heap property if the value at the
   * starting leaf is less than all its children.
   */
  while( index>0 )
    {
      int upIndex = (int) (index-1)/2;

      if( node[tree[index].nodeIndex].T < 
      node[tree[upIndex].nodeIndex].T )
    {
      // then swap the 2 nodes

      FMleaf tmp=tree[index];
      tree[index]=tree[upIndex];
      tree[upIndex]=tmp;

      // make sure pointers remain correct
      node[ tree[upIndex].nodeIndex ].leafIndex = upIndex;
      node[ tree[index].nodeIndex ].leafIndex = index;
    
      index = upIndex;
    }
      else
    // then there is nothing left to do
    // force stop
    break;
    }
}

FMleaf vtkAffineSegment::removeSmallest( void ) {

  FMleaf f;
  f=tree[0];

  /*
   * Now move the bottom, rightmost, leaf to the root.
   */
  tree[0]=tree[ tree.size()-1 ];

  // make sure pointers remain correct
  node[ tree[0].nodeIndex ].leafIndex = 0;

  tree.pop_back();

  // trickle the element down until everything 
  // is sorted again
  downTree( 0 );

  return f;
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

vtkAffineSegment::vtkAffineSegment() 
{ 
  initialized=false; 
  somethingReallyWrong=true;
}

//called when we are on the Affine Segmentation screen
//called only once. initialize and assign mem
void vtkAffineSegment::init(int dimX, int dimY, int dimZ, int depth, double dx, double dy, double dz)
{
  powerSpeed = 1.0;
  Evolve = 0;

  this->dx=(float)dx;
  this->dy=(float)dy;
  this->dz=(float)dz;

  invDx2 = (float)(1.0/(dx*dx));
  invDy2 = (float)(1.0/(dy*dy));
  invDz2 = (float)(1.0/(dz*dz));

  nNeighbors=6; // 6 or 26
  //note: there seem to be some problems with discr < 0 
  //and A==0 when 26
  this->NumberOfIterations = 30;
  nEvolutions=1000;
  this->nPointsEvolution = 10000;
  this->Inflation = 100;
  this->NumberOfContractions = 5;
  already_computed = false;
  Contract = false;
  InitialSize = 500;

  this->dimX=dimX;
  this->dimY=dimY;
  this->dimZ=dimZ;
  this->dimXY=dimX*dimY;
  this->dimXYZ=dimX*dimY*dimZ;

  arrayShiftNeighbor[0] = 0; // neighbor 0 is the node itself
  arrayDistanceNeighbor[0] = 0.0;

  arrayShiftNeighbor[1] = -dimX;
  arrayDistanceNeighbor[1] = dy;
  arrayShiftNeighbor[2] = +1;
  arrayDistanceNeighbor[2] = dx;
  arrayShiftNeighbor[3] = dimX;
  arrayDistanceNeighbor[3] = dy;
  arrayShiftNeighbor[4] = -1;
  arrayDistanceNeighbor[4] = dx;
  arrayShiftNeighbor[5] = -dimXY;
  arrayDistanceNeighbor[5] = dz;
  arrayShiftNeighbor[6] = dimXY;
  arrayDistanceNeighbor[6] = dz;

  arrayShiftNeighbor[7] =  -dimX+dimXY;
  arrayDistanceNeighbor[7] = sqrt( dy*dy + dz*dz );
  arrayShiftNeighbor[8] =  -dimX-dimXY;
  arrayDistanceNeighbor[8] = sqrt( dy*dy + dz*dz );
  arrayShiftNeighbor[9] =   dimX+dimXY;
  arrayDistanceNeighbor[9] = sqrt( dy*dy + dz*dz );
  arrayShiftNeighbor[10] =  dimX-dimXY;
  arrayDistanceNeighbor[10] = sqrt( dy*dy + dz*dz );
  arrayShiftNeighbor[11] = -1+dimXY;
  arrayDistanceNeighbor[11] = sqrt( dx*dx + dz*dz );
  arrayShiftNeighbor[12] = -1-dimXY;
  arrayDistanceNeighbor[12] = sqrt( dx*dx + dz*dz );
  arrayShiftNeighbor[13] = +1+dimXY;
  arrayDistanceNeighbor[13] = sqrt( dx*dx + dz*dz );
  arrayShiftNeighbor[14] = +1-dimXY;
  arrayDistanceNeighbor[14] = sqrt( dx*dx + dz*dz );
  arrayShiftNeighbor[15] = +1-dimX;
  arrayDistanceNeighbor[15] = sqrt( dx*dx + dy*dy );
  arrayShiftNeighbor[16] = +1+dimX;
  arrayDistanceNeighbor[16] = sqrt( dx*dx + dy*dy );
  arrayShiftNeighbor[17] = -1+dimX;
  arrayDistanceNeighbor[17] = sqrt( dx*dx + dy*dy );
  arrayShiftNeighbor[18] = -1-dimX;
  arrayDistanceNeighbor[18] = sqrt( dx*dx + dy*dy );

  arrayShiftNeighbor[19] = +1-dimX-dimXY;
  arrayDistanceNeighbor[19] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[20] = +1-dimX+dimXY;
  arrayDistanceNeighbor[20] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[21] = +1+dimX-dimXY;
  arrayDistanceNeighbor[21] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[22] = +1+dimX+dimXY;
  arrayDistanceNeighbor[22] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[23] = -1+dimX-dimXY;
  arrayDistanceNeighbor[23] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[24] = -1+dimX+dimXY;
  arrayDistanceNeighbor[24] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[25] = -1-dimX-dimXY;
  arrayDistanceNeighbor[25] = sqrt( dx*dx + dy*dy + dz*dz );
  arrayShiftNeighbor[26] = -1-dimX+dimXY;
  arrayDistanceNeighbor[26] = sqrt( dx*dx + dy*dy + dz*dz );

  this->depth=depth;

  phi_hat = NULL;
  phi_hat_x = NULL;
  phi_hat_y = NULL;
  phi_hat_z = NULL;

  level_set = NULL;
  sdist = NULL;
  temp_phi_ext = NULL;
  temp_phi_ext_x = NULL;
  temp_phi_ext_y = NULL;
  temp_phi_ext_z = NULL;

  node = new FMnode[ dimX*dimY*dimZ ];

  //allocate space for arrays
  Allocate_Space();

  // assert( node!=NULL );
  if(!(node!=NULL))
    {
      vtkErrorMacro("Error in void vtkAffineSegment::init(), not enough memory for allocation of 'node'");
      return;
    }

  initialized=false; // we will need one pass in the execute
  // function before we are properly initialized

  firstCall = true;

  somethingReallyWrong = false; // so far so good
}

void vtkAffineSegment::setInData(short* data)
{
  indata=data;
}

void vtkAffineSegment::setOutData(short* data)
{
  outdata=data;
}

vtkAffineSegment::~vtkAffineSegment()
{
  /* all the delete are done by unInit() */
}

int vtkAffineSegment::shiftNeighbor(int n)
{
  //assert(initialized);
  //assert(n>=0 && n<=nNeighbors);

  return arrayShiftNeighbor[n];
}

double vtkAffineSegment::distanceNeighbor(int n)
{
  //assert(initialized);
  //assert(n>=0 && n<=nNeighbors);

  return arrayDistanceNeighbor[n];
}

int vtkAffineSegment::indexFather(int n )
{
  float Tmin = (float)INF;
  int index, indexMin;

  // note: has to be 6 or else topology not consistent and
  // we get weird path to parents using the diagonals
  for(int k=1;k<=6;k++)
    {
      index = n+shiftNeighbor(k);
      if( node[index].T<Tmin )
    {
      Tmin = node[index].T;
      indexMin = index;
    }
    }

  //assert( Tmin < INF );
  // or else there was no initialized neighbor around ?

  return indexMin;
}

float vtkAffineSegment::step( int *indx )
{
  if(somethingReallyWrong)
    return (float)INF;

  int indexN;
  int n;
  
  FMleaf min;

  /* find point in fmsTRIAL with smallest T, remove it from fmsTRIAL and put
     it in fmsKNOWN */

  if( emptyTree() )
    {
      vtkErrorMacro( "vtkAffineSegment::step empty tree!" << endl );
      return (float)INF;
    }

  min=removeSmallest();
  
  if( node[min.nodeIndex].T>=INF )
    {
      vtkErrorMacro( " node[min.nodeIndex].T>=INF " << endl );      

      // this would happen if the only points left were artificially put back
      // by the user playing with the slider
      // we do not want to consider those before the expansion has naturally 
      // reachjed them.
      return (float)INF;
    }


  node[min.nodeIndex].status=fmsKNOWN;
  knownPoints.push_back(min.nodeIndex);
  *indx = min.nodeIndex;

  //fprintf(fpc,"step: T = %f\n",node[min.nodeIndex].T);

  //assign the corresponding extension values
  phi_ext.push_back(temp_phi_ext[min.nodeIndex]);
  phi_ext_x.push_back(temp_phi_ext_x[min.nodeIndex]);
  phi_ext_y.push_back(temp_phi_ext_y[min.nodeIndex]);
  phi_ext_z.push_back(temp_phi_ext_z[min.nodeIndex]);
  eucl_ext.push_back(temp_eucl_phi[min.nodeIndex]);

  /* then we consider all the neighbors */
  for(n=1;n<=nNeighbors;n++)
    {
      /* 'indexN' is the index of the nth neighbor 
     of node of index 'index' */
      indexN=min.nodeIndex+shiftNeighbor(n);
      
      /*
       * Check the status of the neighbors. If
       * they are fmsTRIAL, recompute their crossing time values and
       * adjust their position in the tree with an UpHeap (Note that 
       * recomputed value must be less than or equal to the original). 
       * If they are fmsFAR, recompute their crossing times, and move 
       * them into fmsTRIAL.
       */
      if( node[indexN].status==fmsFAR )
    {
      FMleaf f;
      node[indexN].T=computeT(indexN);
      f.nodeIndex=indexN;

      insert( f );

      node[indexN].status=fmsTRIAL;

    }
      else if( node[indexN].status==fmsTRIAL )
    {
      float t1,  t2;
      t1 = node[indexN].T;

      node[indexN].T=computeT(indexN);

      t2 = node[indexN].T;
      if( t2<t1 )
        upTree( node[indexN].leafIndex );
      else
        downTree( node[indexN].leafIndex );

    }
    }

  return node[min.nodeIndex].T; 
}

//compute T and compute extensions accordingly
float vtkAffineSegment::computeT(int index )
{
  double A, B, C, Discr;
  double ph,denom;
  double ph_x,ph_y,ph_z,ph_eu;

  A = 0.0;
  B = 0.0;
  ph = 0.0;
  denom = 0.0;
  ph_x = 0.0;
  ph_y = ph_z = 0.0;
  ph_eu=0.0;

  double s=speed(index);

  
  /*
    we don't want anything really small here as it might give us very large T
    and we don't want something not defined (Inf) or larger than our own INF
    ( because at low level the algo relies on Tij < INF to say that Tij is defined
    cf   if ((Dxm>0.0) || (Dxp<0.0)) ))
 
    this should be cool with a volume of dimension less than 1e6, (volumes are typically 256~=1e2 to 1e3)
  */

  C = -1.0/( s*s ); 

  double Tij, Txm, Txp, Tym, Typ, Tzm, Tzp, TijNew;
  double Pij,Pxm,Pxp,Pym,Pyp,Pzm,Pzp;
  double Exm,Exp,Eym,Eyp,Ezm,Ezp;
  double x_Pxm,x_Pxp,x_Pym,x_Pyp,x_Pzm,x_Pzp;
  double y_Pxm,y_Pxp,y_Pym,y_Pyp,y_Pzm,y_Pzp;
  double z_Pxm,z_Pxp,z_Pym,z_Pyp,z_Pzm,z_Pzp;


  Pij = temp_phi_ext[index];

  Tij = node[index].T;

  /* we know that all neighbors are defined
     because this node is not fmsOUT */
  Txm = node[index+shiftNeighbor(4)].T;
  Txp = node[index+shiftNeighbor(2)].T;
  Tym = node[index+shiftNeighbor(1)].T;
  Typ = node[index+shiftNeighbor(3)].T;
  Tzm = node[index+shiftNeighbor(5)].T;
  Tzp = node[index+shiftNeighbor(6)].T;
  
  /*extension values */
  Pxm = temp_phi_ext[index+shiftNeighbor(4)];
  Pxp = temp_phi_ext[index+shiftNeighbor(2)];
  Pym = temp_phi_ext[index+shiftNeighbor(1)];
  Pyp = temp_phi_ext[index+shiftNeighbor(3)];
  Pzm = temp_phi_ext[index+shiftNeighbor(5)];
  Pzp = temp_phi_ext[index+shiftNeighbor(6)];

  Exm = temp_eucl_phi[index+shiftNeighbor(4)];
  Exp = temp_eucl_phi[index+shiftNeighbor(2)];
  Eym = temp_eucl_phi[index+shiftNeighbor(1)];
  Eyp = temp_eucl_phi[index+shiftNeighbor(3)];
  Ezm = temp_eucl_phi[index+shiftNeighbor(5)];
  Ezp = temp_eucl_phi[index+shiftNeighbor(6)];

  x_Pxm = temp_phi_ext_x[index+shiftNeighbor(4)];
  x_Pxp = temp_phi_ext_x[index+shiftNeighbor(2)];
  x_Pym = temp_phi_ext_x[index+shiftNeighbor(1)];
  x_Pyp = temp_phi_ext_x[index+shiftNeighbor(3)];
  x_Pzm = temp_phi_ext_x[index+shiftNeighbor(5)];
  x_Pzp = temp_phi_ext_x[index+shiftNeighbor(6)];

  y_Pxm = temp_phi_ext_y[index+shiftNeighbor(4)];
  y_Pxp = temp_phi_ext_y[index+shiftNeighbor(2)];
  y_Pym = temp_phi_ext_y[index+shiftNeighbor(1)];
  y_Pyp = temp_phi_ext_y[index+shiftNeighbor(3)];
  y_Pzm = temp_phi_ext_y[index+shiftNeighbor(5)];
  y_Pzp = temp_phi_ext_y[index+shiftNeighbor(6)];

  z_Pxm = temp_phi_ext_z[index+shiftNeighbor(4)];
  z_Pxp = temp_phi_ext_z[index+shiftNeighbor(2)];
  z_Pym = temp_phi_ext_z[index+shiftNeighbor(1)];
  z_Pyp = temp_phi_ext_z[index+shiftNeighbor(3)];
  z_Pzm = temp_phi_ext_z[index+shiftNeighbor(5)];
  z_Pzp = temp_phi_ext_z[index+shiftNeighbor(6)];

  double Dxm, Dxp, Dym, Dyp, Dzm, Dzp;

  Dxm = Tij - Txm;
  Dxp = Txp - Tij;
  Dym = Tij - Tym;
  Dyp = Typ - Tij;
  Dzm = Tij - Tzm;
  Dzp = Tzp - Tij;

  /*
   * Set up the quadratic equation for TijNew.
   */
  if ((Dxm>0.0) || (Dxp<0.0)) {
    if (Dxm > -Dxp) {
      A += invDx2;
      B += -2.0 * Txm * invDx2;
      C += Txm * Txm * invDx2;
      denom -= Dxm;
      ph -= Dxm*Pxm;
      ph_x -= Dxm*x_Pxm;
      ph_y -= Dxm*y_Pxm;
      ph_z -= Dxm*z_Pxm;
      ph_eu -= Dxm*Exm;
    }
    else {
      A += invDx2;
      B += -2.0 * Txp * invDx2;
      C += Txp * Txp * invDx2;
      denom += Dxp;
      ph += Dxp*Pxp;
      ph_x += Dxp*x_Pxp;
      ph_y += Dxp*y_Pxp;
      ph_z += Dxp*z_Pxp;
      ph_eu += Dxp*Exp;
    }
  }
  if ((Dym>0.0) || (Dyp<0.0)) {
    if (Dym > -Dyp) {
      A += invDy2;
      B += -2.0 * Tym * invDy2;
      C += Tym * Tym * invDy2;
      denom -= Dym;
      ph -= Dym*Pym;
      ph_x -= Dym*x_Pym;
      ph_y -= Dym*y_Pym;
      ph_z -= Dym*z_Pym;
      ph_eu -= Dym*Eym;
    }
    else {
      A += invDy2;
      B += -2.0 * Typ * invDy2;
      C += Typ * Typ * invDy2;
      denom += Dyp;
      ph += Dyp*Pyp;
      ph_x += Dyp*x_Pyp;
      ph_y += Dyp*y_Pyp;
      ph_z += Dyp*z_Pyp;
      ph_eu += Dyp*Eyp;
    }
  }
  if ((Dzm>0.0) || (Dzp<0.0)) {
    if (Dzm > -Dzp) {
      A += invDz2;
      B += -2.0 * Tzm * invDz2;
      C += Tzm * Tzm * invDz2;
      denom -= Dzm;
      ph -= Dzm*Pzm;
      ph_x -= Dzm*x_Pzm;
      ph_y -= Dzm*y_Pzm;
      ph_z -= Dzm*z_Pzm;
      ph_eu -= Dzm*Ezm;
    }
    else {
      A += invDz2;
      B += -2.0 * Tzp * invDz2;
      C += Tzp * Tzp * invDz2;
      denom += Dzp;
      ph += Dzp*Pzp;
      ph_x += Dzp*x_Pzp;
      ph_y += Dzp*y_Pzp;
      ph_z += Dzp*z_Pzp;
      ph_eu += Dzp*Ezp;
    }
  }

  
  Discr = B*B - 4.0*A*C;


  // cases when the quadratic equation is singular
  if ((A==0) || (Discr < 0.0)) {
    int candidateIndex;
    double candidateT;
    
    Tij=INF;
    double s=speed(index);
    for(int n=1;n<=nNeighbors;n++)
      {
    candidateIndex = index + shiftNeighbor(n);
    if( (node[candidateIndex].status==fmsTRIAL) 
        || (node[candidateIndex].status==fmsKNOWN) )
      {
        candidateT = node[candidateIndex].T + distanceNeighbor(n)/s;
        if( candidateT<Tij )
          {
        Tij=candidateT;
        temp_phi_ext[index] = temp_phi_ext[candidateIndex];
        temp_phi_ext_x[index] = temp_phi_ext_x[candidateIndex];
        temp_phi_ext_y[index] = temp_phi_ext_y[candidateIndex];
        temp_phi_ext_z[index] = temp_phi_ext_z[candidateIndex];
        temp_eucl_phi[index] =  temp_eucl_phi[candidateIndex];
          }
        
      }
      }

    
    if(!( Tij<INF ))
      {
    vtkErrorMacro("Error in vtkAffineSegment::computeT(...): !( Tij<INF )");
    return (float)INF;
      }
   
    //if(Tij > INF)
    //fprintf(fpc,"Tij is greater than INF !!!, = %f\n",Tij);
    return (float)Tij;
  }

  /*
   * Solve the quadratic equation. Note that the new crossing
   * must be GREATER than the average of the active neighbors,
   * since only EARLIER elements are active. Therefore the plus
   * sign is appropriate.
   */
  TijNew = (-B + (float)sqrt(Discr))/((float)2.0*A);
  temp_phi_ext[index] = ph/denom;
  temp_phi_ext_x[index] = ph_x/denom;
  temp_phi_ext_y[index] = ph_y/denom;
  temp_phi_ext_z[index] = ph_z/denom;
  temp_eucl_phi[index] = ph_eu/denom;

  return (float)TijNew; 
}

void vtkAffineSegment::setRAStoIJKmatrix
(float m11, float m12, float m13, float m14,
 float m21, float m22, float m23, float m24,
 float m31, float m32, float m33, float m34,
 float m41, float m42, float m43, float m44)
{
  this->m11=m11;
  this->m12=m12;
  this->m13=m13;
  this->m14=m14;

  this->m21=m21;
  this->m22=m22;
  this->m23=m23;
  this->m24=m24;

  this->m31=m31;
  this->m32=m32;
  this->m33=m33;
  this->m34=m34;

  this->m41=m41;
  this->m42=m42;
  this->m43=m43;
  this->m44=m44;
}

//add all the fiducials
int vtkAffineSegment::addSeed( float r, float a, float s )
{
  if(somethingReallyWrong)
    return 0;


  int I, J, K;
  //int k_offset,i_offset,j_offset;
  //int i,j,k;

  I = (int) ( m11*r + m12*a + m13*s + m14*1 );
  J = (int) ( m21*r + m22*a + m23*s + m24*1 );
  K = (int) ( m31*r + m32*a + m33*s + m34*1 );
  
  if ( (I>=1) && (I<(dimX-1))
       &&  (J>=1) && (J<(dimY-1))
       &&  (K>=1) && (K<(dimZ-1)) )
    {
      seedPoints.push_back( I+J*dimX+K*dimXY );
      Evolve = 1;
      return 1;
    }

 
  return 0; // we're trying to put a seed outside of the volume
}

//release mem
void vtkAffineSegment::unInit( void )
{
  //assert( initialized );
  if(!initialized)
    {
      vtkErrorMacro("Error in vtkAffineSegment::unInit(): !initialized");
      return;
    }

  if(somethingReallyWrong)
    return;

  Release_Space();
  if(!this->node)
    delete [] this->node;

  while(tree.size()>0)
    tree.pop_back();

  while(knownPoints.size()>0)
    {
      knownPoints.pop_back();
    }

  initialized = false;
}



void vtkAffineSegment::tweak(char *name, double value)
{
  if( strcmp( name, "sigma2SmoothPDF" )==0 )
    {
      return;
    }

  if( strcmp( name, "powerSpeed" )==0 )
    {
      powerSpeed=value;
      return;
    }


  vtkErrorMacro("Error in vtkAffineSegment::tweak(...): '" << name << "' not recognized !");
}

//this is called when we want TOTAL reset
void vtkAffineSegment::Reset()
{
  vtkImageData *outData = this->GetOutput();
  short *outPtr = (short *) outData->GetScalarPointer();

  for(int i =0;i<(int)zero_set.size();i++)
    outPtr[zero_set[i]] = 0;
  //make sure everything is clear
  knownPoints.clear();
  seedPoints.clear();
  zero_set.clear();
  already_computed = false;

  Evolve = 1;

  return;
}

//this function is called when we only want the
//output to be reset. we dont want the interface
// and seed points to go away.
void vtkAffineSegment::OutputReset()
{
  vtkImageData *outData = this->GetOutput();
  short *outPtr = (short *) outData->GetScalarPointer();

  for(int i =0;i<(int)zero_set.size();i++)
    outPtr[zero_set[i]] = 0;
  //make sure everything is clear
  knownPoints.clear();
  zero_set.clear();
  Evolve = 1;

  return;
}


